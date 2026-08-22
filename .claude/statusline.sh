#!/usr/bin/env bash
#
# Claude Code statusline — inspired by status-liner-demo.sh.
#
# Reads the statusline JSON on stdin and prints a 4-line, width-responsive block:
#   line 1  ✳ <model> [1M]  <dir>/  ⎇ <branch>  <style>  <sub> <tier>  $cost  +adds -dels
#   line 2  Context    bar  + token counts
#   line 3  5h/12h     bar  + reset countdown + exhaustion forecast
#   line 4  7d Limit   bar  + reset countdown + exhaustion forecast
#
# JSON is parsed with python3 (jq is not installed on this host; python3 is, and is
# already used for JSON parsing elsewhere in this workspace). No other dependencies
# beyond coreutils (tput/seq/awk/date) and git.

input=$(cat)

# --- Pick a JSON parser (python3 preferred, python fallback) ---
PY=""
command -v python3 >/dev/null 2>&1 && PY=python3
[ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY=python
if [ -z "$PY" ]; then
  printf 'Claude Code — statusline needs python3 (or jq)\n'
  exit 0
fi

# --- Terminal width (override with COLUMNS when there is no tty; default 120) ---
cols=$(tput cols 2>/dev/null)
case "$cols" in ''|*[!0-9]*) cols=${COLUMNS:-120} ;; esac

# --- Palette ---
OR='\033[38;5;208m'   # orange (Claude mark)
CY='\033[0;36m'       # cyan
GR='\033[0;32m'       # green
YL='\033[0;33m'       # yellow
RD='\033[0;31m'       # red
MG='\033[0;35m'       # magenta
BL='\033[0;34m'       # blue
DM='\033[0;90m'       # dim/gray
BD='\033[1m'          # bold
RS='\033[0m'          # reset

# Progress bar: filled ▪ + empty ▫, exactly w chars, green→yellow→red by load.
bar() {
  local pct=${1:-0} w=${2:-25} i
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  local f=$(( pct * w / 100 ))
  local c="$GR"
  [ "$pct" -ge 50 ] && c="$YL"
  [ "$pct" -ge 80 ] && c="$RD"
  printf "%b" "$c"
  for (( i=0; i<f; i++ )); do printf '▪'; done
  printf "%b" "$DM"
  for (( i=f; i<w; i++ )); do printf '▫'; done
  printf "%b" "$RS"
}

# Format a token count as "1.2k" (drop a trailing .0).
fk() { awk "BEGIN {printf \"%.1f\", ${1:-0}/1000}" | sed 's/\.0$//'; }

# Human countdown from an epoch-seconds timestamp to now.
countdown() {
  local t=${1:-0} now
  now=$(date +%s)
  [ "$t" -le 0 ] 2>/dev/null && { echo "-"; return; }
  local d=$(( t - now ))
  [ "$d" -le 0 ] && { echo "now"; return; }
  local days=$(( d / 86400 )) hrs=$(( (d % 86400) / 3600 )) mins=$(( (d % 3600) / 60 ))
  if   [ "$days" -gt 0 ]; then echo "${days}d ${hrs}h"
  elif [ "$hrs"  -gt 0 ]; then echo "${hrs}h ${mins}m"
  else echo "${mins}m"
  fi
}

# Render the exhaustion forecast for a window: an ETA epoch projected from the
# current burn rate vs. the window's reset epoch.
#   eta <= 0          → no usage yet / nothing to extrapolate → blank
#   eta >= reset      → you'd reset before running out → green "on track"
#   eta <  reset      → you'd run out first → red "↯ exhausts ~<countdown>"
# mode "short" emits a terse token for the narrow (compact) layout.
forecast_str() {
  local eta=${1:-0} reset=${2:-0} mode=${3:-full}
  [ "$eta" -le 0 ] 2>/dev/null && return
  if [ "$reset" -gt 0 ] && [ "$eta" -ge "$reset" ]; then
    if [ "$mode" = short ]; then printf "  ${GR}✓${RS}"
    else printf "  ${GR}↗ on track${RS}"; fi
  else
    local cd; cd=$(countdown "$eta")
    if [ "$mode" = short ]; then printf "  ${RD}↯%s${RS}" "$cd"
    else printf "  ${RD}↯ exhausts ~%s${RS}" "$cd"; fi
  fi
}

