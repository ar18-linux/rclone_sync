#!/bin/zsh
export dir_name="$(dirname "$(realpath $0)")"
export script_name="${$(readlink -f "${(%):-%x}"):t}"
guard_id=-1
rclone_pid=-1
export parent_pid=$$
export DISPLAY=:0
echo "this pid is [${parent_pid}]"
export cleaned=0
file_size_threshold="5M"
tray_update_interval=1
export temp_dir="/dev/shm/rclone_gui_sync"
mkdir -p "${temp_dir}"
#set -x

# create a FIFO file, used to manage the I/O redirection from shell
export PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
mkfifo $PIPE
. "${dir_name}/_functions.sh"

# attach a file descriptor to the file
exec 3<> $PIPE

function on_kill(){
  echo "on_kill"

  if [[ -f "${temp_dir}/rclone_syncing" ]]; then 
    echo "removing lock file"
    rm "${temp_dir}/rclone_syncing" || true
  fi
  if [[ -f "${temp_dir}/rclone_pid" ]]; then 
    echo "removing pid file"
    rm "${temp_dir}/rclone_pid" || true
  fi
  trap '' EXIT
  my_exit
  #exit
}

# add handler to manage process shutdown
function my_exit(){
  echo "my_exit"
  cleanup
  exit
}

function cleanup(){
  echo "cleanup"
  if [[ "${cleaned}" == "1" ]]; then
    return
  fi
  echo "quit" >&3
  rm -f $PIPE
  if [[ "${guard_id}" != "-1" ]]; then
    echo "killing guard [${guard_id}]"
    kill "${guard_id}"
    echo killed
  fi 
  if [[ "${rclone_pid}" != "-1" ]]; then
    echo "killing rclone [${rclone_pid}]"
    kill "${rclone_pid}"
  fi
  rm -rf "${temp_dir}"
  cleaned=1 
}

function on_stop(){
  echo "on_stop triggered"
  my_pause
}

trap on_kill USR1 INT

trap on_stop USR2


function render_tray_icon(){
  local start=1
  local step=1
  local place_holder="1"
  while kill -0 "$1"; do
    sleep ${tray_update_interval}
    if [[ -f "${temp_dir}/rebuild_menu" ]]; then
      local reason="$(cat "${temp_dir}/rebuild_menu")"
      if [[ "${reason}" != "${last_menu_rebuilt_reason}" ]]; then
        ts_now="$(date +%s)"
        if [[ ! -f "${temp_dir}/ts_menu_built" ]] \
        || [[ "$((ts_now - $(cat "${temp_dir}/ts_menu_built")))" -gt 5 ]]; then
          build_base_menu "${reason}"
          last_menu_rebuilt_reason="${reason}"
        fi
      fi
    fi
    if [[ -f "${temp_dir}/errors" ]];then
      echo "tooltip:There were errors" >&3
      echo "icon:error" >&3
      printf "%s" "errors" > "${temp_dir}/rebuild_menu"
      continue
    elif [[ -f "${temp_dir}/stopped" ]]; then
      echo "icon:media-playback-pause" >&3
      continue
    fi
    echo "tooltip:Syncing [${pair[1]}] to [${pair[2]}]" >&3
    # Animation for 2-way sync.
    if [[ "${pair[3]}" == "2" ]]; then
      if [[ "${start}" == "200" ]]; then
        place_holder="100"
        step=-5
      elif [[ "${start}" == "100" ]]; then
        step=5
        place_holder="${start:1:2}"
      else
        place_holder="${start:1:2}"
      fi
      start=$((start + step))
    # Animation for 1-way sync.
    elif [[ "${pair[3]}" == "1" ]]; then
      #
      if [[ "$(strindex "${pair[2]}" ":")" != "-1" ]]; then
        step=1
        if [[ "${start}" == "12" ]]; then
          place_holder="1"
          start=1
        else
          place_holder="${start}"
          start=$((start + step))
        fi
      #
      else
        step=-1
        if [[ "${start}" == "0" ]]; then
          place_holder="11"
          start=$((start + step))
        elif [[ "${start}" == "0" ]]; then
          place_holder="1"
          start=11
        else
          place_holder="${start}"
          start=$((start + step))
        fi
      fi
    fi
    #echo "icon:btsync-gui-${place_holder}"
    echo "icon:btsync-gui-${place_holder}" >&3
  done
}


function render_tray_icon_xubuntu(){
  local start=200
  local step=5
  local place_holder="00"
  while kill -0 "$1"; do
    sleep ${tray_update_interval}
    if [[ -f "${temp_dir}/rebuild_menu" ]]; then
      local reason="$(cat "${temp_dir}/rebuild_menu")"
      #echo "${last_menu_rebuilt_reason}"
      #echo "${reason}"
      if [[ "${reason}" != "${last_menu_rebuilt_reason}" ]]; then
        ts_now="$(date +%s)"
        if [[ ! -f "${temp_dir}/ts_menu_built" ]] \
        || [[ "$((ts_now - $(cat "${temp_dir}/ts_menu_built")))" -gt 5 ]]; then
          build_base_menu "${reason}"
          last_menu_rebuilt_reason="${reason}"
        fi
      fi
    fi
    if [[ -f "${temp_dir}/errors" ]];then
      echo "tooltip:There were errors" >&3
      echo "icon:error" >&3
      printf "%s" "errors" > "${temp_dir}/rebuild_menu"
      continue
    elif [[ -f "${temp_dir}/stopped" ]]; then
      echo "icon:media-playback-pause" >&3
      continue
    fi
    echo "tooltip:Syncing [${pair[1]}] to [${pair[2]}]" >&3
    # Animation for 2-way sync.
    if [[ "${pair[3]}" == "2" ]]; then
      if [[ "${start}" == "200" ]]; then
        place_holder="100"
        step=-5
      elif [[ "${start}" == "100" ]]; then
        step=5
        place_holder="${start:1:2}"
      else
        place_holder="${start:1:2}"
      fi
      start=$((start + step))
    # Animation for 1-way sync.
    elif [[ "${pair[3]}" == "1" ]]; then
      #
      if [[ "$(strindex "${pair[2]}" ":")" != "-1" ]]; then
        step=5
        if [[ "${start}" == "300" ]]; then
          place_holder="100"
          start=200
        else
          place_holder="${start:1:2}"
          start=$((start + step))
        fi
      #
      else
        step=-5
        if [[ "${start}" == "200" ]]; then
          place_holder="100"
          start=$((start + step))
        elif [[ "${start}" == "100" ]]; then
          place_holder="00"
          start=200
        else
          place_holder="${start:1:2}"
          start=$((start + step))
        fi
      fi
    fi
    #echo "icon:brasero-disc-${place_holder}"
    echo "icon:brasero-disc-${place_holder}" >&3
  done
}


