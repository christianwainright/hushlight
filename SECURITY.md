# Security

Hushlight has no network capability, no account and no server, so there is nothing
remote to attack. The app itself never sends a record anywhere. Records can leave
the device in two ways the user controls: Copy or Share on the For the call card,
and the ordinary iPhone or iCloud backup that includes every app's local data. The
[privacy policy](docs/privacy-policy-hushlight.md) describes both. Neither is a
vulnerability. One of these would be:

- a way for the app to send recorded data off the device by itself,
- a way for another app to read Hushlight's sandbox,
- a problem in the release pipeline or this repository's workflows.

## Reporting

Please report privately through GitHub: **Security ▸ Report a vulnerability** on
this repository. Don't open a public issue for a security problem.

You'll get an acknowledgement within a week. Fixes ship in the next App Store
build, and the advisory is published once that build is live.

## Supported versions

Only the current App Store release is supported.