# --- Extract every field in one python pass (robust to missing/null/ISO values) ---
read -r -d '' PROG <<'PYEOF'
import json, sys, os, datetime

try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

def g(d, *path, default=None):
    cur = d
    for k in path:
        if isinstance(cur, dict) and cur.get(k) is not None:
            cur = cur[k]
        else:
            return default
    return cur

def num(x, d=0):
    try:
        return float(x)
    except Exception:
        return d

def to_epoch(v):
    if isinstance(v, (int, float)):
        return int(v)
    if isinstance(v, str) and v.strip():
        s = v.strip()
        try:
            return int(float(s))
        except Exception:
            pass
        try:
            return int(datetime.datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp())
        except Exception:
            return 0
    return 0

model_id   = g(data, 'model', 'id', default='') or ''
model_name = g(data, 'model', 'display_name', default='?') or '?'
cwd        = g(data, 'workspace', 'current_dir') or g(data, 'cwd', default='') or ''
style      = g(data, 'output_style', 'name', default='default') or 'default'
cost       = num(g(data, 'cost', 'total_cost_usd', default=0))
adds       = int(num(g(data, 'cost', 'total_lines_added', default=0)))
dels       = int(num(g(data, 'cost', 'total_lines_removed', default=0)))

ctx_size = int(num(g(data, 'context_window', 'context_window_size', default=0)))
cr = int(num(g(data, 'context_window', 'current_usage', 'cache_read_input_tokens', default=0)))
cc = int(num(g(data, 'context_window', 'current_usage', 'cache_creation_input_tokens', default=0)))
it = int(num(g(data, 'context_window', 'current_usage', 'input_tokens', default=0)))
used   = cr + cc + it
remain = max(ctx_size - used, 0)
pct    = (used * 100 // ctx_size) if ctx_size > 0 else 0

five_raw   = num(g(data, 'rate_limits', 'five_hour', 'used_percentage', default=0))
five_pct   = round(five_raw)
five_reset = to_epoch(g(data, 'rate_limits', 'five_hour', 'resets_at', default=0))
week_raw   = num(g(data, 'rate_limits', 'seven_day', 'used_percentage', default=0))
week_pct   = round(week_raw)
week_reset = to_epoch(g(data, 'rate_limits', 'seven_day', 'resets_at', default=0))

# --- Exhaustion forecast (burst-aware) ---
# A single statusline render only sees a snapshot (used%, resets_at) — too little to
# tell a recent burst from steady use. So we persist a small (t, used%) time-series per
# window across renders and derive the burn rate from a RECENT sliding window via
# least-squares regression. An active burst steepens the recent slope → a sooner ETA;
# going idle ages the burst out of the horizon → the rate relaxes back to the long-run
# average since the window opened. Run-out epoch is now + (100-used%)/rate.
#
# State lives in ~/.claude/.statusline-usage.json (account-wide; rate limits are not
# per-session, so all sessions safely share and enrich the same series). Every IO step
# is best-effort — any failure silently degrades to the window-open average.
now_epoch = int(datetime.datetime.now().timestamp())
home = os.environ.get('HOME') or os.path.expanduser('~')
STATE_PATH = os.path.join(home, '.claude', '.statusline-usage.json')

# Per-window recent-horizon for burst detection and a hard cap on retained samples.
HORIZON = {'five': 30 * 60, 'week': 6 * 3600}
MAX_SAMPLES = 240

def _slope(pts):
    # Least-squares slope of used% over time (percent/second); 0 if degenerate.
    n = len(pts)
    mt = sum(p[0] for p in pts) / n
    mu = sum(p[1] for p in pts) / n
    den = sum((p[0] - mt) ** 2 for p in pts)
    if den <= 0:
        return 0.0
    return sum((p[0] - mt) * (p[1] - mu) for p in pts) / den

def burn_rate(state, key, used, reset_epoch, window_secs):
    # Update the persisted series for this window and return a burst-aware rate (%/s).
    w = state.get(key) if isinstance(state.get(key), dict) else {}
    samples = w.get('samples') if isinstance(w.get('samples'), list) else []
    # New window (reset rolled over) or a drop in used% (fresh window) → start clean.
    if w.get('reset') != reset_epoch or (samples and used + 0.05 < samples[-1][1]):
        samples = []
    if not samples or samples[-1][0] != now_epoch:
        samples.append([now_epoch, used])
    # Keep only this window's samples, newest MAX_SAMPLES.
    open_t = reset_epoch - window_secs
    samples = [s for s in samples if s[0] >= open_t][-MAX_SAMPLES:]
    state[key] = {'reset': reset_epoch, 'samples': samples}

    # Recent slope when we have ≥2 samples spanning ≥60s; else fall back to the
    # average since the window opened (the old behaviour).
    horizon = HORIZON.get(key, 30 * 60)
    recent = [s for s in samples if s[0] >= now_epoch - horizon]
    rate = 0.0
    if len(recent) >= 2 and (recent[-1][0] - recent[0][0]) >= 60:
        rate = _slope(recent)
    if rate <= 0:
        elapsed = now_epoch - open_t
        rate = (used / elapsed) if (elapsed > 0 and used > 0) else 0.0
    return max(rate, 0.0)

def forecast(used, reset_epoch, rate):
    if reset_epoch <= 0 or used <= 0:
        return 0
    if used >= 100:
        return now_epoch
    if rate <= 0:
        return 0
    return int(now_epoch + (100 - used) / rate)

state = {}
try:
    with open(STATE_PATH) as f:
        loaded = json.load(f)
        if isinstance(loaded, dict):
            state = loaded
except Exception:
    pass

five_rate = burn_rate(state, 'five', five_raw, five_reset, 5 * 3600)
week_rate = burn_rate(state, 'week', week_raw, week_reset, 7 * 86400)
five_eta = forecast(five_raw, five_reset, five_rate)
week_eta = forecast(week_raw, week_reset, week_rate)

try:
    tmp = STATE_PATH + '.tmp'
    with open(tmp, 'w') as f:
        json.dump(state, f)
    os.replace(tmp, STATE_PATH)
except Exception:
    pass

sub_type = rate_tier = ''
try:
    home = os.environ.get('HOME') or os.path.expanduser('~')
    with open(os.path.join(home, '.claude', '.credentials.json')) as f:
        oauth = (json.load(f).get('claudeAiOauth') or {})
    sub_type  = oauth.get('subscriptionType') or ''
    rate_tier = oauth.get('rateLimitTier') or ''
except Exception:
    pass

# --- "Total tokens" exactly as the /usage dialog reports it ---
# /usage's "Total tokens" = sum of inputTokens + outputTokens over modelUsage
# (every model, all-time; cache read/creation deliberately excluded). It reads
# ~/.claude/stats-cache.json, which Claude Code refreshes (e.g. on opening /usage),
# so we read the same file and show the same number — cheap (one small JSON), no
# transcript scanning. Formatted like Gc(): en-US compact, 1 decimal, lowercase
# suffix (e.g. 69.6m). Best-effort: blank on any failure.
tok_total_str = ''
try:
    with open(os.path.join(home, '.claude', 'stats-cache.json')) as f:
        mu = (json.load(f).get('modelUsage') or {})
    total = 0
    for m in mu.values():
        if isinstance(m, dict):
            total += int(num(m.get('inputTokens'))) + int(num(m.get('outputTokens')))
    if total >= 1e9:
        tok_total_str = f"{total/1e9:.1f}b"
    elif total >= 1e6:
        tok_total_str = f"{total/1e6:.1f}m"
    elif total >= 1e3:
        tok_total_str = f"{total/1e3:.1f}k"
    else:
        tok_total_str = str(int(total))
except Exception:
    tok_total_str = ''

# One value per line, every value newline-terminated → mapfile yields exactly 20.
vals = [model_id, model_name, cwd, style, f"{cost:.4f}", adds, dels,
        ctx_size, used, pct, remain, five_pct, five_reset, week_pct, week_reset,
        sub_type, rate_tier, five_eta, week_eta, tok_total_str]
sys.stdout.write("".join(f"{v}\n" for v in vals))
PYEOF

mapfile -t F < <(printf '%s' "$input" | "$PY" -c "$PROG" 2>/dev/null)

if [ "${#F[@]}" -lt 20 ]; then
  printf 'Claude Code — statusline parse error\n'
  exit 0
fi

model_id=${F[0]};  model_name=${F[1]}; cwd=${F[2]};      style=${F[3]}
cost=${F[4]};      adds=${F[5]};       dels=${F[6]}
ctx_size=${F[7]};  used=${F[8]};       pct=${F[9]};      remain=${F[10]}
five_pct=${F[11]}; five_reset=${F[12]}; week_pct=${F[13]}; week_reset=${F[14]}
sub_type=${F[15]}; rate_tier=${F[16]}; five_eta=${F[17]}; week_eta=${F[18]}
tok_total=${F[19]}

# --- Model display name (current lineup) + 1M-context badge ---
case "$model_id" in
  *fable-5*|*fable5*)        mdl="Fable 5" ;;
  *opus-4-8*|*opus-4.8*)     mdl="Opus 4.8" ;;
  *opus-4-7*|*opus-4.7*)     mdl="Opus 4.7" ;;
  *opus-4-6*|*opus-4.6*)     mdl="Opus 4.6" ;;
  *sonnet-4-6*|*sonnet-4.6*) mdl="Sonnet 4.6" ;;
  *sonnet-4-5*|*sonnet-4.5*) mdl="Sonnet 4.5" ;;
  *haiku-4-5*|*haiku-4.5*)   mdl="Haiku 4.5" ;;
  *)                          mdl="$model_name" ;;
