#!/usr/bin/env python3
"""An ES256 JWT for the App Store Connect API, with no third-party dependency.

Signing an ASC token needs ECDSA P-256 over SHA-256, which Python's standard library
cannot do — `hashlib` and `hmac` stop at symmetric hashes. The usual answer is PyJWT
plus `cryptography`, a compiled dependency tree, in a repository whose whole
dependency surface is two GitHub Actions and whose ratchet forbids third-party code in
the app. So this uses the `openssl` CLI, which is on every runner and every Mac, and
does the one piece of real work openssl leaves out: converting its DER signature to
the raw r‖s form JOSE requires.

That conversion is the entire reason this file exists. `openssl dgst -sign` emits
`SEQUENCE { INTEGER r, INTEGER s }`; JWS ES256 wants the two integers concatenated,
each left-padded to exactly 32 bytes. Handing the DER bytes straight to a JWT gets a
401 that says nothing about why.
"""
import base64
import json
import subprocess
import time


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _der_to_raw(der: bytes) -> bytes:
    """`SEQUENCE { INTEGER r, INTEGER s }` to r‖s, each 32 bytes.

    Hand-parsed rather than pulled from a library: it is twenty lines of ASN.1 that
    have not changed since 1988, and the alternative is a compiled dependency in a
    release path.
    """
    if der[0] != 0x30:
        raise ValueError("signature is not an ASN.1 SEQUENCE")
    # Length may be short-form (one byte) or long-form (0x81 + one byte). A P-256
    # signature never needs more than that.
    index = 2 if der[1] < 0x80 else 3
    out = b""
    for _ in range(2):
        if der[index] != 0x02:
            raise ValueError("expected an ASN.1 INTEGER in the signature")
        length = der[index + 1]
        value = der[index + 2: index + 2 + length]
        # DER stores signed integers, so a value whose top bit is set carries a
        # leading zero byte that must not survive into the fixed-width form.
        value = value.lstrip(b"\x00")
        if len(value) > 32:
            raise ValueError("signature integer is wider than P-256")
        out += value.rjust(32, b"\x00")
        index += 2 + length
    return out


def token(key_path: str, key_id: str, issuer_id: str, lifetime_seconds: int = 1200) -> str:
    """A signed bearer token. Apple caps the lifetime at 20 minutes and rejects a
    longer one outright, so the default is exactly that."""
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + lifetime_seconds,
        "aud": "appstoreconnect-v1",
    }
    signing_input = f"{_b64(json.dumps(header, separators=(',', ':')).encode())}." \
                    f"{_b64(json.dumps(payload, separators=(',', ':')).encode())}"
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", key_path, "-binary"],
        input=signing_input.encode(), capture_output=True, check=True,
    ).stdout
    return f"{signing_input}.{_b64(_der_to_raw(der))}"
