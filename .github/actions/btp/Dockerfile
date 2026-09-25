FROM buildpack-deps:stretch-curl

# btp CLI installation, see
# https://blogs.sap.com/2021/09/01/sap-tech-bytes-btp-cli-installation/
ARG BTP_CLI_VERSION=latest
COPY install-btp-cli.sh btp-cli.sha256 /tmp/btp-cli/
RUN BTP_CLI_VERSION="$BTP_CLI_VERSION" /tmp/btp-cli/install-btp-cli.sh && rm -rf /tmp/btp-cli

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
