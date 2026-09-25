#!/usr/bin/env bash

# Installs the SAP btp CLI from SAP's official distribution host into
# /usr/local/bin. The tarball is checked against the pinned digest in
# btp-cli.sha256 when that file contains one.

set -euo pipefail

declare -r ARCH="linux-amd64"
declare -r LICENCE="tools.hana.ondemand.com/developer-license-3_1.txt"
declare -r VERSION="${BTP_CLI_VERSION:-latest}"
declare -r TARBALL="btp-cli-${ARCH}-${VERSION}.tar.gz"
declare -r URL="https://tools.hana.ondemand.com/additional/${TARBALL}"
declare -r CHECKSUM_FILE="$(dirname "$0")/btp-cli.sha256"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --proto '=https' \
  --tlsv1.2 \
  --header "Cookie: eula_3_1_agreed=${LICENCE}; path=/;" \
  --output "${tmpdir}/${TARBALL}" \
  "$URL"

expected=""
if [[ -f $CHECKSUM_FILE ]]; then
  expected="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$CHECKSUM_FILE" | tr -d '\n')"
fi

if [[ -n $expected ]]; then
  echo "${expected}  ${tmpdir}/${TARBALL}" | sha256sum --check --status
  echo "Verified ${TARBALL} against pinned digest"
else
  echo "WARNING: no digest pinned in ${CHECKSUM_FILE}; skipping integrity check" >&2
  echo "WARNING: record the output of 'sha256sum ${TARBALL}' there to enable it" >&2
fi

tar \
  --file "${tmpdir}/${TARBALL}" \
  --extract \
  --gunzip \
  --directory "$tmpdir" \
  --strip-components 1 \
  "${ARCH}/btp"

install -m 0755 "${tmpdir}/btp" /usr/local/bin/btp
