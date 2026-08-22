#!/usr/bin/env bash
#
# The env contract's single enforcement engine — one script, two entry points.
#
#   Usage:  infra/hooks/sync-preview-env.sh                          (sync, default)
#           infra/hooks/sync-preview-env.sh --check                  (report only)
#           infra/hooks/sync-preview-env.sh --check --source .env.example
#           infra/hooks/sync-preview-env.sh --source <file>
#
# THE CHAIN IT ENFORCES, its two links and the rule that there is deliberately no second
# implementation: infra/README.md § infra/hooks/ — the env contract.
#
#   LINK 1 — sync mode, a CaptainHook `pre-commit` action from the volatile root `.env`.
#   LINK 2 — check mode, `--check --source .env.example`, run by infra/ci/env-contract.sh.
#
# Lives in infra/hooks/ and not in infra/ddev/hooks/ or infra/deploy/: infra/README.md
# § infra/hooks/ — the env contract.

set -euo pipefail
unset CDPATH

# ---------------------------------------------------------------------------
# Exclusion list — keys that exist in the DDEV root `.env` and are DELIBERATELY
# absent from the PREVIEW topology. Adding a key here means: "this key belongs
# to DDEV only (or to Laravel's defaults) and must never reach infra/deploy/."
# Removing a key here makes the next run propagate it. Keep it sorted-ish by
# group and keep a reason on every group.
#
# SCOPE, and it is not the obvious one: this list filters the two PREVIEW
# targets only. It does NOT filter root `.env.example`, which is the DDEV
# template and therefore the one file every one of these keys legitimately
# belongs in — several are in it already. Applying the list there would make the
# template a subset of the environment it is a template for, and would break
# Link 2 by hiding exactly the keys the preview stack deliberately drops.
# ---------------------------------------------------------------------------
EXCLUDED_KEYS=(
    # Laravel defaults the preview stack is happy to inherit from config/**.
    APP_MAINTENANCE_DRIVER
    APP_MAINTENANCE_STORE
    BCRYPT_ROUNDS
    PHP_CLI_SERVER_WORKERS

    # Logging detail beyond LOG_CHANNEL/LOG_LEVEL — preview pins only those two.
    LOG_STACK
    LOG_DEPRECATIONS_CHANNEL

    # Session tuning kept at framework defaults; preview pins SESSION_DRIVER and
    # SESSION_SECURE_COOKIE only (the latter is preview-only, HTTPS topology).
    SESSION_LIFETIME
    SESSION_ENCRYPT
    SESSION_PATH
    SESSION_DOMAIN

    # Not wired in the preview stack.
    BROADCAST_CONNECTION
    MEMCACHED_HOST
    CACHE_PREFIX

    # No S3/object storage in the preview topology (FILESYSTEM_DISK=local).
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_DEFAULT_REGION
    AWS_BUCKET
    AWS_USE_PATH_STYLE_ENDPOINT

    # Build-time only — assets are compiled into the platform image, never read
    # from the container environment at runtime.
    VITE_APP_NAME
)

# ---------------------------------------------------------------------------
# Anchor exemptions — keys that infra/deploy/.env.example declares and that are
# DELIBERATELY absent from `x-platform-environment`, because nothing inside a
# container ever reads them. Every entry is a VERIFIED consumer, not a guess;
# without this list assertion (b) below would be red on arrival, and a gate that
# is red on arrival gets disabled rather than fixed
# (infra/ci/contract-lint.sh states the principle).
#
#   CONSOLE_ADMIN_EMAIL     read by infra/deploy/up.sh and passed to
#   CONSOLE_ADMIN_NAME      `artisan console:administrator` as CLI ARGUMENTS
#   CONSOLE_ADMIN_PASSWORD  (up.sh, "asserting console operator") — putting the
#                           operator password in the long-lived container
#                           environment of web AND queue would widen it for no
#                           gain.
#   DB_HOST_PORT            consumed by Compose itself in the `db` service's
#                           `ports:` mapping, and echoed by up.sh. The app talks
#                           to DB_HOST/DB_PORT on the compose network and has no
#                           use for the host-side publish port.
#
# Adding a key here is a claim that it has a non-container consumer. Name that
# consumer in a comment or the exemption is indistinguishable from a silence.
# ---------------------------------------------------------------------------
ANCHOR_EXEMPT_KEYS=(
    CONSOLE_ADMIN_EMAIL
    CONSOLE_ADMIN_NAME
    CONSOLE_ADMIN_PASSWORD
    DB_HOST_PORT
)

