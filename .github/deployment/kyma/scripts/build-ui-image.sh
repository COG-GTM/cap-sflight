#!/bin/bash

set -e
cd "$(dirname "$(npm root)")"
DIR="$(pwd)/.github"

# Pinned build-time tooling. Override only with a version that has been reviewed.
YAML_VERSION="${YAML_VERSION:-2.9.1}"
HTML5_APP_DEPLOYER_VERSION="${HTML5_APP_DEPLOYER_VERSION:-7.2.4}"

npm install --no-save --ignore-scripts "yaml@$YAML_VERSION"

function value() {
    node "$DIR/deployment/kyma/scripts/value.js" "$1"
}

function image() {
    local REPOSITORY="$(value "$1.image.repository")"
    local TAG="$(value "$1.image.tag")"
    if [ "$TAG" != "" ]; then
        echo "$REPOSITORY:$TAG"
    else
        echo "$REPOSITORY"
    fi
}

rm -rf gen/ui
mkdir -p gen/ui/resources

CLOUD_SERVICE="$(value html5-apps-deployer.env.SAP_CLOUD_SERVICE)"
DESTINATIONS="$(value backendDestinations)"

IMAGE="$(image html5-apps-deployer)"

for APP in app/*; do
    if [ -f "$APP/webapp/manifest.json" ]; then
        echo "Build $APP..."
        echo

        rm -rf "gen/$APP"
        mkdir -p "gen/app"
        cp -r "$APP" gen/app
        pushd >/dev/null "gen/$APP"

        node "$DIR/deployment/kyma/scripts/prepareUiFiles.js" $CLOUD_SERVICE $DESTINATIONS
        if [ -f package-lock.json ]; then
            npm ci --ignore-scripts
        else
            echo "WARNING: no package-lock.json in $APP, dependency versions are not pinned" >&2
            npm install --ignore-scripts
        fi
        ./node_modules/.bin/ui5 build preload --clean-dest --config ui5-deploy.yaml --include-task=generateManifestBundle generateCachebusterInfo
        cd dist
        rm manifest-bundle.zip
        mv *.zip "$DIR/gen/ui/resources"

        popd >/dev/null
    fi
done

cd gen/ui

echo
echo "HTML5 Apps:"
ls -l resources
echo

cat >package.json <<EOF
{
    "name": "ui-deployer",
    "scripts": { "start": "node node_modules/@sap/html5-app-deployer/index.js" },
    "dependencies": { "@sap/html5-app-deployer": "$HTML5_APP_DEPLOYER_VERSION" }
}
EOF

npm install --ignore-scripts "@sap/html5-app-deployer@$HTML5_APP_DEPLOYER_VERSION"
pack build $IMAGE --path . --buildpack gcr.io/paketo-buildpacks/nodejs --builder paketobuildpacks/builder-jammy-base
