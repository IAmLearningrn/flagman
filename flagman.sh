
#!/usr/bin/env bash
#flagman - A CLI to show man pages for a specific flag.

set -euo pipefail
IFS=$'\n\t'

: "${DEBUG:=false}"
: "${TRACE:=false}"
if [[ "$TRACE" == true ]]; then
  export PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}()  '
  set -x
  set -E
  trap 'err "ERR at ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (status=$?)"' ERR
elif [[ "$DEBUG" == true ]]; then
  set -x
fi

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

print_help(){
  cat <<EOF


EOF
}

_tmpdir="$HOME/.manflag/tmp"
[[ ! -d "$_tmpdir" ]] && mkdir -p "$_tmpdir"
cleanup() {
  local code=$?
  [[ -n ${_tmpdir:-} && -d "$_tmpdir" ]] && rm -rf -- "$_tmpdir"
  if [[ $code -eq 0 ]] ;then
    $DEBUG && ok "done"
  else
    $DEBUG && warn "exit code $code"
  fi
  exit "$code"
}
trap cleanup EXIT INT TERM

have() { command -v -- "$1" >/dev/null 2>&1; }

if [[ -t 2 ]]; then
  _b=$'\033[1m'; _d=$'\033[0m'
  _red=$'\033[31m'; _yel=$'\033[33m'; _grn=$'\033[32m'; _blu=$'\033[34m'
else
  _b='' _d='' _red='' _yel='' _grn='' _blu=''
fi
warn() { printf '%s[WARN]%s %s\n' "$_b$_yel" "$_d" "$*" >&2; }
ok()   { printf '%s[ OK ]%s %s\n' "$_b$_grn" "$_d" "$*" >&2; }
die()  { printf '%s[ ERR ]%s %s\n' "$_b$_red" "$_d" "$*" >&2; exit 1; }
err()  { printf '%s[ ERR ]%s %s\n' "$_b$_red" "$_d" "$*" >&2; }

COLOR=${COLOR:-false}
LIB=""
FLAGS=()

GET_MAN(){ # for one lib
  lib="${1,,}" ; shift
  PARTS=()
  WANTED=()

  _tmp="$(mktemp "$_tmpdir/${lib}.txt.XXXXXX")" || die "mktemp failed"

  if have "$lib";then
    man "$lib" > "$_tmp" 2>/dev/null || die "Failed Writing the tmp file"
    if [[ "$(man $lib | head -n 1)" == "No manual"* ]];then
      err "${lib} doesn't have a man page"
      return
    else
      if (( $# != 0 ));then
        for f in ${FLAGS[@]};do
          found="$(python3 - "$_tmp" "$f" <<'PY'
import re
import sys
file=sys.argv[1]
flag=sys.argv[2]
regex = r"[ ]{3}[-]{1,2}[\S ]*([\n]{1}[ ]{3}[\S ]*)*"
data=open(file).read()
matches = re.finditer(regex, data)
found=[]
for matchNum, match in enumerate(matches, start=1):
    g=match.group()
    if flag in g:
      found.append(g)

if len(found) == 0:
    print("No Result")
else:
    for p in found:
        print(p)
PY
)"
          echo -e "\n --- ${f}: --- \n"
          if $COLOR ; then
            echo "${found//$f/$_red$f$_d}"
          else
            echo -e "$found"
          fi
        done
      fi
    fi
  else
    die "${lib} doesn't exist."
  fi
}

FLAG_PARSE(){
  flags="$@"
  while IFS=" " read -a flags ; do
    FLAGS+=(${flags[@]})
  done <<< "${flags}"
}

#(( $# == 0 )) && { show_help ; exit 0 ;}
#GET_MAN "grep" "-p"
ARGS=()
while (($#)); do
  case "$1" in
    -h|--help) print_help ; exit 0 ;;
    --lib) LIB="${2:?$(die "Need a Lib")}";shift 2 ;;
    --flags) shift ; ARGS+=("$@") ; shift $# ;;
    --) shift ; ARGS+=("$@") ; break ;;
    -*) ARGS+=("$@") ; shift $# ;;
    *) ARGS+=("$@") ; shift $# ;;
  esac
done

if ! have python3;then
  die "Python3 is required"
fi

echo "Lib: ${LIB}"
echo "Flags: ${ARGS[@]}"
if have $LIB ; then
  FLAG_PARSE "${ARGS[@]}"
  GET_MAN "$LIB" "$FLAGS[@]"
else
  die "'${LIB}' Not Found"
fi
