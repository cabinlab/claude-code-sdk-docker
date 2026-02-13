#!/bin/bash
# test-variants.sh - Build and validate all Docker image variants
#
# Usage: scripts/test-variants.sh [OPTIONS] [VARIANT...]
#   VARIANT: typescript, python, alpine, alpine-python (default: all)
#   --no-cleanup    Keep test images after run
#   --no-build      Skip build phase (test pre-existing images)
#   --help          Show usage

set -euo pipefail

# --- Configuration ---
IMAGE_PREFIX="test-claude-sdk"
ALL_VARIANTS=(typescript alpine python alpine-python)
CLEANUP=true
BUILD=true
VARIANTS=()
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
RESULTS=()

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helpers ---
usage() {
    sed -n '2,8p' "$0" | sed 's/^# \?//'
    exit 0
}

log()  { echo -e "${BLUE}[INFO]${RESET} $*"; }
pass() { echo -e "  ${GREEN}PASS${RESET} $*"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo -e "  ${RED}FAIL${RESET} $*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${RESET} $*"; SKIP_COUNT=$((SKIP_COUNT + 1)); }

# Run a command inside a test container; sets $OUT and returns the exit code
run_in() {
    local tag="$1"; shift
    OUT=$(docker run --rm "${IMAGE_PREFIX}:${tag}" "$@" 2>&1) && return 0 || return $?
}

# Run a command in a named (non-rm) container; sets $OUT
exec_in() {
    local name="$1"; shift
    OUT=$(docker exec "$name" "$@" 2>&1) && return 0 || return $?
}

has_python() {
    [[ "$1" == "python" || "$1" == "alpine-python" ]]
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-cleanup) CLEANUP=false; shift ;;
        --no-build)   BUILD=false;   shift ;;
        --help|-h)    usage ;;
        *)
            if printf '%s\n' "${ALL_VARIANTS[@]}" | grep -qx "$1"; then
                VARIANTS+=("$1")
            else
                echo "Unknown variant: $1" >&2; usage
            fi
            shift ;;
    esac
done
[[ ${#VARIANTS[@]} -eq 0 ]] && VARIANTS=("${ALL_VARIANTS[@]}")

# --- Locate repo root (script may be invoked from anywhere) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  Claude SDK Docker - Variant Tests${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo "  Variants: ${VARIANTS[*]}"
echo "  Build:    $BUILD"
echo "  Cleanup:  $CLEANUP"
echo ""

# =====================================================================
# BUILD PHASE
# =====================================================================
if $BUILD; then
    log "Building images..."

    # Base images first (independent of each other)
    for base in typescript alpine; do
        if printf '%s\n' "${VARIANTS[@]}" | grep -qE "^${base}$|^python$|^alpine-python$"; then
            # typescript is needed by python; alpine is needed by alpine-python
            need=false
            case "$base" in
                typescript) printf '%s\n' "${VARIANTS[@]}" | grep -qE "^typescript$|^python$" && need=true ;;
                alpine)     printf '%s\n' "${VARIANTS[@]}" | grep -qE "^alpine$|^alpine-python$" && need=true ;;
            esac
            if $need; then
                case "$base" in
                    typescript) df="Dockerfile.typescript" ;;
                    alpine)     df="Dockerfile.alpine" ;;
                esac
                log "  Building ${IMAGE_PREFIX}:${base} from ${df}..."
                if docker build -f "$df" -t "${IMAGE_PREFIX}:${base}" . > /dev/null 2>&1; then
                    pass "Build ${base}"
                else
                    fail "Build ${base}"
                    echo "    Build failed — run manually to see errors:"
                    echo "    docker build -f $df -t ${IMAGE_PREFIX}:${base} ."
                fi
            fi
        fi
    done

    # Extension images (depend on bases)
    if printf '%s\n' "${VARIANTS[@]}" | grep -qx "python"; then
        log "  Building ${IMAGE_PREFIX}:python from Dockerfile..."
        if docker build -f Dockerfile \
            --build-arg BASE_IMAGE="${IMAGE_PREFIX}:typescript" \
            -t "${IMAGE_PREFIX}:python" . > /dev/null 2>&1; then
            pass "Build python"
        else
            fail "Build python"
        fi
    fi

    if printf '%s\n' "${VARIANTS[@]}" | grep -qx "alpine-python"; then
        log "  Building ${IMAGE_PREFIX}:alpine-python from Dockerfile.alpine-python..."
        if docker build -f Dockerfile.alpine-python \
            --build-arg BASE_IMAGE="${IMAGE_PREFIX}:alpine" \
            -t "${IMAGE_PREFIX}:alpine-python" . > /dev/null 2>&1; then
            pass "Build alpine-python"
        else
            fail "Build alpine-python"
        fi
    fi

    echo ""
fi

