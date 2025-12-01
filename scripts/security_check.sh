#!/usr/bin/env bash

set -uo pipefail

export LC_ALL=C LANG=C

VERBOSE=0
STRICT=0
SELFTEST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    --strict)     STRICT=1 ;;
    --self-test|--selftest) SELFTEST=1 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" ; exit 2 ;;
    *)  break ;;
  esac
  shift
done

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [--verbose] [--strict] [--self-test] <path-to-libmemalloc.(a|so)|executable>"
  exit 2
fi

TARGET="$1"
[[ -e "$TARGET" ]] || { echo "File not found: $TARGET"; exit 2; }

CC=${CC:-cc}
for tool in readelf objdump file grep awk sed ar nm "$CC"; do
  command -v "$tool" >/dev/null || { echo "'$tool' not found in PATH"; exit 2; }
done

ROOT="$(pwd)"
WORKDIR="$ROOT/sec_check"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cleanup(){ rm -rf "$WORKDIR"; }
trap cleanup EXIT INT TERM

has_flag() {
  echo 'int main(void){return 0;}' | "$CC" -Werror -x c - $1 -o /dev/null >/dev/null 2>&1
}

detect_std_flag() {
  for f in -std=c23 -std=c2x -std=gnu2x -std=gnu17; do
    if has_flag "$f"; then echo "$f"; return; fi
  done
  echo ""
}

detect_fortify_level() {
  if echo 'int main(void){return 0;}' | "$CC" -O2 -D_FORTIFY_SOURCE=3 -x c - -o /dev/null >/dev/null 2>&1; then
    echo 3
  else
    echo 2
  fi
}

STD_FLAG="$(detect_std_flag)"
FORT_LVL="$(detect_fortify_level)"

CFLAGS="-O2 ${STD_FLAG} -D_FORTIFY_SOURCE=${FORT_LVL} -fstack-protector-strong -fno-strict-overflow -fno-strict-aliasing -fPIE -pthread"
LDFLAGS="-pie -pthread -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,-z,separate-code -Wl,--as-needed -Wl,--build-id=sha1"

has_flag -ftrivial-auto-var-init=pattern && CFLAGS+=" -ftrivial-auto-var-init=pattern"
has_flag -fzero-call-used-regs=used     && CFLAGS+=" -fzero-call-used-regs=used"
has_flag -fcf-protection=full           && CFLAGS+=" -fcf-protection=full"
has_flag -fno-plt                       && CFLAGS+=" -fno-plt"
if has_flag -mbranch-protection=standard; then
  case "$(uname -m)" in
    aarch64|arm64) CFLAGS+=" -mbranch-protection=standard" ;;
  esac
fi

SONAME_POLICY="${SONAME_POLICY:-}"

cat > "$WORKDIR/fortify_probe.c" <<'EOF'
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static volatile int sink;

#if defined(__GNUC__)
__attribute__((noinline))
#endif
int probe_strcpy(const char *s)
{
    char d[8];
    strcpy(d, s); // should resolve to __strcpy_chk
    sink += d[0];
    return d[0];
}

#if defined(__GNUC__)
__attribute__((noinline))
#endif
int probe_sprintf(void)
{
    char buf[16];
    int x = 42;
    sprintf(buf, "%d", x);   // should resolve to __sprintf_chk
    return buf[0];
}

#if defined(__GNUC__)
__attribute__((noinline))
#endif
int probe_memcpy(void)
{
    char dst[16], src[16] = "hello";
    memcpy(dst, src, sizeof(src)); // may resolve to __memcpy_chk
    return dst[0];
}

int probe_snprintf(void)
{
    char buf[8];
    return snprintf(buf, sizeof(buf), "abc:%d", 7);
}

int main(void)
{
    probe_strcpy("AAAAAAA");
    probe_sprintf();
    probe_memcpy();
    probe_snprintf();
    puts("fortify probes ran");
    return 0;
}
EOF

"$CC" $CFLAGS -c "$WORKDIR/fortify_probe.c" -o "$WORKDIR/fortify_probe.o"

OUT_EXE=""
case "$TARGET" in
  *.a)
    "$CC" $CFLAGS "$WORKDIR/fortify_probe.o" \
      -Wl,--whole-archive "$TARGET" -Wl,--no-whole-archive \
      -o "$WORKDIR/fortify_with_lib" $LDFLAGS
    OUT_EXE="$WORKDIR/fortify_with_lib"
    ;;
  *.so)
    "$CC" $CFLAGS "$WORKDIR/fortify_probe.o" "$TARGET" \
      -o "$WORKDIR/fortify_with_lib" $LDFLAGS
    OUT_EXE="$WORKDIR/fortify_with_lib"
    ;;
  *)
    # TARGET is already an executable: do not build a probe
    :
    ;;