esac
onem=""
[[ "$model_id" == *"[1m]"* ]] && onem="  ${DM}1M${RS}"

# --- Window label: the second bar reads rate_limits.five_hour, so label it truthfully. ---
period_label="5h Limit"

# --- Git branch ---
branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Derived display strings ---
dir=""; [ -n "$cwd" ] && dir=$(basename "$cwd")
used_k=$(fk "$used"); ctx_k=$(fk "$ctx_size"); remain_k=$(fk "$remain")
five_cd=$(countdown "$five_reset"); week_cd=$(countdown "$week_reset")

dir_str="";   [ -n "$dir" ]    && dir_str="  ${BL}${dir}/${RS}"
br_str="";    [ -n "$branch" ] && br_str="  ${GR}⎇ ${branch}${RS}"
style_str=""; [ "$style" != "default" ] && [ -n "$style" ] && style_str="  ${YL}${BD}${style}${RS}"
acct_str=""
[ -n "$sub_type" ] && acct_str="  ${DM}${sub_type}${RS}"
mult=""; [[ "$rate_tier" =~ ([0-9]+x)$ ]] && mult="${BASH_REMATCH[1]}"
[ -n "$mult" ] && acct_str="${acct_str} ${DM}${mult}${RS}"

# Session cost — shown when present and the terminal is wide enough.
cost_str=""
if [ "$cols" -ge 80 ]; then
  cost_show=$(awk "BEGIN {c=${cost:-0}; if (c > 0) printf \"\$%.2f\", c}")
  [ -n "$cost_show" ] && cost_str="  ${DM}${cost_show}${RS}"
