#!/bin/zsh

dir_name="$(dirname "$(realpath $0)")"
parent_pid=$1

while true; do
  
  file_size=$(stat -c%s "${temp_dir}/output")
  if [[ "${file_size}" -gt 10000 ]]; then
    echo '' > "${temp_dir}/output"
  fi
  
  sleep 10
  input="${dir_name}/disallowed_interfaces"
  # Test if we are connected to an allowed interface.
  if [[ -f "${input}" ]] && [[ ! -f "${temp_dir}/stopped" ]]; then
    while IFS= read -r line; do
      if [[ "${line:0:1}" == "#" ]] || [[ "${line}" == "" ]]; then
        continue
      fi
      output="$(/sbin/route -n | sed -n '3 p' | grep "${line}")"
      if [[ "${output}" != "" ]]; then
        echo "interface [${line}] not allowed, but is set as primary: syncing paused" > "${temp_dir}/errors"
        kill -usr2 ${parent_pid}
      fi
    done < "$input"
  fi
done