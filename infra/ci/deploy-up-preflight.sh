#!/usr/bin/env bash
# Deterministic sequencing tests for infra/deploy/up.sh. Docker is replaced by
# a shell function: no Compose project, container, volume, or database is touched.
set -euo pipefail

TEST_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly TEST_REPO_ROOT
readonly DEPLOY_SCRIPT="${TEST_REPO_ROOT}/infra/deploy/up.sh"

[[ -f "${DEPLOY_SCRIPT}" ]] || {
  echo "error: missing ${DEPLOY_SCRIPT}" >&2
  exit 1
}

# shellcheck source=../deploy/up.sh
source "${DEPLOY_SCRIPT}"

TEST_TMP="$(mktemp -d)"
readonly TEST_TMP
trap 'rm -rf "${TEST_TMP}"' EXIT

EVENTS="${TEST_TMP}/events"
OUTPUT="${TEST_TMP}/output"
MOCK_MODE=success

fail() {
  echo "not ok: $*" >&2
  if [[ -f "${EVENTS}" ]]; then
    echo "events:" >&2
    while IFS= read -r line; do echo "  ${line}" >&2; done < "${EVENTS}"
  fi
  if [[ -f "${OUTPUT}" ]]; then
    echo "output:" >&2
    while IFS= read -r line; do echo "  ${line}" >&2; done < "${OUTPUT}"
  fi
  exit 1
}

env_get() {
  case "$1" in
    DB_USERNAME) printf '%s' oir_flow ;;
    DB_DATABASE) printf '%s' oir_flow ;;
    *) return 1 ;;
  esac
}

compose() {
  local sql=''

  case "$*" in
    "up -d --wait --no-build --no-deps db")
      echo db-up >> "${EVENTS}"
      ;;
    "exec -T db pg_isready -U oir_flow -d oir_flow")
      echo db-ready >> "${EVENTS}"
      ;;
    *"psql -v ON_ERROR_STOP=1 -U oir_flow -d oir_flow -tAc SELECT to_regclass('public.tenants') IS NOT NULL;")
      echo table-exists >> "${EVENTS}"
      if [[ "${MOCK_MODE}" == table-check-fails ]]; then
        return 1
      elif [[ "${MOCK_MODE}" == table-check-invalid ]]; then
        printf 'unexpected\n'
      elif [[ "${MOCK_MODE}" == fresh-database ]]; then
        printf 'f\n'
      else
        printf 't\n'
      fi
      ;;
    *"psql -v ON_ERROR_STOP=1 -P pager=off -U oir_flow -d oir_flow")
      echo readable-query >> "${EVENTS}"
      while IFS= read -r line; do
        sql+="${line}"$'\n'
      done
      [[ "${sql}" == *"${CONSOLA_PREFLIGHT_QUERY}"* ]] || return 98
      [[ "${sql}" == *"REPEATABLE READ READ ONLY"* ]] || return 98
      [[ "${sql}" == *"AS consola_collision \\gset"* ]] || return 98
      [[ "${sql}" == *"\\quit 42"* ]] || return 98
      if [[ "${MOCK_MODE}" == query-fails ]]; then
        return 1
      elif [[ "${MOCK_MODE}" == collision ]]; then
        return 42
      fi
      ;;
    "run --rm --no-deps web php artisan migrate --force --no-interaction")
      echo migration >> "${EVENTS}"
      [[ "${MOCK_MODE}" != migration-fails ]]
      ;;
    "up -d --wait --no-build"|"up -d --wait --no-build --force-recreate")
      echo "full-up:$*" >> "${EVENTS}"
      ;;
    "down --volumes")
      [[ "$*" == *"--volumes"* ]] || return 97
      [[ "$*" != *"--rmi"* ]] || return 97
      echo down-volumes >> "${EVENTS}"
      [[ "${MOCK_MODE}" != down-fails ]]
      ;;
    *)
      echo "unexpected:$*" >> "${EVENTS}"
      return 97
      ;;
  esac
}

extract_fn() {
  local name="$1"
  awk -v n="${name}" '
    $0 ~ "^" n "\\(\\) \\{" {grab=1}
    grab {print}
    grab && $0 == "}" {exit}
  ' "${DEPLOY_SCRIPT}"
}

run_case() {
  local mode="$1"
  local recreate="$2"
  : > "${EVENTS}"
  : > "${OUTPUT}"
  MOCK_MODE="${mode}"
  RESET_DATA=0

  set +e
  (start_preview_stack "${recreate}") > "${OUTPUT}" 2>&1
  CASE_STATUS=$?
  set -e
}

run_reset_case() {
  local mode="$1"
  : > "${EVENTS}"
  : > "${OUTPUT}"
  MOCK_MODE="${mode}"

  set +e
  (reset_preview_data) > "${OUTPUT}" 2>&1
  CASE_STATUS=$?
  set -e
}

