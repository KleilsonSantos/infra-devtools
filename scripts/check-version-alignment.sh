#!/usr/bin/env bash
# DEPRECATED — do not use in hooks or CI.
# Replaced by:
#   scripts/version.sh check
#   scripts/check-semver-alignment.sh
# See docs/guides/releases.md and ADR-0002 (#57).
set -euo pipefail
echo "DEPRECATED: scripts/check-version-alignment.sh" >&2
echo "Use: bash scripts/version.sh check" >&2
echo "Use: bash scripts/check-semver-alignment.sh" >&2
exit 2
