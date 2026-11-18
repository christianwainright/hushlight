#!/bin/bash
# Prints the UDID of the newest available iOS simulator matching a device-name
# filter ("iPhone" by default). One definition, called by every script that needs a
# device, so "which simulator" cannot mean two different things in two places.
#
# HL-038 replaced a hardcoded `-- iOS 27` filter here. The app's floor is iOS 18.0,
# so nothing requires the beta runtime any more — and requiring it made every QA
# script unrunnable on a machine carrying only the shipping Xcode. Newest-available
# is what a stock machine has (the shipping OS) and what a beta machine has (the
# beta); pin either one deliberately with HUSHLIGHT_SIM rather than by accident.
set -euo pipefail

# simctl groups devices under `-- iOS <version> --` headers in no guaranteed order,
# so the version is carried down onto each device line and `sort -V` picks the
# newest. A non-iOS header (watchOS, xrOS) clears the carry rather than inheriting.
xcrun simctl list devices available "${1:-iPhone}" \
    | awk '
        /^-- iOS /  { v = $3; next }
        /^--/       { v = "";  next }
        v != "" && match($0, /[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/) {
            print v, substr($0, RSTART, RLENGTH)
        }' \
    | sort -V | tail -1 | awk '{ print $2 }'