run_boot_case() {
  local mode="$1"
  local recreate="$2"
  local reset="$3"
  : > "${EVENTS}"
  : > "${OUTPUT}"
  MOCK_MODE="${mode}"
  RECREATE="${recreate}"
  RESET_DATA="${reset}"

  set +e
  (boot_preview_after_images) > "${OUTPUT}" 2>&1
  CASE_STATUS=$?
  set -e
}

assert_events() {
  local expected="$1"
  local actual
  actual="$(<"${EVENTS}")"
  [[ "${actual}" == "${expected}" ]] || fail "event order differs"
}

assert_output_contains() {
  local expected="$1"
  local output
  output="$(<"${OUTPUT}")"
  [[ "${output}" == *"${expected}"* ]] || fail "output lacks: ${expected}"
}

[[ "${CONSOLA_PREFLIGHT_QUERY}" == \
  "SELECT id, name, status FROM public.tenants WHERE id = 'consola';" ]] || \
  fail "readable preflight query does not match the cutover contract"
[[ "${TENANTS_TABLE_EXISTS_QUERY}" == \
  "SELECT to_regclass('public.tenants') IS NOT NULL;" ]] || \
  fail "table-existence query does not match the fresh-database safeguard"

success_events=$'db-up\ndb-ready\ntable-exists\nreadable-query\nmigration\nfull-up:up -d --wait --no-build'
run_case success 0
[[ "${CASE_STATUS}" -eq 0 ]] || fail "successful preflight returned ${CASE_STATUS}"
assert_events "${success_events}"

fresh_database_events=$'db-up\ndb-ready\ntable-exists\nmigration\nfull-up:up -d --wait --no-build'
run_case fresh-database 0
[[ "${CASE_STATUS}" -eq 0 ]] || fail "fresh-database preflight returned ${CASE_STATUS}"
assert_events "${fresh_database_events}"
assert_output_contains "public.tenants is absent; no existing tenant collision is possible"

recreate_events=$'db-up\ndb-ready\ntable-exists\nreadable-query\nmigration\nfull-up:up -d --wait --no-build --force-recreate'
run_case success 1
[[ "${CASE_STATUS}" -eq 0 ]] || fail "successful recreate preflight returned ${CASE_STATUS}"
assert_events "${recreate_events}"

before_migration=$'db-up\ndb-ready\ntable-exists\nreadable-query'
run_case collision 0
[[ "${CASE_STATUS}" -ne 0 ]] || fail "tenant collision did not fail"
assert_events "${before_migration}"
assert_output_contains "tenant id 'consola' is reserved"
assert_output_contains "web and queue were not replaced"

run_case query-fails 0
[[ "${CASE_STATUS}" -ne 0 ]] || fail "readable preflight query failure did not fail"
assert_events "${before_migration}"
assert_output_contains "could not query public.tenants"

run_case table-check-fails 0
[[ "${CASE_STATUS}" -ne 0 ]] || fail "table-existence query failure was treated as table absence"
assert_events $'db-up\ndb-ready\ntable-exists'
assert_output_contains "could not determine whether public.tenants exists"

run_case table-check-invalid 0
[[ "${CASE_STATUS}" -ne 0 ]] || fail "invalid table-existence result was treated as table absence"
assert_events $'db-up\ndb-ready\ntable-exists'
assert_output_contains "unexpected public.tenants existence result 'unexpected'"

run_case migration-fails 0
[[ "${CASE_STATUS}" -ne 0 ]] || fail "central migration failure did not fail"
assert_events $'db-up\ndb-ready\ntable-exists\nreadable-query\nmigration'
assert_output_contains "central migrations failed"
assert_output_contains "web and queue were not replaced"

echo "ok: deploy preflight orders db, existence check, collision query, migration, then full up"
echo "ok: fresh database skips collision query, then runs migration before full up"
echo "ok: existence, query, collision, and migration failures abort before web/queue replacement"

usage_text="$(usage)"
[[ "${usage_text}" == *"[--build|--no-build] [--recreate] [--reset-data]"* ]] || \
  fail "usage does not list --reset-data with the existing flags"
[[ "${usage_text}" == *"--reset-data"* ]] || fail "usage omits --reset-data"

header="$(head -n 8 "${DEPLOY_SCRIPT}")"
[[ "${header}" == *"[--build|--no-build] [--recreate] [--reset-data]"* ]] || \
  fail "header does not list --reset-data"

BUILD_MODE=auto
RECREATE=0
RESET_DATA=0
parse_preview_up_args --reset-data --recreate --no-build
[[ "${BUILD_MODE}" == nobuild ]] || fail "--reset-data --recreate --no-build did not keep --no-build"
[[ "${RECREATE}" -eq 1 ]] || fail "--reset-data --recreate --no-build did not set --recreate"
[[ "${RESET_DATA}" -eq 1 ]] || fail "--reset-data --recreate --no-build did not set --reset-data"