esac

if [[ -n "$OUT_EXE" && ! -x "$OUT_EXE" ]]; then
  warn "Não consegui linkar o executável de probe contra '$TARGET' (checks via probe limitados)."
  OUT_EXE=""
fi

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
info()   { [[ $VERBOSE -eq 1 ]] && printf "\033[36m%s\033[0m\n" "$*"; }

PASS_CNT=0; FAIL_CNT=0; WARN_CNT=0
pass(){ green  " [PASS] $*"; ((PASS_CNT++)); }
_fail(){ red    " [FAIL] $*"; ((FAIL_CNT++)); }
warn(){
  if (( STRICT )); then _fail "(strict) $*"; else yellow " [WARN] $*"; ((WARN_CNT++)); fi
}

banned_api_scan() {
  local BIN="$1"
  local banned='(^|[^[:alnum:]_])(gets|strcpy|strcat|sprintf|vsprintf|stpcpy|mktemp|tmpnam|tempnam)($|[^[:alnum:]_])'
 	if objdump -T "$BIN" 2>/dev/null | grep -Eq "${banned}" \
    	|| objdump -t "$BIN" 2>/dev/null | grep -Eq "${banned}"; then
    _fail "Banned libc API referenced/exported (gets/strcpy/strcat/sprintf/...)"
  else
    pass "No banned libc APIs referenced/exported"
  fi
}

debug_sections_scan() {
  local BIN="$1"
  if readelf -S "$BIN" 2>/dev/null | grep -Eq '\.debug_(info|line|abbrev|arranges|str|pub(names|types))'; then
    warn "Debug sections present (.debug_*) — consider stripping for release"
  else
    pass "No .debug_* sections present"
  fi
}

gotplt_relro_check() {
  local BIN="$1"
  if readelf -lW "$BIN" | grep -q 'GNU_RELRO' && readelf -d "$BIN" 2>/dev/null | grep -q 'BIND_NOW'; then
    pass ".got.plt protected by FULL RELRO"
  else
    warn ".got.plt may be writable at startup (not FULL RELRO)"
  fi
}

soname_policy_check() {
  local BIN="$1" want="$2"
  [[ -n "$want" ]] || return 0
  if readelf -h "$BIN" | grep -q 'Type:.*DYN' && ! readelf -lW "$BIN" | grep -q 'Requesting program interpreter'; then
    local soname
    soname="$(readelf -d "$BIN" 2>/dev/null | awk -F'[][]' '/SONAME/{print $2}')"
    if [[ -z "$soname" ]]; then
      warn "No SONAME to compare against policy ($want)"
    elif [[ "$soname" == "$want" || $soname == $want* ]]; then
      pass "SONAME matches policy ($soname)"
    else
      warn "SONAME '$soname' differs from policy ('$want')"
    fi
  fi
}

retpoline_check() {
  local BIN="$1"
  if objdump -d "$BIN" 2>/dev/null | grep -q '__x86_indirect_thunk_'; then
    pass "Retpoline thunks present (__x86_indirect_thunk_*)"
  else
    info "No retpoline thunks detected (may be fine depending on toolchain)"
  fi
}

external_tools_summaries() {
  local BIN="$1"
  if [[ $VERBOSE -eq 1 ]]; then
    if command -v hardening-check >/dev/null; then
      info "hardening-check:"
      hardening-check "$BIN" | sed 's/^/  /'
    fi
    if command -v checksec >/dev/null; then
      info "checksec --file:"
      checksec --file="$BIN" | sed 's/^/  /'
    fi
  fi
}