# =====================================================================
# VALIDATION PHASE
# =====================================================================
for VARIANT in "${VARIANTS[@]}"; do
    echo -e "${BOLD}--- Validating: ${VARIANT} ---${RESET}"

    IMAGE="${IMAGE_PREFIX}:${VARIANT}"

    # Verify image exists
    if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
        fail "Image ${IMAGE} not found (was it built?)"
        RESULTS+=("${VARIANT}: SKIPPED (no image)")
        continue
    fi

    # Report image size
    SIZE=$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
    SIZE_MB=$(( SIZE / 1024 / 1024 ))
    log "  Image size: ${SIZE_MB} MB"

    # --- Entrypoint & user checks (need a running container) ---
    CNAME="${IMAGE_PREFIX}-${VARIANT}-test"
    docker rm -f "$CNAME" > /dev/null 2>&1 || true
    docker run -d --name "$CNAME" "$IMAGE" sleep 120 > /dev/null 2>&1

    # Check entrypoint ran
    sleep 1
    LOGS=$(docker logs "$CNAME" 2>&1)
    if echo "$LOGS" | grep -q "Starting Claude Agent SDK container"; then
        pass "Entrypoint executes"
    else
        fail "Entrypoint did not print startup message"
    fi

    # Check running as claude user
    if exec_in "$CNAME" whoami && [[ "$OUT" == "claude" ]]; then
        pass "Runs as claude user"
    else
        fail "Not running as claude user (got: ${OUT:-unknown})"
    fi

    # --- Tool availability ---
    if exec_in "$CNAME" claude --version; then
        pass "claude CLI: $OUT"
    else
        fail "claude CLI not available"
    fi

    if exec_in "$CNAME" node --version; then
        pass "node: $OUT"
    else
        fail "node not available"
    fi

    if exec_in "$CNAME" tsx --version; then
        pass "tsx: $OUT"
    else
        fail "tsx not available"
    fi

    if exec_in "$CNAME" git --version; then
        pass "git: $OUT"
    else
        fail "git not available"
    fi

    # --- JS SDK import ---
    if exec_in "$CNAME" node -e "require('@anthropic-ai/claude-agent-sdk'); console.log('ok')"; then
        pass "JS SDK loads"
    else
        fail "JS SDK import failed: $OUT"
    fi

    # --- HTTPS connectivity ---
    if exec_in "$CNAME" sh -c "curl -sf --max-time 10 https://api.github.com/zen > /dev/null 2>&1"; then
        pass "HTTPS connectivity"
    elif exec_in "$CNAME" sh -c "node -e \"fetch('https://api.github.com/zen').then(r=>{process.exit(r.ok?0:1)})\""; then
        pass "HTTPS connectivity (via node fetch)"
    else
        fail "HTTPS connectivity"
    fi

    # --- Filesystem checks ---
    if exec_in "$CNAME" ls /app/examples/; then
        pass "Examples directory present"
    else
        fail "Examples directory missing"
    fi

    if exec_in "$CNAME" ls /home/claude/.claude/; then
        pass ".claude config directory present"
    else
        fail ".claude config directory missing"
    fi

    # --- Python checks (variant-specific) ---
    if has_python "$VARIANT"; then
        if exec_in "$CNAME" python3 --version; then
            pass "python3: $OUT"
        else
            fail "python3 not available"
        fi

        if exec_in "$CNAME" python3 -c "import claude_agent_sdk; print('ok')"; then
            pass "Python SDK loads"
        else
            fail "Python SDK import failed: $OUT"
        fi
    fi

    docker rm -f "$CNAME" > /dev/null 2>&1

    # --- OAuth token injection test ---
    CNAME_AUTH="${IMAGE_PREFIX}-${VARIANT}-auth"
    docker rm -f "$CNAME_AUTH" > /dev/null 2>&1 || true
    docker run -d --name "$CNAME_AUTH" \
        -e CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-TESTTOKEN123" \
        "$IMAGE" sleep 60 > /dev/null 2>&1
    sleep 2

    AUTH_LOGS=$(docker logs "$CNAME_AUTH" 2>&1)
    if echo "$AUTH_LOGS" | grep -q "OAuth authentication setup complete"; then
        pass "OAuth entrypoint setup"
    else
        fail "OAuth entrypoint did not complete"
    fi

    if exec_in "$CNAME_AUTH" cat /home/claude/.claude/.credentials.json \
       && echo "$OUT" | grep -q "sk-ant-oat01-TESTTOKEN123"; then
        pass "Credentials file written with token"
    else
        fail "Credentials file missing or token not injected"
    fi

    if exec_in "$CNAME_AUTH" cat /home/claude/.claude.json \
       && echo "$OUT" | grep -q "hasCompletedOnboarding"; then
        pass "Session config (.claude.json) created"
    else
        fail "Session config missing"
    fi

    # Check permissions on credentials file
    if exec_in "$CNAME_AUTH" stat -c '%a' /home/claude/.claude/.credentials.json 2>/dev/null \
       && [[ "$OUT" == "600" ]]; then
        pass "Credentials file permissions (600)"
    elif exec_in "$CNAME_AUTH" sh -c "ls -la /home/claude/.claude/.credentials.json | grep -q 'rw-------'"; then
        pass "Credentials file permissions (600)"
    else
        fail "Credentials file permissions incorrect (got: ${OUT:-unknown})"
    fi

    docker rm -f "$CNAME_AUTH" > /dev/null 2>&1

    V_PASS=$PASS_COUNT
    V_FAIL=$FAIL_COUNT
    RESULTS+=("${VARIANT}: done")
    echo ""
done

# =====================================================================
# CLEANUP PHASE
# =====================================================================
if $CLEANUP; then
    log "Cleaning up test images..."
    for v in "${ALL_VARIANTS[@]}"; do
        docker rmi "${IMAGE_PREFIX}:${v}" > /dev/null 2>&1 || true
    done
    log "Cleanup complete"
else
    log "Skipping cleanup (--no-cleanup). Remove manually:"
    log "  docker rmi ${IMAGE_PREFIX}:{typescript,alpine,python,alpine-python}"
fi

# =====================================================================
# SUMMARY
# =====================================================================
echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  SUMMARY${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${RESET}"
echo -e "  ${RED}Failed: ${FAIL_COUNT}${RESET}"
echo -e "  ${YELLOW}Skipped: ${SKIP_COUNT}${RESET}"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}RESULT: FAIL${RESET}"
    exit 1
else
    echo -e "  ${GREEN}${BOLD}RESULT: PASS${RESET}"
    exit 0
fi