BUILD_MODE=auto
RECREATE=0
RESET_DATA=0
parse_preview_up_args --build --reset-data
[[ "${BUILD_MODE}" == build ]] || fail "--build --reset-data did not set --build"
[[ "${RECREATE}" -eq 0 ]] || fail "--build --reset-data implied --recreate"
[[ "${RESET_DATA}" -eq 1 ]] || fail "--build --reset-data did not set --reset-data"

BUILD_MODE=auto
RECREATE=0
RESET_DATA=0
parse_preview_up_args --reset-data
[[ "${BUILD_MODE}" == auto ]] || fail "--reset-data implied --build"
[[ "${RECREATE}" -eq 0 ]] || fail "--reset-data implied --recreate"
[[ "${RESET_DATA}" -eq 1 ]] || fail "--reset-data did not set RESET_DATA"

: > "${OUTPUT}"
set +e
(parse_preview_up_args --bogus) > "${OUTPUT}" 2>&1
CASE_STATUS=$?
set -e
[[ "${CASE_STATUS}" -eq 2 ]] || fail "unknown argument did not exit 2 (got ${CASE_STATUS})"

BUILD_MODE=auto
RECREATE=0
RESET_DATA=0

run_reset_case success
[[ "${CASE_STATUS}" -eq 0 ]] || fail "reset_preview_data returned ${CASE_STATUS}"
assert_events $'down-volumes'
assert_output_contains "RESET-DATA: compose down --volumes"

run_reset_case down-fails
[[ "${CASE_STATUS}" -ne 0 ]] || fail "reset_preview_data did not fail when down failed"
assert_events $'down-volumes'
assert_output_contains "compose down --volumes failed"
assert_output_contains "preview stack was not started"

run_boot_case success 0 1
[[ "${CASE_STATUS}" -eq 0 ]] || fail "boot with --reset-data returned ${CASE_STATUS}"
assert_events $'down-volumes\n'"${success_events}"

run_boot_case success 1 1
[[ "${CASE_STATUS}" -eq 0 ]] || fail "boot with --reset-data --recreate returned ${CASE_STATUS}"
assert_events $'down-volumes\n'"${recreate_events}"

run_boot_case success 0 0
[[ "${CASE_STATUS}" -eq 0 ]] || fail "boot with reset off returned ${CASE_STATUS}"
assert_events "${success_events}"

run_boot_case down-fails 0 1
[[ "${CASE_STATUS}" -ne 0 ]] || fail "boot with --reset-data did not fail when down failed"
assert_events $'down-volumes'
assert_output_contains "compose down --volumes failed"

start_fn="$(extract_fn start_preview_stack)"
[[ -n "${start_fn}" ]] || fail "could not extract start_preview_stack"
[[ "${start_fn}" != *down* ]] || fail "start_preview_stack must not down"

reset_fn="$(extract_fn reset_preview_data)"
[[ -n "${reset_fn}" ]] || fail "could not extract reset_preview_data"
[[ "${reset_fn}" == *"compose down --volumes"* ]] || \
  fail "reset_preview_data must call compose down --volumes"
[[ "${reset_fn}" != *"--rmi"* ]] || fail "reset_preview_data must not pass --rmi"
[[ "${reset_fn}" != *"start_preview_stack"* ]] || \
  fail "reset_preview_data must not start the stack"
[[ "${reset_fn}" != *$'\n'*read* && "${reset_fn}" != *' read '* ]] || \
  fail "reset_preview_data must not prompt"

boot_fn="$(extract_fn boot_preview_after_images)"
[[ -n "${boot_fn}" ]] || fail "could not extract boot_preview_after_images"
case "${boot_fn}" in
  *"reset_preview_data"*"start_preview_stack"*) ;;
  *) fail "boot_preview_after_images must reset then start_preview_stack" ;;
esac

main_fn="$(extract_fn main)"
[[ -n "${main_fn}" ]] || fail "could not extract main"
[[ "${main_fn}" != *"reset_preview_data"* ]] || \
  fail "main must not call reset_preview_data (wipe belongs in boot_preview_after_images after the image gate)"
[[ "${main_fn}" != *"start_preview_stack"* ]] || \
  fail "main must not call start_preview_stack (boot_preview_after_images owns that)"
[[ "${main_fn}" != *down* ]] || fail "main must not down"
case "${main_fn}" in
  *"images missing"*"boot_preview_after_images"*) ;;
  *) fail "main must die on missing images before boot_preview_after_images" ;;
esac
case "${main_fn}" in
  *"boot_preview_after_images"*"images missing"*)
    fail "reset_preview_data / boot_preview_after_images must not run before the missing-image die"
    ;;
esac

echo "ok: --reset-data is opt-in, listed in usage/header, and combines with --build/--no-build/--recreate"
echo "ok: reset_preview_data records down --volumes (no --rmi) and does not start the stack"
echo "ok: down failure dies before start_preview_stack"
echo "ok: boot_preview_after_images wipes then existing start_preview_stack order; reset off is additive"
echo "ok: start_preview_stack does not down; main dies on missing images before any wipe"
