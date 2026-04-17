#!/usr/bin/env bash
#
# Bump the build number in pubspec.yaml and build a release APK.
#
# Usage:
#   bash scripts/release-apk.sh          # bump +N by 1 and build APK
#   bash scripts/release-apk.sh aab      # build AAB (bundle) instead
#   bash scripts/release-apk.sh minor    # bump minor (X.Y.Z -> X.(Y+1).0), reset +N to 1
#   bash scripts/release-apk.sh major    # bump major (X.Y.Z -> (X+1).0.0), reset +N to 1
#
set -euo pipefail

cd "$(dirname "$0")/.."

mode="${1:-build}"

current=$(grep -E '^version:[[:space:]]' pubspec.yaml | head -n1 | awk '{print $2}')
if [[ -z "$current" ]]; then
  echo "ERROR: could not find version line in pubspec.yaml" >&2
  exit 1
fi

name="${current%+*}"
code="${current#*+}"

case "$mode" in
  major)
    IFS='.' read -r maj min pat <<<"$name"
    name="$((maj + 1)).0.0"
    code=1
    ;;
  minor)
    IFS='.' read -r maj min pat <<<"$name"
    name="${maj}.$((min + 1)).0"
    code=1
    ;;
  *)
    code=$((code + 1))
    ;;
esac

new_version="${name}+${code}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version:[[:space:]].*/version: ${new_version}/" pubspec.yaml
else
  sed -i "s/^version:[[:space:]].*/version: ${new_version}/" pubspec.yaml
fi

echo "Version: ${current} -> ${new_version}"
echo

flutter clean
if [[ "$mode" == "aab" ]]; then
  flutter build appbundle --release
  out="build/app/outputs/bundle/release/app-release.aab"
else
  flutter build apk --release
  out="build/app/outputs/flutter-apk/app-release.apk"
fi

echo
echo "Built: ${out}"
echo "Version: ${new_version}"
