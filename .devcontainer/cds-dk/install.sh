#!/bin/sh
set -e

# Keep in sync with the @sap/cds-dk version resolved in package-lock.json.
DEFAULT_VERSION="10.1.1"

# Minimum versions of the bundled database packages that are known good.
MIN_DB_SERVICE_VERSION="2.11.0"
MIN_SQLITE_VERSION="2.4.0"

VERSION="${VERSION:-}"
if [ -z "${VERSION}" ] || [ "${VERSION}" = "latest" ]; then
    VERSION="${DEFAULT_VERSION}"
fi

if ! echo "${VERSION}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
    echo "Refusing to install @sap/cds-dk@${VERSION}: an exact version is required (e.g. ${DEFAULT_VERSION})." >&2
    exit 1
fi

. ${NVM_DIR}/nvm.sh

npm i -g "@sap/cds-dk@${VERSION}"

MIN_DB_SERVICE_VERSION="${MIN_DB_SERVICE_VERSION}" MIN_SQLITE_VERSION="${MIN_SQLITE_VERSION}" node -e '
const { execFileSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const root = execFileSync("npm", ["root", "-g"], { encoding: "utf8" }).trim();
const floors = {
  "@cap-js/db-service": process.env.MIN_DB_SERVICE_VERSION,
  "@cap-js/sqlite": process.env.MIN_SQLITE_VERSION,
};

const cmp = (a, b) => {
  const pa = a.split("-")[0].split(".").map(Number);
  const pb = b.split("-")[0].split(".").map(Number);
  for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] - pb[i];
  return 0;
};

for (const [name, floor] of Object.entries(floors)) {
  const pkg = path.join(root, "@sap/cds-dk/node_modules", name, "package.json");
  if (!fs.existsSync(pkg)) continue;
  const { version } = JSON.parse(fs.readFileSync(pkg, "utf8"));
  if (cmp(version, floor) < 0) {
    console.error(`Bundled ${name}@${version} is below the required minimum ${floor}.`);
    process.exit(1);
  }
}
'
