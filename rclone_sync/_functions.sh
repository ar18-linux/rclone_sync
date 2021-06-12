#!/bin/zsh

exec 3<> $PIPE

function on_click() {
  echo "clicked"
  #echo "quit" >&3
  #kill -cont $$
}

function my_pause(){
  local rclone_pid=$(cat "${temp_dir}/rclone_pid")
  echo "$(date)" > "${temp_dir}/stopped"
  echo "tooltip:Syncing paused" >&3
  kill -stop ${rclone_pid}
  printf "%s" "continue" > "${temp_dir}/rebuild_menu"
}

function my_continue(){
  echo "continue"
  local rclone_pid=$(cat "${temp_dir}/rclone_pid")
  rm "${temp_dir}/stopped"
  kill -cont ${rclone_pid}
  printf "%s" "pause" > "${temp_dir}/rebuild_menu"
}


function show_errors(){
  echo "show errors"
  my_date=$(date +%s) 
  mv "${temp_dir}/errors" "${temp_dir}/errors_${my_date}" 
  xdg-open "${temp_dir}/errors_${my_date}" &!
  printf "%s" "errors_cleared" > "${temp_dir}/rebuild_menu"
}


function show_output(){
  xterm -e "tail -f ${temp_dir}/output" &!
}


function build_base_menu(){
  echo "Rebuilding menu for $1"
  local new_menu="menu:"
  new_menu="${new_menu}Quit!zsh -c \"kill -usr1 ${parent_pid}\"!application-exit"
  if [[ -f "${temp_dir}/stopped" ]]; then
    new_menu="${new_menu}|Continue!zsh -c \". ${dir_name}/_functions.sh; my_continue\"!media-playback-start"
  else 
    new_menu="${new_menu}|Pause!zsh -c \". ${dir_name}/_functions.sh; my_pause\"!media-playback-pause"
  fi
  new_menu="${new_menu}|Output!zsh -c \". ${dir_name}/_functions.sh; show_output\"!preview-file"
  new_menu="${new_menu}|Devices!xdg-open ${dir_name}/disallowed_interfaces!1E64_notepad.0"
  new_menu="${new_menu}|Pairs!xdg-open ${dir_name}/sync_pairs!1E64_notepad.0"
  if [[ -f "${temp_dir}/errors" ]]; then
    new_menu="${new_menu}|Errors!zsh -c \". ${dir_name}/_functions.sh; show_errors\"!error"
  fi
  echo "${new_menu}" >&3
  printf "%s" "$(date +%s)" > "${temp_dir}/ts_menu_built"
}

function strindex(){ 
  local x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}