audit_elf() {
  local BIN="$1"

  local ftype
  ftype=$(file -b "$BIN" 2>/dev/null || true)
  if [[ $ftype != ELF* ]]; then
    info "[skip] not an ELF: $BIN (type: $ftype)"
    return 0
  fi

  local TYPE MACHINE LMACHINE
  TYPE=$(readelf -h "$BIN" | awk -F: '/Type:/{gsub(/^[ \t]+/,"",$2); print $2}')
  MACHINE=$(readelf -h "$BIN" | awk -F: '/Machine:/{gsub(/^[ \t]+/,"",$2); print $2}')
  LMACHINE=$(printf "%s" "$MACHINE" | tr '[:upper:]' '[:lower:]')

  local HAS_INTERP=0
  if readelf -lW "$BIN" | grep -q 'Requesting program interpreter'; then
    HAS_INTERP=1
  fi

  # PIE
  if [[ $HAS_INTERP -eq 1 && "$TYPE" == *"DYN"* ]]; then
    pass "PIE enabled (ET_DYN + PT_INTERP)"
  elif [[ $HAS_INTERP -eq 1 && "$TYPE" == *"EXEC"* ]]; then
    _fail "No PIE (ET_EXEC detected)"
  else
    pass "PIE not applicable (not a dynamic executable)"
  fi

  # RELRO
  if readelf -lW "$BIN" | grep -q 'GNU_RELRO'; then
    if readelf -d "$BIN" 2>/dev/null | grep -q 'BIND_NOW'; then
      pass "FULL RELRO (-z relro -z now)"
    else
      warn "Partial RELRO (-z relro without -z now)"
    fi
  else
    _fail "No RELRO"
  fi

  # NX
  local STACK_LINE
  STACK_LINE=$(readelf -lW "$BIN" | awk '/GNU_STACK/{print}')
  if [[ -n "$STACK_LINE" ]]; then
    if echo "$STACK_LINE" | grep -q 'E'; then
      _fail "GNU_STACK is executable (no NX)"
    else
      pass "NX enabled (GNU_STACK without E)"
    fi
  else
    warn "No GNU_STACK header (NX heuristic inconclusive)"
  fi

  # Stack protector
  if readelf -sW "$BIN" 2>/dev/null | grep -Eq '__stack_chk_fail|__stack_chk_guard'; then
    pass "Stack protector in use (__stack_chk_*)"
  else
    warn "No evidence of stack protector"
  fi

  # FORTIFY
  if readelf -sW "$BIN" 2>/dev/null | grep -Eiq '(_chk@|__.*_chk)'; then
    pass "FORTIFY detected (*_chk functions present)"
  else
    warn "No *_chk detected (may be normal)"
  fi

  # RPATH/RUNPATH
  if readelf -d "$BIN" 2>/dev/null | grep -q '(RPATH)'; then
    _fail "RPATH present"
  else
    if readelf -d "$BIN" 2>/dev/null | grep -q '(RUNPATH)'; then
      warn "RUNPATH present (prefer to avoid in production)"
    else
      pass "No RPATH/RUNPATH"
    fi
  fi

  # TEXTREL
  if readelf -d "$BIN" 2>/dev/null | grep -q 'TEXTREL'; then
    _fail "TEXTREL detected"
  else
    pass "No TEXTREL"
  fi

  # Build-ID
  if readelf -n "$BIN" 2>/dev/null | grep -q 'Build ID'; then
    pass "Build-ID present"
  else
    warn "No Build-ID (recommend -Wl,--build-id)"
  fi

  # CET/BTI notes
  local NOTES
  NOTES=$(readelf -n "$BIN" 2>/dev/null || true)
  if [[ "$LMACHINE" == *"x86-64"* ]]; then
    if echo "$NOTES" | grep -Eq 'IBT|SHSTK'; then
      pass "CET (IBT/SHSTK) advertised"
    else
      warn "No IBT/SHSTK"
    fi
  fi
  if [[ "$LMACHINE" == *"aarch64"* ]]; then
    if echo "$NOTES" | grep -Eq 'BTI'; then
      pass "AArch64 BTI advertised"
    else
      warn "No BTI"
    fi
  fi

  # W^X
  local LOADS
  LOADS="$(readelf -lW "$BIN" | awk '/LOAD/{print}')"
  if echo "$LOADS" | grep -Eq 'RWE|RW[^ ]*E'; then
    _fail "RWX segment found (W^X violation)"
  else
    pass "W^X ok (no RWX segments)"
  fi

  # SONAME for .so
  if readelf -h "$BIN" | grep -q 'Type:.*DYN' && ! readelf -lW "$BIN" | grep -q 'Requesting program interpreter'; then
    if readelf -d "$BIN" 2>/dev/null | grep -q '(SONAME)'; then
      pass "SONAME present"
    else
      warn "Shared library without SONAME (consider -Wl,-soname,memalloc.so)"
    fi
  fi

  # Hidden unless verbose: interp & NEEDED
  if [[ $VERBOSE -eq 1 && $HAS_INTERP -eq 1 ]]; then
    local interp
    interp="$(readelf -lW "$BIN" | awk -F'[][]' '/Requesting program interpreter/{print $2}' | sed 's/.*: //')"
    info "interp: $interp"
  fi
  local needed n
  needed="$(readelf -d "$BIN" 2>/dev/null | awk -F'[][]' '/NEEDED/{print $2}')"
  if [[ -n "$needed" ]]; then
    [[ $VERBOSE -eq 1 ]] && info "NEEDED: $needed"
    n=$(echo "$needed" | wc -l | tr -d ' ')
    if (( n > 8 )); then
      warn "Too many dependencies ($n); check for unnecessary linkage"
    else
      pass "Dependency count OK ($n)"
    fi
  else
    pass "No dynamic dependencies declared"
  fi

  # Exports & versioning (only .so)
  if readelf -h "$BIN" | grep -q 'Type:.*DYN' && ! readelf -lW "$BIN" | grep -q 'Requesting program interpreter'; then
    local exported count
    exported="$(readelf --dyn-syms "$BIN" 2>/dev/null | awk '$4=="FUNC" && $5=="GLOBAL" && $7=="DEFAULT"{print $8}')"
    count=$(echo "$exported" | sed '/^$/d' | wc -l | tr -d ' ')
    if (( count > 50 )); then
      warn "Too many exported functions ($count) — use -fvisibility=hidden / version script"
    else
      pass "Moderate number of exports ($count)"
    fi
    if readelf -V "$BIN" 2>/dev/null | grep -q 'Version symbols section'; then
      pass "Symbol versioning present"
    else
      warn "No symbol versioning (consider --version-script)"
    fi
  fi

  banned_api_scan "$BIN"
  debug_sections_scan "$BIN"
  gotplt_relro_check "$BIN"
  retpoline_check "$BIN"
  soname_policy_check "$BIN" "$SONAME_POLICY"

  external_tools_summaries "$BIN"
}