# ---------------------------------------------------------------------------
# Preview-only keys — declared by infra/deploy/.env.example and DELIBERATELY
# absent upstream, because the preview topology is HTTPS, seeded and
# operator-provisioned and DDEV is none of those. They are what makes the
# upstream comparison SAFE TO RUN IN BOTH DIRECTIONS: without this list the
# reverse assertion would flag the topology difference itself, and a gate that
# is red on arrival gets disabled rather than fixed.
#
# WHY THE REVERSE DIRECTION IS CHECKED AT ALL. The forward assertion — every
# upstream key reaches the preview contract — is satisfied trivially by an
# upstream file that has LOST a key: a smaller source always fits inside a
# larger downstream. That is precisely the drift this project actually had
# (LOGIN_THROTTLE_ENABLED sat in root `.env`, infra/deploy/.env.example and the
# anchor, and was MISSING from root `.env.example` — committed and undetected),
# so a forward-only check would have gone green over the very defect that
# motivated it.
#
# Every entry names the mechanism that supplies it upstream instead, verified,
# not assumed:
#
#   SESSION_SECURE_COOKIE  preview is HTTPS-only (compose web publishes :443
#   TLS_HOSTNAME           and nginx terminates TLS); DDEV has neither concern.
#   DB_HOST_PORT           host-side publish of Postgres — a Compose-level
#                          concern, and DDEV pins host_db_port itself.
#   REDIS_QUEUE_RETRY_AFTER must exceed the preview `queue:work --timeout=360`;
#                          DDEV runs no queue worker service.
#   ENGINE_URL             injected as DDEV CONTAINER variables instead of via
#   ENGINE_KEY             `.env` (infra/ddev/config.stub.yaml → web_environment),
#   MAIL_FROM_ADDRESS      because dotenv never overwrites a real container
#                          variable but does skip a stale `.env` line.
#   MAIL_FROM_NAME         preview pins it; DDEV inherits config/mail.php's
#                          fallback to APP_NAME (verified in config/mail.php).
#   CONSOLE_ADMIN_EMAIL    first console operator and the staging seed secret,
#   CONSOLE_ADMIN_NAME     both required by infra/deploy/up.sh. DDEV provisions
#   CONSOLE_ADMIN_PASSWORD its operator and tenants through the post-start hook
#   STAGING_SEED_PASSWORD  instead (infra/ddev/hooks/dev-install.sh).
#
# Adding a key here is a claim that the local runtime supplies it another way.
# Name that way, or the exemption is indistinguishable from forgetting the key.
# ---------------------------------------------------------------------------
PREVIEW_ONLY_KEYS=(
    SESSION_SECURE_COOKIE
    TLS_HOSTNAME
    DB_HOST_PORT
    REDIS_QUEUE_RETRY_AFTER
    ENGINE_URL
    ENGINE_KEY
    MAIL_FROM_ADDRESS
    MAIL_FROM_NAME
    CONSOLE_ADMIN_EMAIL
    CONSOLE_ADMIN_NAME
    CONSOLE_ADMIN_PASSWORD
    STAGING_SEED_PASSWORD
)

MODE=sync
SOURCE_ARG=""

usage() {
    sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --check)
            MODE=check
            shift
            ;;
        --source)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                printf 'sync-preview-env: --source needs a file argument.\n' >&2
                exit 2
            fi
            SOURCE_ARG="$2"
            shift 2
            ;;
        --source=*)
            SOURCE_ARG="${1#--source=}"
            if [ -z "$SOURCE_ARG" ]; then
                printf 'sync-preview-env: --source needs a file argument.\n' >&2
                exit 2
            fi
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'sync-preview-env: unknown argument %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Locate the repository root robustly; CWD is not assumed.
# ---------------------------------------------------------------------------
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ]; then
    script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
    repo_root="$(cd -- "$script_dir/../.." && pwd)"
fi

ROOT_EXAMPLE="$repo_root/.env.example"
DEPLOY_EXAMPLE="$repo_root/infra/deploy/.env.example"
COMPOSE_FILE="$repo_root/infra/deploy/compose.yaml"
ANCHOR_LINE='x-platform-environment: &platform-environment'

