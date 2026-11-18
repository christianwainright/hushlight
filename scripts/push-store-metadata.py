#!/usr/bin/env python3
"""Push `docs/store/metadata/` to App Store Connect.

    python3 scripts/push-store-metadata.py                 # dry run, the default
    python3 scripts/push-store-metadata.py --apply         # text fields
    python3 scripts/push-store-metadata.py --apply --screenshots

**Nothing is written without `--apply`.** A dry run reads the live listing and prints
a field-by-field diff, which is also the only way to see what App Store Connect
currently holds without opening fourteen web pages.

Why this exists (HL-047): fourteen storefronts × six text fields plus their screenshot
sets is around a hundred manual uploads, redone on every copy change — which is how a
listing quietly stops describing the app it sells. Run from CI after a successful
build upload, the listing cannot drift from the binary by more than one release.

**It runs on ubuntu, and that is the cost argument.** This is HTTPS and nothing else,
so it bills at 1x where the archive job bills at 10x. The one thing it needs that the
standard library lacks — ES256 signing — comes from the `openssl` CLI via `asc_jwt`,
so there is no dependency to install and nothing third-party enters the release path.

Credentials come from the environment, never from an argument, so they cannot land in
a process list or a CI log:

    ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH   (the .p8, as `release.yml` already writes)

Field routing is Apple's, not ours, and it is the part most likely to surprise:
**name, subtitle and the privacy policy URL live on `appInfoLocalizations`**, while
**description, keywords, promotional text and the support URL live on
`appStoreVersionLocalizations`**. Two different objects, two different locale lists,
both keyed by the same locale string.
"""
import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asc_jwt  # noqa: E402

API = "https://api.appstoreconnect.apple.com"
BUNDLE_ID = "net.wainright.hushlight"
METADATA = "docs/store/metadata"
SCREENSHOTS = "docs/design/hushlight/store/frames"

# Which language's frames a storefront shows. English takes the flat set that has
# always been there; everything else takes its language's folder beside it.
STOREFRONT_LANGUAGE = {
    "en-US": "", "en-GB": "", "en-AU": "", "en-CA": "",
    "es-ES": "es", "es-MX": "es", "fr-FR": "fr", "fr-CA": "fr",
    "de-DE": "de", "it": "it", "pt-BR": "pt-BR",
    "ja": "ja", "ko": "ko", "zh-Hans": "zh-Hans",
}

# HL-058c: the iPad set lives beside the iPhone set and goes to the 13" slot. This one
# display type is **named**, not discovered — no iPad set exists on any localization
# until the first push creates it, so there is nothing to read. Apple's 13" slot
# (`APP_IPAD_PRO_3GEN_129`) accepts the 2064×2752 a 13" iPad Pro captures.
SCREENSHOTS_IPAD = "docs/design/hushlight/store/frames-ipad"
IPAD_DISPLAY_TYPE = "APP_IPAD_PRO_3GEN_129"

# Which file feeds which attribute of which object.
APP_INFO_FIELDS = {"title": "name", "subtitle": "subtitle", "privacy_url": "privacyPolicyUrl"}
VERSION_FIELDS = {"description": "description", "keywords": "keywords",
                  "promotional_text": "promotionalText", "support_url": "supportUrl",
                  "release_notes": "whatsNew"}

# HL-053: What's New is per version, not per listing — `release_notes/<version>.txt`
# under each storefront, read for whichever version this run targets. A version with
# no file sends nothing (1.0 has none; App Store Connect does not ask for one on a
# first release), and the lint refuses a MARKETING_VERSION past 1.0 without its file.
RELEASE_NOTES_VERSION = None


class ApiError(Exception):
    def __init__(self, status, detail, where):
        super().__init__(f"{where}\n  HTTP {status}\n  {detail[:900]}")
        self.status, self.detail = status, detail


