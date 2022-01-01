#!/usr/bin/env bash

# ===========================================================
# Shellplate boilerplate v1.0
# Written by: @DarkGuy10 (https://github.com/DarkGuy10)
# Shellplate Repo: https://github.com/DarkGuy10/Shellplate
# ===========================================================

script_name=""
script_author=""
script_version=""
script_repository=""
script_description=""

centre() {
  folded=$(printf "$1" | fold -w 80 -s)
  count=$(printf "$folded" | grep "" -c)
  for (( i = 1; i <= $count; i++ )); do
    line=$(printf "$folded" | grep "" -m "$i" | tail -1)
    length=${#line}
    printf "%*s\n" $((($length+80)/2)) "$line"
  done
}

header(){
  tput bold; centre "[ $1 ]"; tput sgr0
}

check_requirements() {
  printf "=================================\n"
  printf "===   CHECKING REQUIREMENTS   ===\n"
  printf "=================================\n"
  all_dependencies_met="true"
  count=`grep "" requirements.txt -c`
  for (( i = 1; i <= $count; i++ )); do
    req=`grep "" requirements.txt -m "$i" | tail -1`
    sleep 0.3
    printf "\t$req"
    if [ ! -z `command -v $req` ]; then
      printf "\tOK\n"
    else
      printf "\tUNMET\n"
      all_dependencies_met=""
    fi
  done
  if [[ -z "$all_dependencies_met" ]]; then
    printf "Some script dependencies are unmet\nManually install them and rerun the script\n"
    exit
  fi
  printf "All dependencies met!\n"
  sleep 1
}

load_script_variables() {
  script_name=`jq -r '.name' < project.json`
  script_author=`jq -r '.author' < project.json`
  script_version=`jq -r '.version' < project.json`
  script_repository=`jq -r '.repository' < project.json`
  script_description=`jq -r '.description' < project.json`
}

pretty_banner() {
  clear
  cat ascii_art.txt
  printf '=%.0s' {1..80}
  printf "\n"
  tput bold; centre "$script_description"; tput sgr0
  centre "Author: @$script_author | Git repo: $script_repository"
  centre "Script Version: v$script_version"
  printf '=%.0s' {1..80}
  printf "\n"
}

prerun(){
  if [[ $(id -u) != "0" ]]; then
    printf "[ - ] Script needs root privileges; rerun with sudo.\n"
    exit
  fi
}

pre_exit(){
  sudo modprobe -rf v4l2loopback 2> /dev/null
  trap 2
  exit
}

on_user_abort(){
  printf "\n[ - ] user abort\n"
  pre_exit
}

main(){
  pretty_banner
  trap 'on_user_abort' 2

  present_devices=`ls -1 /dev/video* | echo || echo ""`
  header "FAKESTREAM WIZARD"
  video_file=""
  while [[ -z "$video_file" ]]; do
    printf "[ ? ] Absolute path to vidoo file (required): "
    read video_file
    if [[ -z $(file -b --mime-type "$video_file" | grep "video") ]]; then
      printf "\n[ * ] Selected file does not have a valid mime type."
      video_file=""
    else
      break
    fi
  done
  sudo modprobe v4l2loopback card_label="$script_name@$script_version device" exclusive_caps=1 || pre_exit
  new_devices=$(ls -1 /dev/video* || echo "")
  device_enuse=""
  for (( i = 1; i <= $(echo "$new_devices" | grep "" -c); i++ )); do
    device=$(echo "$new_devices" | grep "" -m "$i" | tail -1)
    if [[ -z $(echo "$present_devices" | grep "$device") ]]; then
      device_enuse="$device"
    fi
  done

  if [[ -z "$device_enuse" ]]; then
    printf "[ - ] Loopback could not be created."
    pre_exit
  fi

  printf "[ > ] Looping video file $video_file to device $device_enuse.\n"
  printf "[ > ] Run \`ffplay $device_enuse\` in another terminal to test!\n"
  ffmpeg -hide_banner -loglevel error -stream_loop -1 -re -i "$video_file" -vcodec rawvideo -threads 0 -f v4l2 "$device_enuse" > /dev/null || pre_exit
}

check_requirements
prerun
load_script_variables
main
