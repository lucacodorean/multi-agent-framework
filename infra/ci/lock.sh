#!/usr/bin/env bash
# One run of a gate at a time on a machine. SOURCED, never executed.
#
#   source "<repo>/infra/ci/lock.sh"
#   ci_take_gate_lock seam        # …then, and only then, define cleanup and trap it
#
# Owned by platform-engineer. Used by the three gates that own long-lived Docker resources:
#   infra/ci/engine-suite.sh     (2 containers, 1 network)
#   infra/ci/platform-suite.sh   (2 containers, 1 network)
#   infra/ci/seam-suite.sh       (4 containers, 1 network)
#
# infra/ci/contract-lint.sh deliberately does NOT use this — it owns no shared resource. Its
# containers are synchronous `docker run --rm` and its report directory is `mktemp -d`, unique
# per run. Two concurrent contract lints cannot touch each other, so serializing them would
# only make a five-second gate wait. That is recorded in the file itself rather than left for
# someone to re-derive from its absence here.
#
# ---------------------------------------------------------------------------------------
# WHY, and it is not the reason people assume: the container and network names are
# CONSTANTS, so two concurrent runs are destructive rather than merely racy, and the lock
# serializes a file rather than a copy. Recorded in infra/README.md § Isolation, together
# with the rule that the lock is taken BEFORE `cleanup` and its `trap` are defined.
# ---------------------------------------------------------------------------------------

# Acquire the exclusive lock for one gate, waiting if another run holds it.
#
#   ci_take_gate_lock <gate-name>
#
# CALL THIS BEFORE DEFINING `cleanup` AND BEFORE `trap cleanup EXIT`. A process still WAITING
# on the lock owns no containers, so if it carried the trap and were interrupted its cleanup
# would delete the containers of the run it is queueing behind.
#
# File descriptor 9 is opened on the lock file and deliberately never closed — the kernel
# releases the lock however the process exits, including SIGKILL, where a trap-released lock
# would leak on exactly the abnormal exits it most needs to survive.
ci_take_gate_lock() {
  local gate="$1"
  local lock_file="/tmp/oir-flow-ci-${gate}-suite.lock"

  exec 9>"${lock_file}"

  if ! flock --nonblock 9; then
    echo "==> another ${gate} gate run holds ${lock_file} — waiting for it (container names are shared)"
    flock 9
    echo "==> lock acquired; the previous ${gate} run has finished"
  fi
}
