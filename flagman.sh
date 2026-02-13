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


print_help(){
  cat <<EOF


EOF
}

_tmpdir="$HOME/.manflag/tmp"
[[ ! -d "$_tmpdir" ]] && mkdir -p "$_tmpdir"
cleanup() {
  local code=$?
  if [[ $code -eq 0 ]] ;then
    ok "done"
  else
    [[ -n ${_tmpdir:-} && -d "$_tmpdir" ]] && rm -rf -- "$_tmpdir"
    warn "exit code $code"
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
COLOR=false
LIST=()

GET_MAN(){ # for one lib
  lib="${1,,}" ; shift
  PARTS=()
  WANTED=()
  if [[ ! $(find "${_tmpdir}/." -type f -name "${lib}") ]] ;then
    _tmp="$(mktemp "${_tmpdir}/${lib}.XXXXXX.txt")" || die "Couldn't make tmp file"
  else
    _tmp="$(find "${_tmpdir}/." -type f -name "${lib}")"
  fi

  if have "$lib";then
    res=$(man "$lib")
    if [[ $res == "No manual"* ]];then
      err "${lib} doesn't have a man page"
      return
    else
      echo "$res" > "$_tmp" || die "Couldn't write in tmp file"
      while IFS="\n       -" read -r part ; do
        echo -e "$part"
        if (( $# != 0 ));then
          for f in $@;do
            if [[ "$part" =~ ^[" "]+["-"]+["\S "]+["\n"]?[" "]+["\S \n"]+$ ]];then
              #echo -e "$part"
              WANTED+=("$part")
            fi
            PARTS+=("$part")
          done
        fi
      done <<< "$(cat $_tmp | tr '\n\n' '\n' )"
    fi
  else
    err "${lib} doesn't exist."
    return
  fi

  #echo "${PARTS[16]}"

  for (( i=0 ; i<${#WANTED[@]} ; i++ ));do
    echo -e "${i}: ${WANTED[i]}"
  done
}

#(( $# == 0 )) && { show_help ; exit 0 ;}
GET_MAN "curl" "-p"
while (($#)); do
  case "$1" in
    -h|--help) show_help ; exit 0 ;;
    -C|--color) COLOR=true; shift ;;
    --) shift ; break ;;
    -*) die "Unknown option: $1" ;;
    *) LIST+=("$1") ; shift ;;
  esac
done
