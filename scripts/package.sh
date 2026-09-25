#!/usr/bin/env bash
# Builds dist/looker-to-bi-app-migration.zip for upload under Claude > Customize > Skills.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
rm -f dist/looker-to-bi-app-migration.zip
(cd skills && zip -rq ../dist/looker-to-bi-app-migration.zip looker-to-bi-app-migration)
echo "Built dist/looker-to-bi-app-migration.zip"