function init_action(){
  local source="$1"
  local dest="$2"
  local mode="$3"
  local parms="$4"
  #echo "rclone sync ${source} ${dest} ${parms} --progress --exclude-from \"${dir_name}/exclude_list\"" > /tmp/out2
  if [[ "${mode}" == "1" ]]; then
    echo "tooltip:1-way sync [${source}] to [${dest}]" >&3
    rclone sync $(echo ${source}) $(echo ${dest}) $(echo ${parms}) --progress --exclude-from "${dir_name}/exclude_list" > "${temp_dir}/output" &
  elif [[ "${mode}" == "2" ]]; then
    #echo "not implemented"
    echo "2-way sync not implemented" > "${temp_dir}/errors"
    continue
  elif [[ "${mode}" == "3" ]]; then
    echo "tooltip:moving contents of [${source}] to [${dest}]" >&3
    rclone move $(echo ${source}) $(echo ${dest}) $(echo ${parms}) --progress > "${temp_dir}/output" &
    #echo "not implemented"
    #echo "move operation not implemented" > "${temp_dir}/errors"
  fi
  local rclone_pid=$!
  echo "${rclone_pid}"
}


function run(){
  echo "scrip_name:${script_name}"
  local other_pid="$(pidof -x "${script_name}")"
  echo "other:${other_pid}"
  #echo "other:${other_pid}" > /tmp/out2
  if [[ -f "${temp_dir}/rclone_syncing" ]]; then
    echo "sync lock file found, sync already in progress?"
    if [[ "${other_pid}" != "" ]] && [[ "${other_pid}" != "$$" ]]; then
      #echo "Process already running1" >> /tmp/out2
      return
    else
      rm -rf "${temp_dir}/rclone_syncing"
    fi
  fi
  if [[ "${other_pid}" != "" ]] && [[ "${other_pid}" != "$$" ]]; then
    #echo "Process already running2" >> /tmp/out2
    #echo $(pidof -x "${script_name}") >>/tmp/out2
    return
  fi

  trap cleanup EXIT
  
  local last_menu_rebuilt_reason=""

  local input="${dir_name}/disallowed_interfaces"
  # Test if we are connected to an allowed interface.
  if [[ -f "${input}" ]]; then
    while IFS= read -r line; do
      echo "${line}"
      if [[ "${line:0:1}" == "#" ]] || [[ "${line}" == "" ]]; then
        continue
      fi
      local output="$(/sbin/route -n | sed -n '3 p' | grep "${line}")"
      if [[ "${output}" != "" ]]; then
        >&2 echo "interface [${line}] not allowed, but is set as primary"
        return
      fi
    done < "$input"
  fi

  local input="${dir_name}/sync_pairs"
  if [[ -f "${input}" ]]; then
    echo "$(date)" > "${temp_dir}/rclone_syncing"
    echo "Beginning sync"
    # Initiating interface guard.
    "${dir_name}/_check_for_disallowed_interface.sh" $$ &!
    guard_id="$(echo $!)"
    echo "guard_id [${guard_id}]"
    # create the notification icon
    /usr/bin/yad \
    --notification \
    --listen \
    --image="btsync-gui-1" \
    --text="rclone gui sync" \
    --command="zsh -c \". ${dir_name}/_functions.sh; on_click;\"" <&3 &
    
    build_base_menu "init"
    while IFS= read -r line; do
      
      if [[ "${line}" == "" ]] || [[ "${line:0:1}" == "#" ]]; then
        continue
      fi
      echo "line:${line}"
      local old_ifs="${IFS}"
      IFS=$'\t' 
      local pair=($(echo "${line}"))
      IFS="${old_ifs}"
      
      # First sync small files
      rclone_pid="$(init_action "${pair[1]}" "${pair[2]}" "${pair[3]}" \
      "--max-size ${file_size_threshold}")"
      echo "rclone_pid [${rclone_pid}]"
      printf "%s" "${rclone_pid}" > "${temp_dir}/rclone_pid"
      render_tray_icon ${rclone_pid}
      
      # Then large files, but only one at a time
      rclone_pid="$(init_action "${pair[1]}" "${pair[2]}" "${pair[3]}" \
      "--transfers=1 --min-size ${file_size_threshold}")"
      echo "rclone_pid [${rclone_pid}]"
      printf "%s" "${rclone_pid}" > "${temp_dir}/rclone_pid"
      render_tray_icon ${rclone_pid}
      
      #tail --pid=${rclone_pid} -f /dev/null
      #wait
    done < "$input"
    rm "${temp_dir}/rclone_syncing" || true
  fi

}

run