#!/bin/sh
set -e

MBT_VERSION="${MBTVERSION:-1.2.49}"
CF_CLI_PACKAGE="${CFCLIPACKAGE:-cf8-cli}"
CF_CLI_KEYRING=/usr/share/keyrings/cloudfoundry-cli.gpg

# Cloud Foundry CLI from the official Debian repository. apt verifies every
# package against the keyring below, so no remote script is executed.
if ! type cf >/dev/null 2>&1; then
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl gnupg
    curl -fsSL https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key \
        | gpg --dearmor -o "${CF_CLI_KEYRING}"
    echo "deb [signed-by=${CF_CLI_KEYRING}] https://packages.cloudfoundry.org/debian stable main" \
        > /etc/apt/sources.list.d/cloudfoundry-cli.list
    apt-get update
    apt-get install -y --no-install-recommends "${CF_CLI_PACKAGE}"
    rm -rf /var/lib/apt/lists/*
fi

su vscode -s /bin/bash -c "cf install-plugin -f multiapps"

npm i -g "mbt@${MBT_VERSION}"