fi
# Lines added/removed this session — only on wider terminals.
churn_str=""
if [ "$cols" -ge 100 ] && { [ "${adds:-0}" -gt 0 ] || [ "${dels:-0}" -gt 0 ]; }; then
  churn_str="  ${GR}+${adds}${RS} ${RD}-${dels}${RS}"
fi

# --- Line 1: configuration ---
printf "${OR}✳${RS} ${CY}${BD}%s${RS}" "$mdl"
printf "%b" "$onem"
printf "%b" "$dir_str"
printf "%b" "$br_str"
printf "%b" "$style_str"
printf "%b" "$acct_str"
printf "%b" "$cost_str"
printf "%b" "$churn_str"
printf "\n"

# --- Separator ---
sep=$(( cols < 60 ? cols : 60 ))
printf "${DM}%.0s─" $(seq 1 "$sep")
printf "${RS}\n"

# --- Lines 2-4: usage bars (width-responsive) ---
label1="Context"; label2="$period_label"; label3="7d Limit"
pad=10
pad1=$(( pad - ${#label1} )); [ "$pad1" -lt 1 ] && pad1=1
pad2=$(( pad - ${#label2} )); [ "$pad2" -lt 1 ] && pad2=1
pad3=$(( pad - ${#label3} )); [ "$pad3" -lt 1 ] && pad3=1

if [ "$cols" -lt 80 ]; then
  # COMPACT — tiny bars, minimal detail
  bw=10
  printf "${CY}%s${RS}%*s%3s%%  " "$label1" "$pad1" "" "$pct";      bar "$pct" "$bw";      printf "\n"
  printf "${MG}%s${RS}%*s%3s%%  " "$label2" "$pad2" "" "$five_pct"; bar "$five_pct" "$bw"; printf "  ${DM}%s${RS}" "$five_cd"; forecast_str "$five_eta" "$five_reset" short; printf "\n"
  printf "${BL}%s${RS}%*s%3s%%  " "$label3" "$pad3" "" "$week_pct"; bar "$week_pct" "$bw"; printf "  ${DM}%s${RS}" "$week_cd"; forecast_str "$week_eta" "$week_reset" short
elif [ "$cols" -lt 140 ]; then
  # STANDARD — medium bars, token counts
  bw=$(( cols - 55 )); [ "$bw" -lt 15 ] && bw=15; [ "$bw" -gt 25 ] && bw=25
  printf "${CY}%s${RS}%*s%3s%%  " "$label1" "$pad1" "" "$pct";      bar "$pct" "$bw";      printf "   %sk/%sk\n" "$used_k" "$ctx_k"
  printf "${MG}%s${RS}%*s%3s%%  " "$label2" "$pad2" "" "$five_pct"; bar "$five_pct" "$bw"; printf "   ${DM}resets %s${RS}" "$five_cd"; forecast_str "$five_eta" "$five_reset"; printf "\n"
  printf "${BL}%s${RS}%*s%3s%%  " "$label3" "$pad3" "" "$week_pct"; bar "$week_pct" "$bw"; printf "   ${DM}resets %s${RS}" "$week_cd"; forecast_str "$week_eta" "$week_reset"
else
  # WIDE — large bars, full detail
  bw=$(( cols - 90 )); [ "$bw" -lt 20 ] && bw=20; [ "$bw" -gt 40 ] && bw=40
  printf "${CY}%s${RS}%*s%3s%%  " "$label1" "$pad1" "" "$pct";      bar "$pct" "$bw";      printf "   %sk/%sk ${GR}(%sk free)${RS}\n" "$used_k" "$ctx_k" "$remain_k"
  printf "${MG}%s${RS}%*s%3s%%  " "$label2" "$pad2" "" "$five_pct"; bar "$five_pct" "$bw"; printf "   ${DM}resets %s${RS}" "$five_cd"; forecast_str "$five_eta" "$five_reset"; printf "\n"
  printf "${BL}%s${RS}%*s%3s%%  " "$label3" "$pad3" "" "$week_pct"; bar "$week_pct" "$bw"; printf "   ${DM}resets %s${RS}" "$week_cd"; forecast_str "$week_eta" "$week_reset"
fi

# --- Line 5: account-wide "Total tokens" (matches the /usage dialog) ---
if [ -n "$tok_total" ]; then
  padT=$(( pad - 6 )); [ "$padT" -lt 1 ] && padT=1
  printf "\n"
  printf "${GR}%s${RS}%*s      " "Tokens" "$padT" ""
  printf "${BD}%s${RS} ${DM}total (in+out, per /usage)${RS}" "$tok_total"
fi
