#!/usr/bin/env bash
# leadgen.sh — tiny client for the LeadGen.tools API v1 (used by the leadgen-tools skill).
#
#   leadgen.sh GET  <endpoint> [name=value ...]            query parameters, URL-encoded for you
#   leadgen.sh POST <endpoint> '<json>' | @file.json | -    JSON body ("-" reads stdin)
#   leadgen.sh PUT  <endpoint> '<json>' | @file.json | -
#
# Examples:
#   leadgen.sh GET companies query="dental clinics" location="Austin, TX" limit=20 with_emails=true
#   leadgen.sh GET people domain=lakesidefamilydental.com want=1 offer="Online booking for dental clinics"
#   leadgen.sh POST verify '{"emails":["info@acme.com"]}'
#
# Environment:
#   LEADGEN_API_KEY   required — LeadGen.tools → API & Agents
#   LEADGEN_BASE_URL  optional — default https://leadgen.tools/v2/api/v1
#   LEADGEN_TIMEOUT   optional — seconds, default 240 (companies with emails can take ~2 minutes)
#
# Prints the JSON response (also on API errors: read "status" / "code"). Exit code 2 = usage or setup
# error, otherwise curl's exit code. The key and the body reach curl as a config on stdin, so the key never
# appears in the process list or in shell history. Works with bash 3.2+ (macOS), Linux and Git Bash.

set -eu

usage() {
  sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

fail() { # code message
  printf '{"status":"error","code":"%s","message":"%s"}\n' "$1" "$2"
  exit 2
}

[ -n "${LEADGEN_API_KEY:-}" ] || fail missing_api_key "Set LEADGEN_API_KEY (LeadGen.tools → API & Agents)."
command -v curl >/dev/null 2>&1 || fail setup "curl is required."
[ $# -ge 2 ] || usage

method=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
endpoint=${2#/}
shift 2
case "$endpoint" in *.php) ;; *) endpoint="$endpoint.php" ;; esac
case "$endpoint" in *[!A-Za-z0-9_/.-]* | *..*) fail setup "Invalid endpoint name." ;; esac

base=${LEADGEN_BASE_URL:-https://leadgen.tools/v2/api/v1}
base=${base%/}
timeout=${LEADGEN_TIMEOUT:-240}

# A curl config value is a double-quoted string: escape backslashes, quotes and line breaks
cfg_escape() {
  printf '%s' "$1" | tr -d '\r' | awk 'BEGIN { ORS = "" } {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); if (NR > 1) printf "\\n"; print }'
}

urlencode() {
  local s=$1 out='' c i
  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    case "$c" in
      [A-Za-z0-9._~-]) out="$out$c" ;;
      *) out="$out$(printf '%%%02X' "'$c")" ;;
    esac
  done
  printf '%s' "$out"
}

config="silent
show-error
max-time = $timeout
header = \"Accept: application/json\"
header = \"User-Agent: leadgen-tools-skill/1.0\""

case "$method" in
  GET)
    config="$config
get
url = \"$base/$endpoint\"
data-urlencode = \"api_key=$(cfg_escape "$LEADGEN_API_KEY")\""
    for kv in "$@"; do
      case "$kv" in *=*) ;; *) fail setup "Parameters must be name=value." ;; esac
      config="$config
data-urlencode = \"$(cfg_escape "$kv")\""
    done
    ;;
  POST | PUT)
    body=${1:-'{}'}
    if [ "$body" = "-" ]; then
      body=$(cat)
    elif [ "${body#@}" != "$body" ]; then
      [ -r "${body#@}" ] || fail setup "Cannot read ${body#@}."
      body=$(cat "${body#@}")
    fi
    config="$config
request = \"$method\"
header = \"Content-Type: application/json\"
url = \"$base/$endpoint?api_key=$(urlencode "$LEADGEN_API_KEY")\"
data-binary = \"$(cfg_escape "$body")\""
    ;;
  *)
    usage
    ;;
esac

printf '%s\n' "$config" | curl -K -
echo