# Absolute, symlink-free path so "is the source also a target?" is a string
# comparison and not a guess about how the caller spelled the path.
abspath() {
    local path="$1" dir base
    case "$path" in
        /*) ;;
        *) path="$repo_root/$path" ;;
    esac
    dir="$(dirname -- "$path")"
    base="$(basename -- "$path")"
    if [ -d "$dir" ]; then
        printf '%s/%s\n' "$(cd -- "$dir" && pwd -P)" "$base"
    else
        printf '%s\n' "$path"
    fi
}

if [ -n "$SOURCE_ARG" ]; then
    SOURCE_FILE="$(abspath "$SOURCE_ARG")"
    SOURCE_EXPLICIT=yes
else
    SOURCE_FILE="$repo_root/.env"
    SOURCE_EXPLICIT=no
fi

rel() {
    printf '%s\n' "${1#"$repo_root"/}"
}

if [ ! -f "$SOURCE_FILE" ]; then
    # An ABSENT root `.env` is normal, never a failure: it is gitignored and does
    # not exist on a fresh clone, in CI, or in a container without one. Sync mode
    # therefore exits 0 quietly. Every other combination is a hard failure —
    # a source the caller NAMED, or a check that would otherwise report green
    # over a file it never read, which is green by absence
    # (docs/conventions/orchestration.md rule 4).
    if [ "$MODE" = sync ] && [ "$SOURCE_EXPLICIT" = no ]; then
        exit 0
    fi
    printf 'sync-preview-env: source %s does not exist — nothing was compared.\n' \
        "$(rel "$SOURCE_FILE")" >&2
    exit 1
fi

for f in "$ROOT_EXAMPLE" "$DEPLOY_EXAMPLE" "$COMPOSE_FILE"; do
    if [ ! -f "$f" ]; then
        if [ "$MODE" = check ]; then
            printf 'sync-preview-env: missing target %s — the contract cannot be checked.\n' \
                "$(rel "$f")" >&2
            exit 1
        fi
        printf 'sync-preview-env: missing target %s — skipping.\n' "$(rel "$f")" >&2
        exit 0
    fi
done

is_excluded() {
    local key="$1" excluded
    for excluded in "${EXCLUDED_KEYS[@]}"; do
        [ "$key" = "$excluded" ] && return 0
    done
    return 1
}

is_anchor_exempt() {
    local key="$1" exempt
    for exempt in "${ANCHOR_EXEMPT_KEYS[@]}"; do
        [ "$key" = "$exempt" ] && return 0
    done
    return 1
}

is_preview_only() {
    local key="$1" preview
    for preview in "${PREVIEW_ONLY_KEYS[@]}"; do
        [ "$key" = "$preview" ] && return 0
    done
    return 1
}

# A key whose VALUE must never be copied into a committed file.
is_secret_key() {
    printf '%s' "$1" | grep -Eq '(^|_)(KEY|SECRET|PASSWORD|PASSWD|TOKEN|CREDENTIALS?|PRIVATE)(_|$)'
}

# A value that is correct for DDEV and wrong for any other topology.
is_ddev_local_value() {
    printf '%s' "$1" | grep -Eiq 'ddev'
}

# Values safe to carry as a Compose default: bare scalars only (booleans,
# numbers, locales, driver names). Anything with a scheme, path, space or quote
# stays a plain `${KEY}` so the operator must supply it.
is_simple_scalar() {
    printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_.-]+$'
}

# Presence test — an uncommented OR deliberately commented-out declaration both
# count as "this file already knows about the key". A commented line is a
# recorded decision; re-adding it under it would be noise.
declares_env_key() {
    local file="$1" key="$2"
    grep -Eq "^[[:space:]]*#?[[:space:]]*$key=" "$file"
}

declares_compose_key() {
    awk -v key="$1" -v anchor="$ANCHOR_LINE" '
        index($0, anchor) == 1 { inblock = 1; next }
        inblock && $0 !~ /^[[:space:]]/ { inblock = 0 }
        inblock && $0 ~ "^[[:space:]]*#?[[:space:]]*" key ":" { found = 1 }
        END { exit(found ? 0 : 1) }
    ' "$COMPOSE_FILE"
}

# Every KEY=VALUE declaration in a dotenv file, comments and blanks dropped.
# Commented-out declarations are NOT emitted: they are a decision not to set the
# key, so they must not travel downstream as if they were set.
each_declaration() {
    local file="$1" raw
    while IFS= read -r raw || [ -n "$raw" ]; do
        raw="${raw%$'\r'}"
        case "$raw" in
            ''|'#'*) continue ;;
        esac
        printf '%s' "$raw" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*=' || continue
        printf '%s\n' "$raw"
    done < "$file"
}

append_env_line() {
    local file="$1" line="$2"
    # Guarantee the file ends with a newline before appending.
    if [ -s "$file" ] && [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
        printf '\n' >> "$file"
    fi
    printf '%s\n' "$line" >> "$file"
}

# Insert a line as the last entry of the x-platform-environment anchor block,
# preserving the block's 4-space indentation and append-at-the-end ordering.
insert_compose_line() {
    local line="$1" tmp
    tmp="$(mktemp)"
    awk -v anchor="$ANCHOR_LINE" -v newline="$line" '
        function flush() { if (pending != "") { printf "%s\n", newline; pending = "" } }
        index($0, anchor) == 1 { print; inblock = 1; pending = "yes"; next }
        inblock && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]/ { flush(); inblock = 0 }
        inblock && $0 ~ /^[[:space:]]*$/ { flush(); inblock = 0 }
        { print }
        END { flush() }
    ' "$COMPOSE_FILE" > "$tmp"
    cat "$tmp" > "$COMPOSE_FILE"
    rm -f "$tmp"
}

# The source may itself be one of the targets (`--source .env.example`), in
# which case comparing it against itself is a tautology and writing to it is a
# self-append. Skip it explicitly rather than relying on the diff being empty.
SOURCE_IS_ROOT_EXAMPLE=no
[ "$SOURCE_FILE" = "$ROOT_EXAMPLE" ] && SOURCE_IS_ROOT_EXAMPLE=yes

# ===========================================================================
# CHECK MODE — read-only. FOUR labelled assertions, each reported under its own
# identifier because each has a different cause and a different fix:
#
#   A1  source            -> root `.env.example`   (local runs only; skipped when
#                                                   the source IS that file)
#   A2  source            -> preview contract      (forward propagation)
#   A3  preview contract  -> source                (the reverse; A2 alone is
#                                                   satisfied by a source that
#                                                   LOST a key)
#   B   preview example   -> x-platform-environment (does it reach a container)
# ===========================================================================
if [ "$MODE" = check ]; then
    declaration_count=0
    missing_root=()
    missing_deploy=()
    missing_anchor=()
    missing_upstream=()
    undelivered=()

    # B first: every key the preview env contract declares must appear in the
    # anchor. The anchor is what actually reaches web and queue — a key in the
    # example but not the anchor is silently never delivered, and the operator
    # who set it has no way to tell.
    while IFS= read -r raw; do
        key="${raw%%=*}"

        # A3, the reverse of A2: a key the preview contract declares and the
        # upstream source does not. Skipped for the preview-only set, which is
        # the topology difference rather than drift.
        if ! is_preview_only "$key" && ! declares_env_key "$SOURCE_FILE" "$key"; then
            missing_upstream+=("$key")
        fi

        is_anchor_exempt "$key" && continue
        declares_compose_key "$key" && continue
        undelivered+=("$key")
    done < <(each_declaration "$DEPLOY_EXAMPLE")

    # A1 and A2. Every source key, minus the preview exclusions, must be declared
    # downstream. A2's anchor dimension is reported ONLY for keys the deploy
    # example does not declare either; when it does declare them, B above already
    # owns the anchor gap, and reporting it twice would suggest two defects where
    # there is one. That is what keeps the four labels DISJOINT.
    while IFS= read -r raw; do
        key="${raw%%=*}"
        declaration_count=$((declaration_count + 1))

        if [ "$SOURCE_IS_ROOT_EXAMPLE" = no ] && ! declares_env_key "$ROOT_EXAMPLE" "$key"; then
            missing_root+=("$key")
        fi

        is_excluded "$key" && continue

        in_deploy=yes
        if ! declares_env_key "$DEPLOY_EXAMPLE" "$key"; then
            in_deploy=no
            missing_deploy+=("$key")
        fi
        if [ "$in_deploy" = no ] && ! declares_compose_key "$key"; then
            missing_anchor+=("$key")
        fi
    done < <(each_declaration "$SOURCE_FILE")

    # A source with no declarations would satisfy every assertion above without
    # comparing anything — the purest green by absence, so it is a failure.
    if [ "$declaration_count" -eq 0 ]; then
        printf 'env-contract FAILED: %s declares no keys — the check compared nothing.\n' \
            "$(rel "$SOURCE_FILE")" >&2
        exit 1
    fi

    if [ "${#missing_root[@]}" -eq 0 ] && [ "${#missing_deploy[@]}" -eq 0 ] \
        && [ "${#missing_anchor[@]}" -eq 0 ] && [ "${#missing_upstream[@]}" -eq 0 ] \
        && [ "${#undelivered[@]}" -eq 0 ]; then
        printf 'env-contract: %s key(s) in %s, all propagated.\n' \
            "$declaration_count" "$(rel "$SOURCE_FILE")"
        exit 0
    fi

    printf '\n' >&2
    printf 'env-contract FAILED: the env contract has drifted.\n' >&2

    # Each assertion carries its OWN label. Three of them share the "root template vs the
    # preview contract" question and are numbered A1-A3; B is the separate "does it actually
    # reach a container" question. The footer names only the labels that fired, so whoever
    # reads a red pipeline can tell at a glance which of the four broke.
    fired=()

    if [ "${#missing_root[@]}" -gt 0 ]; then
        fired+=("A1")
        printf '\nA1  TEMPLATE OUT OF STEP — declared in %s, missing from %s:\n' \
            "$(rel "$SOURCE_FILE")" "$(rel "$ROOT_EXAMPLE")" >&2
        printf '      - %s\n' "${missing_root[@]}" >&2
        printf '    CAUSE: the tracked template no longer mirrors the volatile environment it\n' >&2
        printf '           templates. This is the link that makes the CI gate meaningful: the\n' >&2
        printf '           gate can only read the TRACKED file.\n' >&2
        printf '    FIX:   run infra/hooks/sync-preview-env.sh (no --check) and commit.\n' >&2
    fi

    if [ "${#missing_deploy[@]}" -gt 0 ] || [ "${#missing_anchor[@]}" -gt 0 ]; then
        fired+=("A2")
        printf '\nA2  UPSTREAM KEY NOT PROPAGATED — declared in %s, missing downstream:\n' \
            "$(rel "$SOURCE_FILE")" >&2
        if [ "${#missing_deploy[@]}" -gt 0 ]; then
            printf '    %s\n' "$(rel "$DEPLOY_EXAMPLE")" >&2
            printf '      - %s\n' "${missing_deploy[@]}" >&2
        fi
        if [ "${#missing_anchor[@]}" -gt 0 ]; then
            printf '    %s (x-platform-environment)\n' "$(rel "$COMPOSE_FILE")" >&2
            printf '      - %s\n' "${missing_anchor[@]}" >&2
        fi
        printf '    CAUSE: a commit that added the key upstream without running the hook\n' >&2
        # shellcheck disable=SC2016  # literal advice text; nothing here is meant to expand.
        printf '           (`--no-verify`, or a clone where `captainhook install` never ran).\n' >&2
        printf '    FIX:   run infra/hooks/sync-preview-env.sh (no --check) and commit the\n' >&2
        printf '           result — or, if the key must NEVER reach the preview topology, add\n' >&2
        printf '           it to EXCLUDED_KEYS in that script with a reason.\n' >&2
    fi

    if [ "${#missing_upstream[@]}" -gt 0 ]; then
        fired+=("A3")
        printf '\nA3  DOWNSTREAM KEY MISSING UPSTREAM — declared in %s, absent from %s:\n' \
            "$(rel "$DEPLOY_EXAMPLE")" "$(rel "$SOURCE_FILE")" >&2
        printf '      - %s\n' "${missing_upstream[@]}" >&2
        printf '    CAUSE: the upstream template lost a key, or gained it only downstream.\n' >&2
        printf '           A2 cannot see this: a smaller source always\n' >&2
        printf '           fits inside a larger downstream, so it would report green.\n' >&2
        printf '    FIX:   declare the key in %s — or, if the\n' "$(rel "$SOURCE_FILE")" >&2
        printf '           preview topology alone needs it, add it to PREVIEW_ONLY_KEYS in\n' >&2
        printf '           infra/hooks/sync-preview-env.sh naming what supplies it locally.\n' >&2
    fi

    if [ "${#undelivered[@]}" -gt 0 ]; then
        fired+=("B")
        printf '\nB   DECLARED BUT NEVER DELIVERED — in %s, absent from x-platform-environment:\n' \
            "$(rel "$DEPLOY_EXAMPLE")" >&2
        printf '      - %s\n' "${undelivered[@]}" >&2
        printf '    CAUSE: the anchor is what reaches the web and queue containers. A key\n' >&2
        printf '           only in the example reads as configured and is silently dropped;\n' >&2
        printf '           the operator who set it gets no signal at all.\n' >&2
        # shellcheck disable=SC2016  # `${KEY}` is the literal Compose syntax to type, not an expansion.
        printf '    FIX:   add `KEY: ${KEY}` to the x-platform-environment anchor in\n' >&2
        printf '           %s — or, if the key has a\n' "$(rel "$COMPOSE_FILE")" >&2
        printf '           non-container consumer (Compose itself, infra/deploy/up.sh), add\n' >&2
        printf '           it to ANCHOR_EXEMPT_KEYS naming that consumer.\n' >&2
    fi

    printf '\nFailed assertion(s): %s. Nothing was modified: --check is read-only.\n' \
        "$(printf '%s ' "${fired[@]}" | sed 's/ $//')" >&2
    exit 1
fi

# ===========================================================================
# SYNC MODE — additive propagation into the three targets, then stage them.
# ===========================================================================
added_root=()
added_env=()
added_compose=()

while IFS= read -r raw; do
    key="${raw%%=*}"
    value="${raw#*=}"

    redacted=no
    if is_secret_key "$key" || is_ddev_local_value "$value"; then
        redacted=yes
    fi

    # Root `.env.example` is the DDEV template and mirrors root `.env` IN FULL —
    # EXCLUDED_KEYS is a preview-topology filter and does not apply here.
    if [ "$SOURCE_IS_ROOT_EXAMPLE" = no ] && ! declares_env_key "$ROOT_EXAMPLE" "$key"; then
        if [ "$redacted" = yes ]; then
            append_env_line "$ROOT_EXAMPLE" "$key="
            added_root+=("$key (value withheld — secret or DDEV-local)")
        else
            append_env_line "$ROOT_EXAMPLE" "$key=$value"
            added_root+=("$key")
        fi
    fi

    is_excluded "$key" && continue

    if ! declares_env_key "$DEPLOY_EXAMPLE" "$key"; then
        if [ "$redacted" = yes ]; then
            append_env_line "$DEPLOY_EXAMPLE" "$key="
            added_env+=("$key (value withheld — secret or DDEV-local)")
        else
            append_env_line "$DEPLOY_EXAMPLE" "$key=$value"
            added_env+=("$key")
        fi
    fi

    if ! declares_compose_key "$key"; then
        if [ "$redacted" = yes ]; then
            insert_compose_line "    $key: \${$key:-}"
        elif is_simple_scalar "$value"; then
            insert_compose_line "    $key: \${$key:-$value}"
        else
            insert_compose_line "    $key: \${$key}"
        fi
        added_compose+=("$key")
    fi
done < <(each_declaration "$SOURCE_FILE")

# Nothing new — stay silent.
if [ "${#added_root[@]}" -eq 0 ] && [ "${#added_env[@]}" -eq 0 ] \
    && [ "${#added_compose[@]}" -eq 0 ]; then
    exit 0
fi

printf 'sync-preview-env: propagated new %s keys into the env contract.\n' \
    "$(rel "$SOURCE_FILE")"
if [ "${#added_root[@]}" -gt 0 ]; then
    printf '  %s:\n' "$(rel "$ROOT_EXAMPLE")"
    printf '    + %s\n' "${added_root[@]}"
fi
if [ "${#added_env[@]}" -gt 0 ]; then
    printf '  %s:\n' "$(rel "$DEPLOY_EXAMPLE")"
    printf '    + %s\n' "${added_env[@]}"
fi
if [ "${#added_compose[@]}" -gt 0 ]; then
    printf '  %s (x-platform-environment):\n' "$(rel "$COMPOSE_FILE")"
    printf '    + %s\n' "${added_compose[@]}"
fi
printf '  Review the added lines before completing the commit.\n'
printf '  A key that must NOT reach the preview topology belongs in EXCLUDED_KEYS\n'
printf '  in infra/hooks/sync-preview-env.sh — revert the lines and add it there.\n'

if git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$repo_root" add -- "$ROOT_EXAMPLE" "$DEPLOY_EXAMPLE" "$COMPOSE_FILE" \
        || printf 'sync-preview-env: could not stage the updated files; stage them manually.\n' >&2
fi

exit 0