class Client:
    def __init__(self, token):
        self.token = token

    def request(self, method, path, body=None, headers=None, raw=None):
        url = path if path.startswith("http") else API + path
        data = raw if raw is not None else (json.dumps(body).encode() if body else None)
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self.token}")
        if raw is None and body is not None:
            req.add_header("Content-Type", "application/json")
        for key, value in (headers or {}).items():
            req.add_header(key, value)
        try:
            with urllib.request.urlopen(req) as response:
                payload = response.read()
                return json.loads(payload) if payload and response.status != 204 else {}
        except urllib.error.HTTPError as error:
            raise ApiError(error.code, error.read().decode(errors="replace"),
                           f"{method} {url}") from None

    def get(self, path, **params):
        if params:
            from urllib.parse import urlencode
            path += ("&" if "?" in path else "?") + urlencode(params)
        return self.request("GET", path)

    def paged(self, path, **params):
        page, items = self.get(path, **params), []
        while True:
            items += page.get("data", [])
            nxt = page.get("links", {}).get("next")
            if not nxt:
                return items
            page = self.request("GET", nxt)


def storefronts():
    return sorted(d for d in os.listdir(METADATA) if os.path.isdir(os.path.join(METADATA, d)))


def field(store, name):
    if name == "release_notes":
        if RELEASE_NOTES_VERSION is None:
            return None
        path = os.path.join(METADATA, store, "release_notes", RELEASE_NOTES_VERSION + ".txt")
    else:
        path = os.path.join(METADATA, store, name + ".txt")
    return open(path, encoding="utf-8").read().rstrip("\n") if os.path.exists(path) else None


