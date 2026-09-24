#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-3000}"
exec node "$(dirname "$0")/server.js"
