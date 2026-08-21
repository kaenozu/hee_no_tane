#!/usr/bin/env bash
# Validates the AdMob APPLICATION_ID class inside a built APK/AAB manifest.
#
# Usage: tool/validate_ad_manifest.sh <apk-or-aab-path> <test|production>
#
# The manifest is a binary (XML/APK) or protobuf (AAB) file, but AdMob IDs are
# stored verbatim in its string pool, so classification is done by byte-level
# search. Full IDs are never printed; only a masked prefix is shown.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <apk-or-aab-path> <test|production>" >&2
  exit 64
fi

artifact=$1
expected=$2

if [[ ! -f "$artifact" ]]; then
  echo "ad manifest validation: artifact not found: $artifact" >&2
  exit 66
fi

case "$expected" in
  test | production) ;;
  *)
    echo "ad manifest validation: expected must be 'test' or 'production'" >&2
    exit 64
    ;;
esac

google_test_publisher='ca-app-pub-3940256099942544'
production_publisher='ca-app-pub-1121980304554901'

if [[ "$artifact" == *.aab ]]; then
  manifest_entry='base/manifest/AndroidManifest.xml'
else
  manifest_entry='AndroidManifest.xml'
fi

manifest_entry_selector() {
  if command -v unzip >/dev/null 2>&1; then
    unzip -p "$artifact" "$1"
  else
    python3 - "$artifact" "$1" <<'PY'
import sys, zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    sys.stdout.buffer.write(archive.read(sys.argv[2]))
PY
  fi
}

# Here-string instead of `printf | grep`: under `set -o pipefail`, grep -q
# exiting early on a match kills printf with SIGPIPE and the pipeline would
# report failure even when the marker was found.
manifest_bytes=$(manifest_entry_selector "$manifest_entry")

found_test=false
found_production=false
if grep -qa "$google_test_publisher" <<<"$manifest_bytes"; then
  found_test=true
fi
if grep -qa "$production_publisher" <<<"$manifest_bytes"; then
  found_production=true
fi

if $found_test && $found_production; then
  echo "ad manifest validation: FAIL ($artifact): manifest mixes test and production AdMob app IDs" >&2
  exit 1
fi

if ! $found_test && ! $found_production; then
  echo "ad manifest validation: FAIL ($artifact): no known AdMob app ID found in manifest" >&2
  exit 1
fi

if $found_test; then
  found_class=test
else
  found_class=production
fi

if [[ "$found_class" != "$expected" ]]; then
  echo "ad manifest validation: FAIL ($artifact): expected=$expected found=$found_class" >&2
  exit 1
fi

echo "ad manifest validation: PASS ($artifact): expected=$expected found=$found_class"
