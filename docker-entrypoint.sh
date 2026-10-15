#!/bin/sh
set -eu

config=${XONOTIC_CONFIG_PATH:-/opt/Xonotic/data/server.cfg}
temporary_config="${config}.tmp"

escape_config_value() {
  # Xonotic uses double quotes and semicolons in its console syntax. Newlines,
  # quotes, and backslashes must not be able to turn an environment value into
  # another command.
  printf '%s' "$1" | tr '\r\n' '  ' | sed 's/[\\"]/\\&/g'
}

resolve_setting() {
  # Prefer a mounted secret file ($2) over an inline value ($1) so operators can
  # avoid exposing passwords through the container environment or `docker inspect`.
  if [ -n "${2:-}" ]; then
    if ! value=$(tr -d '\r\n' < "$2" 2>/dev/null); then
      printf 'FATAL: cannot read secret file: %s\n' "$2" >&2
      exit 1
    fi
    printf '%s' "$value"
  else
    printf '%s' "${1:-}"
  fi
}

cleanup() {
  rm -f "$temporary_config"
}
trap cleanup EXIT HUP INT TERM

hostname_value=$(resolve_setting "${XONOTIC_HOSTNAME:-}" "${XONOTIC_HOSTNAME_FILE:-}")
join_password_value=$(resolve_setting "${XONOTIC_JOIN_PASSWORD:-}" "${XONOTIC_JOIN_PASSWORD_FILE:-}")
rcon_password_value=$(resolve_setting "${XONOTIC_RCON_PASSWORD:-}" "${XONOTIC_RCON_PASSWORD_FILE:-}")

if [ -f "$config" ]; then
  # Strip the current managed block plus any legacy variants written by earlier
  # releases so upgrades do not leave stale settings behind.
  awk '
    /^\/\/ BEGIN .*MANAGED SETTINGS$/ { managed = 1; next }
    /^\/\/ END .*MANAGED SETTINGS$/ { managed = 0; next }
    !managed { print }
  ' "$config" > "$temporary_config"
else
  : > "$temporary_config"
fi

{
  echo '// BEGIN MANAGED SETTINGS'
  if [ -n "$hostname_value" ]; then
    printf 'hostname "%s"\n' "$(escape_config_value "$hostname_value")"
  fi
  if [ -n "$join_password_value" ]; then
    printf 'password "%s"\n' "$(escape_config_value "$join_password_value")"
  fi
  if [ -n "$rcon_password_value" ]; then
    printf 'rcon_password "%s"\n' "$(escape_config_value "$rcon_password_value")"
  fi
  echo '// END MANAGED SETTINGS'
} >> "$temporary_config"

mv "$temporary_config" "$config"
chmod 600 "$config"

exec "$@"
