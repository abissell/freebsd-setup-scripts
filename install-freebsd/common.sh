ensure_working_directory() {
  local wd="$(pwd)"
  local required="$1"
  if [ "$wd" != "$required" ]; then
    echo "Running from $wd, must run script from directory $required !"
    exit 1
  fi
}

ensure_root() {
  if [ "$(whoami)" != "root" ]; then
    echo "ERROR: Must run this script as root!"
    echo "Without 'sudo', become root with 'su -'."
    exit 1
  fi
}

prompt() {
  read -p "$1 " yn
  case $yn in
    [Yy]* )
      return 0
    ;;
    * )
      return 1
    ;;
  esac
  exit 1
}

run_with_prompt() {
  local command="$1"
  echo
  if prompt "Execute: '$command' ?"; then
    eval "$command"
    echo && echo "Command '$command' succeeded."
    return 0
  else
    echo "Ok, skipped."
    return 1
  fi
}

press_enter_to_continue() {
  printf "%s " "Press Enter to continue"
  read ans
}
