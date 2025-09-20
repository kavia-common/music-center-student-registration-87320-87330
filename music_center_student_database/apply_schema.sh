#!/bin/bash
set -euo pipefail

# Apply schema to MySQL using one-line mysql -e statements read from schema_apply_commands.sql
# Credentials must be read from db_connection.txt per MySQL Container CRITICAL Rules.

CONN_FILE="db_connection.txt"
SCHEMA_COMMANDS_FILE="schema_apply_commands.sql"

if [ ! -f "$CONN_FILE" ]; then
  echo "ERROR: $CONN_FILE not found. Startup should have generated it."
  exit 1
fi

if [ ! -f "$SCHEMA_COMMANDS_FILE" ]; then
  echo "ERROR: $SCHEMA_COMMANDS_FILE not found."
  exit 1
fi

# Parse connection details from the single-line mysql command
# Expected format: mysql -u appuser -pdbuser123 -h localhost -P 5000 myapp
MYSQL_CMD_LINE="$(cat "$CONN_FILE")"

# Extract user, pass, host, port safely
USER="$(echo "$MYSQL_CMD_LINE" | sed -n 's/.*-u[[:space:]]*\([^[:space:]]\+\).*/\1/p')"
PASS="$(echo "$MYSQL_CMD_LINE" | sed -n 's/.*-p\([^[:space:]]\+\).*/\1/p')"
HOST="$(echo "$MYSQL_CMD_LINE" | sed -n 's/.*-h[[:space:]]*\([^[:space:]]\+\).*/\1/p')"
PORT="$(echo "$MYSQL_CMD_LINE" | sed -n 's/.*-P[[:space:]]*\([^[:space:]]\+\).*/\1/p')"

if [ -z "${USER:-}" ] || [ -z "${PASS:-}" ] || [ -z "${HOST:-}" ] || [ -z "${PORT:-}" ]; then
  echo "ERROR: Failed to parse connection details from $CONN_FILE"
  exit 1
fi

echo "Applying database schema to MySQL at $HOST:$PORT as $USER ..."

# Execute each non-empty, non-comment line with mysql -e "<SQL>"
while IFS= read -r line; do
  # Trim leading/trailing whitespace
  trimmed="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  # Skip comments and empty lines
  if [ -z "$trimmed" ] || [[ "$trimmed" == --* ]]; then
    continue
  fi
  echo "-> Executing: ${trimmed:0:100}..."
  mysql -u "$USER" -p"$PASS" -h "$HOST" -P "$PORT" -e "$trimmed"
done < "$SCHEMA_COMMANDS_FILE"

echo "✓ Schema applied successfully."
