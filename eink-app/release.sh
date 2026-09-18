#!/usr/bin/env bash
# Cut a release of the eInk image server so Home Assistant offers it as an
# update.
#
# Supervisor decides an update exists by comparing config.yaml's `version`
# against what is installed. A push with an unchanged version is invisible --
# the files move, the store shows nothing, and it looks like the push failed.
# So bumping, committing and pushing are one step here rather than three things
# to remember in order.
#
#   ./release.sh            patch bump  (1.0.0 -> 1.0.1)
#   ./release.sh minor
#   ./release.sh major
#   ./release.sh 2.3.0      an explicit version
#   ./release.sh patch -y   skip the confirmation
set -euo pipefail
cd "$(dirname "$0")"

CURRENT=$(grep -E '^version:' config.yaml | sed 's/.*"\(.*\)".*/\1/')
IFS=. read -r MA MI PA <<< "${CURRENT}"

case "${1:-patch}" in
  patch) NEXT="${MA}.${MI}.$((PA + 1))" ;;
  minor) NEXT="${MA}.$((MI + 1)).0" ;;
  major) NEXT="$((MA + 1)).0.0" ;;
  [0-9]*) NEXT="$1" ;;
  -h|--help) echo "usage: $0 [patch|minor|major|X.Y.Z] [-y]"; exit 0 ;;
  *) echo "usage: $0 [patch|minor|major|X.Y.Z] [-y]" >&2; exit 1 ;;
esac

# This pushes. Say so and stop, unless told not to -- running it to see what it
# does should not be the thing that publishes a release.
if [ "${2:-}" != "-y" ]; then
  echo "About to bump ${CURRENT} -> ${NEXT}, commit eink-app/, and PUSH to origin."
  if [ -t 0 ]; then
    read -r -p "Continue? [y/N] " REPLY
    [ "${REPLY}" = "y" ] || { echo "aborted"; exit 1; }
  else
    echo "Not a terminal and no -y given; aborting." >&2
    exit 1
  fi
fi

echo "→ ${CURRENT} → ${NEXT}"
# BSD and GNU sed disagree about -i, so write through a temp file instead.
sed "s/^version: \".*\"/version: \"${NEXT}\"/" config.yaml > config.yaml.tmp
mv config.yaml.tmp config.yaml

# Explicitly this directory, so a release never sweeps up unrelated work in
# progress elsewhere in the repo.
git add -- .
git commit -m "eink-app ${NEXT}" --quiet
git push --quiet
echo "✓ pushed ${NEXT}"
echo
echo "In Home Assistant:"
echo "  Settings > Add-ons > Add-on Store > (top right) > Check for updates"
echo "  then open eInk Image Server and press Update."
echo
echo "First time only, add the repository first:"
echo "  ... > Repositories > https://github.com/AStoker/eInk-Projects"
