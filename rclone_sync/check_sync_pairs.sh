#!/bin/zsh

# get output from inotifywait via pipe for the watch on sync_pairs,
# if changed remove watches from local folders and rewrite them
. "test2 üä ejkrfjs/test.sh"
. ./test/aliases.sh

echo "x.l8:funcsourcetrace:${funcsourcetrace[-1]#*:}"
  echo "x.l9:$(a_line_number)"
function modi(){
  echo foo
  echo bar
  echo "x.l13:funcsourcetrace:${funcsourcetrace[-1]#*:}"
  echo "x.l14:funcfiletrace:${funcfiletrace[-1]#*:}"
  echo "x.l15:functrace:${functrace[-1]#*:}"
  echo "x.l16:$(a_line_number)"
  return
}
modi

  echo "x.l21:$(a_line_number)"
function run(){
  last_date=unix_time
  while read LINE; do
    if echo $LINE |
    grep 'sync_pairs MODIFY'; then
      local now_date=$(date +%s)
      if $((now_date - last_date)) -gt 2; then
        modi
      fi 
    fi
  done
}


if tty >/dev/null ; then
  # stdin is a tty: process command line
  #echo "current_script_path_dir_path:$(current_script_path_dir_path)"
  #echo "current_script_path_full_path_ext:$(current_script_path_full_path_ext)"
  #echo "current_script_path_full_path:$(current_script_path_full_path)"
  echo --------------------------------------------
  #echo "__cspfp:$(readlink -f "${(%):-%x}")"
  #echo "a_cspfp:$(a_current_script_path_full_path)"
  #echo "__cspfpne:${$(readlink -f "${(%):-%x}"):r}"
  #echo "a_cspfpne:$(a_current_script_path_full_path_no_ext)"
  #echo "__cspdp:$(cd "$(dirname "$(readlink -f "${(%):-%x}")")" >/dev/null 2>&1 && pwd)"
  #echo "a_cspdp:$(a_current_script_path_dir_path)"
  #echo "__cspsn:${$(basename $(readlink -f "${(%):-%x}")):r}"
  #echo "a_cspsn:$(a_current_script_path_script_name)"
  #echo "__cspsne:${$(basename $(readlink -f "${(%):-%x}")):t}"
  #echo "a_cspsne:$(a_current_script_path_script_name_ext)"
  #echo "__cspse:${$(basename $(readlink -f "${(%):-%x}")):t:e}"
  #echo "a_cspse:$(a_current_script_path_script_ext)"
  
  #echo "$(cd "$(dirname "$(readlink -f "${(%):-%x}")")" >/dev/null 2>&1 && pwd)${$(readlink -f "${(%):-%x}"):r}"
  #echo "5:${$(readlink -f "${(%):-%x}"):r}"
  #echo $(echo "$(cd "$(dirname "$(readlink -f "${(%):-%x}")")" >/dev/null 2>&1 && pwd)/${$(readlink -f "${(%):-%x}"):r}")
  echo "test:__csptvn:${${$(readlink -f "${(%):-%x}"):r}//[^a-zA-Z0-9]/_}"
  echo "test:a_csptvn:$(a_current_script_path_2to_variable_name)"
else
  # stdin is not a tty: process standard input
  echo "!tty"
  run
fi
