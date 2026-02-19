#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${ROOT_DIR}/TOPIC_GENERATION_PROMPT.md"

usage() {
  cat <<'EOF'
Usage:
  ./build_topic_prompt.sh [YYYY-MM-DD] [--copy]

Examples:
  ./build_topic_prompt.sh
  ./build_topic_prompt.sh 2026-02-20
  ./build_topic_prompt.sh 2026-02-20 --copy

Required env vars:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY

If no date is passed, it uses the next date after your latest Topic row.

This command prints a filled prompt to stdout by replacing:
  {{DATE}}
  {{PAST_ANSWERS}}
EOF
}

TARGET_DATE=""
COPY_OUTPUT=false

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --copy)
      COPY_OUTPUT=true
      ;;
    *)
      if [[ -z "${TARGET_DATE}" ]]; then
        TARGET_DATE="$arg"
      else
        echo "Unknown argument: $arg" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "Missing SUPABASE_URL env var." >&2
  exit 1
fi

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "Missing SUPABASE_SERVICE_ROLE_KEY env var." >&2
  exit 1
fi

if [[ "${SUPABASE_SERVICE_ROLE_KEY}" == sb_publishable_* ]]; then
  echo "SUPABASE_SERVICE_ROLE_KEY cannot be your publishable key." >&2
  exit 1
fi

if [[ ! -f "${TEMPLATE_PATH}" ]]; then
  echo "Missing template file: ${TEMPLATE_PATH}" >&2
  exit 1
fi

fetch_topics() {
  local table_name="$1"
  local url="${SUPABASE_URL%/}/rest/v1/${table_name}?select=answer,date&order=date.asc"

  curl -sS --fail-with-body "${url}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json"
}

add_one_day() {
  local input_date="$1"
  if date -u -j -v+1d -f "%Y-%m-%d" "${input_date}" "+%Y-%m-%d" >/dev/null 2>&1; then
    date -u -j -v+1d -f "%Y-%m-%d" "${input_date}" "+%Y-%m-%d"
    return
  fi

  date -u -d "${input_date} +1 day" "+%Y-%m-%d"
}

TOPICS_JSON=""
for table_name in Topic topic; do
  if response="$(fetch_topics "${table_name}" 2>/dev/null)"; then
    if printf "%s" "${response}" | jq -e 'type == "array"' >/dev/null 2>&1; then
      TOPICS_JSON="${response}"
      break
    fi
  fi
done

if [[ -z "${TOPICS_JSON}" ]]; then
  echo "Failed to fetch topics from Supabase (tried Topic and topic)." >&2
  exit 1
fi

if [[ -z "${TARGET_DATE}" ]]; then
  LATEST_DATE="$(
    printf "%s" "${TOPICS_JSON}" | jq -r '
      [.[].date | strings | .[0:10]]
      | max // empty
    '
  )"

  if [[ -n "${LATEST_DATE}" ]]; then
    TARGET_DATE="$(add_one_day "${LATEST_DATE}")"
  else
    TARGET_DATE="$(date -u +%Y-%m-%d)"
  fi
fi

if [[ ! "${TARGET_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Date must be in YYYY-MM-DD format." >&2
  exit 1
fi

PAST_ANSWERS="$(
  printf "%s" "${TOPICS_JSON}" | jq -r '
    [.[].answer | strings]
    | reduce .[] as $answer ([]; if index($answer) then . else . + [$answer] end)
    | join(", ")
  '
)"

if [[ -z "${PAST_ANSWERS}" ]]; then
  PAST_ANSWERS="None"
fi

TEMPLATE_CONTENT="$(cat "${TEMPLATE_PATH}")"
FILLED_PROMPT="${TEMPLATE_CONTENT//'{{DATE}}'/${TARGET_DATE}}"
FILLED_PROMPT="${FILLED_PROMPT//'{{PAST_ANSWERS}}'/${PAST_ANSWERS}}"

if [[ "${COPY_OUTPUT}" == true ]]; then
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s\n" "${FILLED_PROMPT}" | pbcopy
    echo "Filled prompt copied to clipboard." >&2
  else
    echo "--copy requested but pbcopy is not available. Printing only." >&2
  fi
fi

printf "%s\n" "${FILLED_PROMPT}"
