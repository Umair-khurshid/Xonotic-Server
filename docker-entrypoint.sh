#!/bin/sh
set -eu

config=${XONOTIC_CONFIG_PATH:-/opt/Xonotic/data/server.cfg}
temporary_config="${config}.tmp"

escape_config_value() {
  # Xonotic uses double quotes and semicolons in its console syntax. Newlines,
  # quotes, and backslashes must not be able to turn an environment value into
  # another command.
  printf '%s' "$1" | tr '\r\n' '  ' | sed 's/[\\\\"]/\\\\&/g'
}

cleanup() {
  rm -f "$temporary_config"
}
trap cleanup EXIT HUP INT TERM

if [ -f "$config" ]; then
  awk '
    /^\/\/ BEGIN CODEX MANAGED SETTINGS$/ { managed = 1; next }
    /^\/\/ END CODEX MANAGED SETTINGS$/ { managed = 0; next }
    !managed { print }
  ' "$config" > "$temporary_config"
else
  : > "$temporary_config"
fi

{
  echo '// BEGIN CODEX MANAGED SETTINGS'
  if [ -n "${XONOTIC_HOSTNAME:-}" ]; then
    printf 'hostname "%s"\n' "$(escape_config_value "$XONOTIC_HOSTNAME")"
  fi
  if [ -n "${XONOTIC_JOIN_PASSWORD:-}" ]; then
    printf 'password "%s"\n' "$(escape_config_value "$XONOTIC_JOIN_PASSWORD")"
  fi
  if [ -n "${XONOTIC_RCON_PASSWORD:-}" ]; then
    printf 'rcon_password "%s"\n' "$(escape_config_value "$XONOTIC_RCON_PASSWORD")"
  fi
  echo '// END CODEX MANAGED SETTINGS'
} >> "$temporary_config"

mv "$temporary_config" "$config"
chmod 600 "$config"

exec "$@"