def show(store, obj, attribute, want, live, changes):
    if want is None:
        return
    if (live or "") == want:
        return
    changes.append((store, obj, attribute))
    old = (live or "").replace("\n", "\\n")
    new = want.replace("\n", "\\n")
    print(f"  {store:8} {obj}.{attribute}")
    print(f"      was: {old[:110] or '(empty)'}")
    print(f"      now: {new[:110]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true",
                        help="actually write; without it this is a read-only diff")
    parser.add_argument("--screenshots", action="store_true",
                        help="also replace the screenshot sets (needs --apply)")
    parser.add_argument("--version", help="version string to target, e.g. 1.0; "
                                          "defaults to the one App Store Connect says is editable")
    parser.add_argument("--diff-only", action="store_true",
                        help="read-only, and no editable version is a notice rather "
                             "than a failure (the Release workflow's diff step)")
    parser.add_argument("--verify", action="store_true",
                        help="read every screenshot's delivery state back and report; "
                             "runs automatically after --screenshots")
    args = parser.parse_args()

    for name in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH"):
        if not os.environ.get(name):
            raise SystemExit(f"{name} is not set — see this file's docstring")
    client = Client(asc_jwt.token(os.environ["ASC_KEY_PATH"], os.environ["ASC_KEY_ID"],
                                  os.environ["ASC_ISSUER_ID"]))

    apps = client.get("/v1/apps", **{"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        raise SystemExit(f"no app with bundle id {BUNDLE_ID} on this account")
    app_id = apps[0]["id"]
    print(f"app {BUNDLE_ID} ({app_id})")

    # The editable version. Anything not yet released is fair game; a live version is
    # not, and picking one silently would be the worst possible failure mode here.
    versions = client.paged(f"/v1/apps/{app_id}/appStoreVersions")
    editable = [v for v in versions
                if v["attributes"]["appStoreState"] in
                {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                 "METADATA_REJECTED", "WAITING_FOR_REVIEW", "INVALID_BINARY"}]
    if args.version:
        editable = [v for v in editable if v["attributes"]["versionString"] == args.version]
    if not editable and args.diff_only and not args.apply:
        print("::notice::no editable app version — nothing to diff until the next "
              "version exists in App Store Connect")
        return
    if not editable:
        raise SystemExit("no editable app version found — a released version cannot be "
                         "edited, and this script will not guess at one")
    version = editable[0]
    print(f"version {version['attributes']['versionString']} "
          f"({version['attributes']['appStoreState']})")
    global RELEASE_NOTES_VERSION
    RELEASE_NOTES_VERSION = version["attributes"]["versionString"]

    app_info = [i for i in client.paged(f"/v1/apps/{app_id}/appInfos")
                if i["attributes"].get("appStoreState") != "READY_FOR_SALE"]
    if not app_info:
        app_info = client.paged(f"/v1/apps/{app_id}/appInfos")
    info_id = app_info[0]["id"]

    info_locales = {l["attributes"]["locale"]: l for l in
                    client.paged(f"/v1/appInfos/{info_id}/appInfoLocalizations")}
    version_locales = {l["attributes"]["locale"]: l for l in
                       client.paged(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")}

    changes, creates = [], []
    print("\nchanges:" if not args.apply else "\napplying:")
    for store in storefronts():
        for locales, fields, obj in ((info_locales, APP_INFO_FIELDS, "appInfo"),
                                     (version_locales, VERSION_FIELDS, "version")):
            live = locales.get(store)
            if live is None:
                creates.append((store, obj))
                print(f"  {store:8} {obj}: locale does not exist yet, would be created")
                for name in fields:
                    show(store, obj, fields[name], field(store, name), None, changes)
                continue
            for name, attribute in fields.items():
                show(store, obj, attribute, field(store, name),
                     live["attributes"].get(attribute), changes)

    if not changes and not creates:
        print("  (nothing — the listing already matches this repository)")

    if not args.apply:
        print(f"\ndry run: {len(changes)} field(s) differ, {len(creates)} locale(s) missing.")
        print("Re-run with --apply to write them.")
        if args.verify:
            verify_screenshots(client, version["id"])
        return

    for store in storefronts():
        for locales, fields, kind, parent, parent_id, collection in (
            (info_locales, APP_INFO_FIELDS, "appInfoLocalizations", "appInfo", info_id,
             f"/v1/appInfos/{info_id}/appInfoLocalizations"),
            (version_locales, VERSION_FIELDS, "appStoreVersionLocalizations",
             "appStoreVersion", version["id"],
             f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations"),
        ):
            attributes = {attribute: field(store, name)
                          for name, attribute in fields.items() if field(store, name) is not None}
            upsert(client, kind, parent, parent_id, collection, locales, store, attributes)

    if args.screenshots:
        push_screenshots(client, version["id"])
    if args.screenshots or args.verify:
        verify_screenshots(client, version["id"])


def upsert(client, kind, parent, parent_id, collection, locales, locale, attributes):
    """Create the localization, or update it if it is already there.

    **The fallback is not defensive padding; it is the shape of the API.** Creating an
    `appInfoLocalization` makes App Store Connect create the matching
    `appStoreVersionLocalization` on its own — so a locale that did not exist when this
    run read the two lists exists by the time it writes the second one, and the POST
    comes back 409 "already exists. Try updating." That is exactly how the first live
    run failed, on `de-DE`, the first storefront alphabetically. Re-reading the
    collection on 409 and patching instead makes the whole pass idempotent, which also
    means a half-finished run can simply be run again.
    """
    live = locales.get(locale)
    if live is not None:
        if all(live["attributes"].get(a) == v for a, v in attributes.items()):
            return
        client.request("PATCH", f"/v1/{kind}/{live['id']}", {"data": {
            "type": kind, "id": live["id"], "attributes": attributes}})
        print(f"  updated {kind} {locale}")
        return

    try:
        client.request("POST", f"/v1/{kind}", {"data": {
            "type": kind, "attributes": {**attributes, "locale": locale},
            "relationships": {parent: {"data": {"type": parent + "s", "id": parent_id}}}}})
        print(f"  created {kind} {locale}")
        return
    except ApiError as error:
        if error.status != 409 or "already exists" not in error.detail:
            raise

    fresh = {l["attributes"]["locale"]: l for l in client.paged(collection)}
    existing = fresh.get(locale)
    if existing is None:
        raise SystemExit(f"{kind} {locale}: App Store Connect says it exists and does "
                         "not list it — refusing to guess")
    locales[locale] = existing
    client.request("PATCH", f"/v1/{kind}/{existing['id']}", {"data": {
        "type": kind, "id": existing["id"], "attributes": attributes}})
    print(f"  updated {kind} {locale} (created for us when its sibling was made)")


def push_screenshots(client, version_id):
    """Replace each locale's screenshot sets with what is committed here: the iPhone
    set (its display type discovered) and, when `frames-ipad/` exists, the iPad set
    (its display type named — see `IPAD_DISPLAY_TYPE`)."""
    push_screenshot_set(client, version_id, SCREENSHOTS, None)
    if os.path.isdir(SCREENSHOTS_IPAD):
        push_screenshot_set(client, version_id, SCREENSHOTS_IPAD, IPAD_DISPLAY_TYPE)


def push_screenshot_set(client, version_id, root, display_type):
    """Replace each locale's screenshot set of one display type with what is
    committed under `root`.

    The display type is **discovered, never guessed**: Apple's enumeration has grown
    with every screen size, and naming the wrong one creates a second empty set beside
    the real one rather than failing loudly. It is read from whichever locale already
    has a set — the primary one does, since 1.0 was submitted with screenshots — and
    reused to create the sets a new localization lacks. That is still not a guess: it
    is this app's own value, copied from this app's own version.
    """
    locales = {l["attributes"]["locale"]: l for l in
               client.paged(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")}

    # One pass to learn the display type before anything is created. Each pass
    # replaces **only its own type's sets**: the iPhone pass discovers its type among
    # the non-iPad sets (so an iPad set created by an earlier run cannot be mistaken
    # for it) and then keeps exactly that type; the iPad pass keeps exactly the named
    # type. Any other set Apple may hold — a second iPhone slot, another iPad size —
    # is left alone rather than emptied and refilled with the wrong frames.
    known_type, all_sets_by_locale = display_type, {}
    for locale, localization in locales.items():
        all_sets_by_locale[locale] = client.paged(
            f"/v1/appStoreVersionLocalizations/{localization['id']}/appScreenshotSets")
        if display_type is None:
            for shot_set in all_sets_by_locale[locale]:
                candidate = shot_set["attributes"].get("screenshotDisplayType")
                if candidate and candidate != IPAD_DISPLAY_TYPE:
                    known_type = known_type or candidate
    sets_by_locale = {
        locale: [ss for ss in sets if ss["attributes"].get("screenshotDisplayType") == known_type]
        for locale, sets in all_sets_by_locale.items()
    }
    if known_type is None:
        print("  no screenshot set exists on any localization, so there is no display "
              "type to read. Upload one screenshot by hand in App Store Connect once, "
              "then re-run — this refuses to guess which size Apple wants.")
        return
    print(f"  screenshot display type: {known_type}")
    for store in storefronts():
        # Frames live per **language**, not per storefront: es-ES and es-MX are two
        # listings sharing one Spanish app, and committing the same seven PNGs twice
        # would put fourteen copies of a 1320×2868 image into the repository to say
        # what nine can.
        #
        # A locale gets its own screenshots only when its set is **complete**. A
        # partial set is worse than the English one: the store would show a Japanese
        # reader four localized screens and three missing, which reads as a broken
        # listing rather than an untranslated one. So the fallback is all-or-nothing.
        english = sorted(f for f in os.listdir(root) if f.endswith(".png"))
        folder = os.path.join(root, STOREFRONT_LANGUAGE.get(store, store))
        if folder != root and os.path.isdir(folder):
            localized = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
            if localized != english:
                missing = sorted(set(english) - set(localized))
                print(f"  {store}: localized set is incomplete ({len(localized)}/"
                      f"{len(english)}, missing {', '.join(missing)}) — using the "
                      "English set rather than a half-translated listing")
                folder = root
        else:
            folder = root
        shots = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
        if not shots or store not in locales:
            continue
        sets = sets_by_locale.get(store) or []
        if not sets:
            created = client.request("POST", "/v1/appScreenshotSets", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": known_type},
                "relationships": {"appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations",
                             "id": locales[store]["id"]}}}}})
            sets = [created["data"]]
            print(f"  {store}: created a {known_type} screenshot set")
        for shot_set in sets:
            for existing in client.paged(f"/v1/appScreenshotSets/{shot_set['id']}/appScreenshots"):
                client.request("DELETE", f"/v1/appScreenshots/{existing['id']}")
            for position, name in enumerate(shots, start=1):
                print(f"  {store}: uploading {position}/{len(shots)} {name}")
                upload(client, shot_set["id"], os.path.join(folder, name), name)
            print(f"  {store}: {len(shots)} screenshots uploaded")


def verify_screenshots(client, version_id, attempts=10, pause=15):
    """**Uploaded is not accepted.** Apple validates a screenshot asynchronously after
    the bytes land: dimensions against the set's display type, format, alpha. A PUT that
    returned 200 tells you the transfer worked and nothing about whether the store will
    show the image — the state to read is `assetDeliveryState.state`, which moves
    through `UPLOAD_COMPLETE` to `COMPLETE`, or to `FAILED` carrying the reason.

    So this polls rather than trusting the upload, and exits non-zero if anything
    failed. Without it a green run could leave fourteen storefronts holding invisible
    screenshots, which is the failure this whole push exists to avoid."""
    print("\nverifying delivery:")
    locales = {l["attributes"]["locale"]: l for l in
               client.paged(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")}
    for attempt in range(1, attempts + 1):
        pending, failed, complete = 0, [], 0
        for locale, localization in sorted(locales.items()):
            for shot_set in client.paged(
                    f"/v1/appStoreVersionLocalizations/{localization['id']}/appScreenshotSets"):
                for shot in client.paged(f"/v1/appScreenshotSets/{shot_set['id']}/appScreenshots"):
                    state = (shot["attributes"].get("assetDeliveryState") or {})
                    name = shot["attributes"].get("fileName", shot["id"])
                    if state.get("errors"):
                        failed.append((locale, name, state["errors"]))
                    elif state.get("state") == "COMPLETE":
                        complete += 1
                    else:
                        pending += 1
        print(f"  attempt {attempt}: {complete} complete, {pending} still processing, "
              f"{len(failed)} failed")
        if failed:
            for locale, name, errors in failed:
                print(f"  FAILED {locale}/{name}: {errors}")
            raise SystemExit("screenshot delivery failed — see above")
        if not pending:
            print(f"  all {complete} screenshots accepted")
            return
        time.sleep(pause)
    raise SystemExit(f"{pending} screenshot(s) still processing after "
                     f"{attempts * pause}s — re-run with --verify to check again")


def raw_put(method, url, headers, body, where):
    request = urllib.request.Request(url, data=body, method=method)
    for key, value in headers.items():
        request.add_header(key, value)
    try:
        with urllib.request.urlopen(request) as response:
            if response.status >= 300:
                raise ApiError(response.status, response.read().decode(errors="replace"), where)
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, error.read().decode(errors="replace"),
                       f"{method} {url.split('?')[0]} ({where})") from None


def upload(client, set_id, path, name):
    """Apple's three-step upload: reserve, PUT the bytes where it says, then commit
    with a checksum it verifies. Skipping the commit leaves an invisible half-upload
    that the web UI shows as a broken tile."""
    blob = open(path, "rb").read()
    reserved = client.request("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": name, "fileSize": len(blob)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    data = reserved["data"]
    for index, operation in enumerate(data["attributes"]["uploadOperations"], start=1):
        chunk = blob[operation["offset"]:operation["offset"] + operation["length"]]
        headers = {h["name"]: h["value"] for h in operation.get("requestHeaders", [])}
        # **Not an App Store Connect API call.** The upload operations point at Apple's
        # storage on another host, carry the headers they tell you to send, and answer
        # with no JSON at all — so this goes through `raw_put` rather than `request`,
        # which would attach a bearer token that endpoint never asked for and then try
        # to parse an empty body as JSON.
        raw_put(operation["method"], operation["url"], headers, chunk,
                f"{name} part {index}/{len(data['attributes']['uploadOperations'])}")
    client.request("PATCH", f"/v1/appScreenshots/{data['id']}", {"data": {
        "type": "appScreenshots", "id": data["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})


if __name__ == "__main__":
    # **Nothing may fail quietly here.** The first live screenshot run exited 1 with no
    # output at all, which cost a whole macOS release run to learn nothing from. Print
    # unbuffered, and print *something* for every way out.
    sys.stdout.reconfigure(line_buffering=True)
    try:
        main()
    except ApiError as error:
        print(f"\nFAILED: {error}", file=sys.stderr, flush=True)
        raise SystemExit(1) from None
    except Exception:
        import traceback
        print("\nFAILED, unexpectedly:", file=sys.stderr, flush=True)
        traceback.print_exc()
        raise SystemExit(1) from None
