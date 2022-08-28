ensure_working_directory() {
  wd="$(pwd)"
  required="/usr/home/$(logname)"
  if [ "$wd" != "$required" ]; then
    echo "Running from $wd, must run script from directory $required !"
    exit 1
  fi
}

ensure_root() {
  if [ "$(whoami)" != "root" ]
  then
    echo "ERROR: Must run the bootstrap script as root!"
    echo "Without 'sudo', become root with 'su -'."
    exit
  fi
}

setup_i3_config() {
  echo
  echo -n "Setting up i3 config file with Win modkey and vim-style movement defaults ... "
  cp /usr/local/etc/i3/config .config/i3
  sed -i'' -e 's/# Font for window titles/set $mod Mod4\n\n# Font for window titles/g' .config/i3/config
  sed -i'' -e 's/Mod1/$mod/g' .config/i3/config
  sed -i'' -e 's/set $up l/set $up k/g' .config/i3/config
  sed -i'' -e 's/set $down k/set $down j/g' .config/i3/config
  sed -i'' -e 's/set $left j/set $left h/g' .config/i3/config
  sed -i'' -e 's/set $right semicolon/set $right l/g' .config/i3/config
  sed -i'' -e 's/exec i3-config-wizard//g' .config/i3/config
  sed -i'' -e 's/bindsym $mod+h split h/bindsym $mod+s split h/g' .config/i3/config
  sed -i'' -e 's/bindsym $mod+s layout stacking/bindsym $mod+t layout stacking/g' .config/i3/config
  echo "Note that you can set the font size for status bar and window labels"
  echo "by changing the line 'font pango:monospace 8' ."
  rm .config/i3/config-e
  chown $user:$user /usr/home/$user/.config/i3/config
  echo "Succeeded."
  echo
}
