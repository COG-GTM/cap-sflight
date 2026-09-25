#!/bin/bash
set -e

export INPUT_USERNAME=${INPUT_USERNAME:-$CF_USERNAME}
INPUT_PASSWORD=${INPUT_PASSWORD:-$CF_PASSWORD}

# Log in without putting the password into the process table: btp reads it from
# its interactive prompt, which is fed through a pty provided by script(1).
btp_login() {
  local fifo writer status

  if ! command -v script > /dev/null; then
    printf '%s\n' "script(1) is required to log in to BTP without exposing the password" >&2
    return 1
  fi

  fifo=$(mktemp -u)
  mkfifo -m 600 "${fifo}"
  # Holding both ends keeps script(1) from seeing EOF on stdin and tearing down
  # the login before the prompt has been answered.
  exec 3<> "${fifo}"

  # Answer the prompt only once the CLI has had time to turn terminal echo off,
  # so the password does not end up in the action log.
  ( sleep 3; printf '%s\n' "${INPUT_PASSWORD}" >&3 ) > /dev/null 2>&1 &
  writer=$!

  status=0
  script -qec 'stty -echo; btp login --url "${INPUT_CLI_URL}" --user "${INPUT_USERNAME}" --subdomain "${INPUT_SUBDOMAIN}"' /dev/null < "${fifo}" || status=$?

  wait "${writer}" 2> /dev/null || true
  exec 3>&-
  exec 3<&-
  rm -f "${fifo}"

  return ${status}
}

btp_login

if [ ! -z "${INPUT_SUBACCOUNT_ID}" ]; then
  btp target --subaccount "${INPUT_SUBACCOUNT_ID}"
fi

if [ ! -z "${INPUT_ROLE_COLLECTION}" ]; then
  btp assign security/role-collection ${INPUT_ROLE_COLLECTION} --to-user ${INPUT_USERNAME} > /dev/null

  if [ ! -z "${GRANT_USERS}" ]; then
    for user in ${GRANT_USERS//\\n/ }  # newline separated
    do
      btp assign security/role-collection ${INPUT_ROLE_COLLECTION} --to-user ${user} --create-user-if-missing
    done
  fi

fi

if [ ! -z "${INPUT_COMMAND}" ]; then
  ${INPUT_COMMAND}
fi