archive_scan() {
  local ARCH="$1"
  [[ "${ARCH##*.}" == "a" ]] || return 0

  local ABS_ARCH
  ABS_ARCH="$(cd "$(dirname "$ARCH")" && pwd)/$(basename "$ARCH")"

  local TMP; TMP="$(mktemp -d)"
  ( cd "$TMP" && ar x "$ABS_ARCH" )

  local had=0
  local line
  local found=0
  while IFS= read -r line; do
    found=1
    if readelf -sW "$line" | grep -q '__stack_chk_fail'; then
      printf "  [info] %s references __stack_chk_fail\n" "$(basename "$line")"
      had=1
    fi
    if objdump -t "$line" 2>/dev/null | grep -Eq '(^|[^[:alnum:]_])(gets|strcpy|strcat|sprintf|vsprintf|stpcpy|mktemp|tmpnam|tempnam)($|[^[:alnum:]_])'; then
      printf "  [warn] %s references banned libc API\n" "$(basename "$line")"
    fi
  done < <(find "$TMP" -maxdepth 1 -type f -name '*.o' -print)

  if (( found == 0 )); then
    printf "  [info] no .o members found in archive\n"
  elif (( had == 0 )); then
    printf "  [info] no objects referencing __stack_chk_fail (may be fine)\n"
  fi

  rm -rf "$TMP"
}

run_self_test() {
  local saveP=$PASS_CNT saveW=$WARN_CNT saveF=$FAIL_CNT
  PASS_CNT=0; WARN_CNT=0; FAIL_CNT=0

  local BAD="$WORKDIR/bad.c" OUT="$WORKDIR/bad_elf"
  cat > "$BAD" <<'C'
#include <stdio.h>
#include <string.h>
int main(){
  char b[4];
  strcpy(b,"this will overflow");
  puts("bad");
  return 0;
}
C
  "$CC" -O0 -U_FORTIFY_SOURCE -fno-stack-protector -fno-pic "$BAD" \
        -Wl,-z,norelro -Wl,-z,lazy -Wl,-z,execstack -o "$OUT" 2>/dev/null || true

 if [[ -x "$OUT" ]]; then
   echo "[self-test] auditing intentionally bad ELF (expected FAIL/WARN below)"
   audit_elf "$OUT"
 else
   info "[self-test] falha ao compilar o ELF ruim; autoteste pulado"
 fi
  echo "[self-test] summary (bad ELF): ${PASS_CNT} PASS, ${WARN_CNT} WARN, ${FAIL_CNT} FAIL (expected)"

  PASS_CNT=$saveP; WARN_CNT=$saveW; FAIL_CNT=$saveF
}

(( SELFTEST )) && run_self_test

bins=()
[[ -n "$OUT_EXE" ]] && bins+=("$OUT_EXE")

if [[ "$TARGET" != *.a ]]; then
  bins+=("$TARGET")
fi

for b in "${bins[@]}"; do
  audit_elf "$b"
done

[[ "$TARGET" == *.a ]] && archive_scan "$TARGET"

echo
if (( FAIL_CNT > 0 )); then
  red   "Summary: ${PASS_CNT} PASS, ${WARN_CNT} WARN, ${FAIL_CNT} FAIL"; exit 1
fi
if (( WARN_CNT > 0 )); then
  if (( STRICT )); then
    red   "Summary (strict): ${PASS_CNT} PASS, ${WARN_CNT} WARN -> FAIL"; exit 1
  else
    yellow "Summary: ${PASS_CNT} PASS, ${WARN_CNT} WARN, ${FAIL_CNT} FAIL"
  fi
else
  green  "Summary: ${PASS_CNT} PASS, ${WARN_CNT} WARN, ${FAIL_CNT} FAIL"
fi
