#!/bin/sh

. ./common.sh
ensure_working_directory
ensure_root

run_with_prompt() {
  local command="$1"
  echo
  read -p "Execute: '$command' ? " yn
  case $yn in
    [Yy]* ) 
      eval "$command"
      echo && echo "Command '$command' succeeded."
    ;;
    * ) 
      echo "Ok, skipped."
    ;;
  esac
  echo
}

reboot_for_changes() {
  local changes="$1"
  echo
  echo "Reboot needed for $changes to take effect."
  read -p "Would you like to reboot now? " yn
  case $yn in
    [Yy]* ) echo "Rebooting ..." && sleep 3 && shutdown -r now;;
    * ) echo "Ok, proceeding with setup script.";;
  esac
  echo
}

add_line_to_file() {
  local line="$1"
  local filename="$2"
  run_with_prompt "echo '$line' >> $filename"
}

add_line_to_file_if_not_present() {
  local line="$1"
  local filename="$2"
  echo
  echo "Adding line: '$line' to file $filename if not present:"
  if [ -f "$filename" ]; then
    if [ $(grep -c "$line" $filename) -ne 0 ]; then
      echo "Line was already in file, will not add it."
      echo
    else
      echo "File was found but line was not in file."
      echo "Adding the line to the file."
      add_line_to_file "$line" "$filename"
    fi
  else
    echo "File was not found, will add line and chown the file to user $user"
    add_line_to_file "$line" "$filename"
    run_with_prompt "chown $user:$user $filename"
  fi
}

press_enter_to_continue() {
  printf "%s " "Press Enter to continue"
  read ans
}

set_step() {
  local newstep="$1"
  echo "$newstep" > .setup-progress.txt
  step="$newstep"
}

echo
user=$(logname)
read -p "Proceed with setup steps for user $user? " yn
case $yn in
  [Yy]* ) echo "Ok, proceeding.";;
  * ) exit;;
esac
echo

step=" "
if [ -f "./.setup-progress.txt" ]; then
  step=$(cat ./.setup-progress.txt)
  echo "Last completed step: $step"
else
  echo "Had not yet completed any steps."
fi
press_enter_to_continue

run_with_prompt "ping -c 1 pkg.freebsd.org && pkg update && pkg upgrade"

if [ "$step" = " " ]; then 
  echo "Beginning 'videogroup' step."
  echo "Adding user $user to 'video' group for GPU acceleration ..."
  run_with_prompt "pw groupmod video -m $user"
  echo "The 'video' group is now: $(pw groupshow video)"
  press_enter_to_continue
  set_step "videogroup"
else
  echo "Skipping the 'videogroup' step since already completed."
fi 
echo

if [ "$step" = "videogroup" ]; then
  echo "Beginning 'drm-kmod' step."
  echo "Installing the graphics/drm-kmod package."
  run_with_prompt "pkg install drm-kmod"
  set_step "drm-kmod"
else
  echo "Skipping the 'drm-kmod' step since already completed."
fi
echo

if [ "$step" = "drm-kmod" ]; then
  echo "Beginning 'kld_list' step."
  echo "Please confirm system uses Intel Integrated Graphics."
  echo "If your system uses a different GPU type, consult https://wiki.freebsd.org/Graphics to modify this step."
  read -p "Proceed to set kld_list+=i915kms in /etc/rc.conf? " yn
  case $yn in
    [Yy]* ) 
      echo "Ok, proceeding."
      run_with_prompt "sysrc -f /etc/rc.conf kld_list+=i915kms"
      set_step "kld_list"
      reboot_for_changes "update to graphics drivers"
    ;;
    * ) 
      echo "Ok, skipped." && echo
      set_step "kld_list"
    ;;
  esac
else
  echo "Skipping the 'kld_list' step since already completed."
fi
echo

if [ "$step" = "kld_list" ]; then
  echo "Beginning 'console-font' step."
  echo "Setting console font to terminus-b32 in rc.conf."
  run_with_prompt 'sysrc -f /etc/rc.conf allscreens_flags="-f terminus-b32"'
  set_step "console-font"
  reboot_for_changes "new console font"
else
  echo "Skipping the 'console-font' step since already completed."
fi
echo

if [ "$step" = "console-font" ]; then
  echo "Beginning 'xorg' step."
  run_with_prompt "pkg install xorg"
  echo "Appending 'kern.vty=vt' to /boot/loader.conf to enable vt"
  add_line_to_file_if_not_present "kern.vty=vt" "/boot/loader.conf"
  set_step "xorg"
else
  echo "Skipping the 'xorg' step since already completed."
fi
echo

if [ "$step" = "xorg" ]; then 
  echo "Beginning 'fonts' step."
  run_with_prompt "pkg install urwfonts"
  press_enter_to_continue
  run_with_prompt "pkg install freefont-ttf"
  press_enter_to_continue
  run_with_prompt "pkg install nerd-fonts"
  press_enter_to_continue
  echo 'Checking for line: Load "freetype" in "Module" section of /etc/X11/xorg.conf'
  if [ -f "/etc/X11/xorg.conf" ]; then
    if [ $(grep -c 'Load "freetype"' /etc/X11/xorg.conf) -ne 0 ]; then
      echo "Line was already in file, will not add it."
      echo
    else
      echo "File was found but line was not in file."
      echo "Please add the line:"
      echo
      echo '	Load "freetype"'
      echo
      echo "to the section:"
      echo
      echo 'Section "Module"'
      echo "..."
      echo "EndSection"
      echo
      echo "of /etc/X11/xorg.conf (create the section if necessary)"
      echo "and resume this script."
      echo 
      printf "%s " "Press Enter to exit"
      read ans
      exit
    fi
  else
    echo -n "File was not found, adding section to file ... "
    echo 'Section "Module"' >> /etc/X11/xorg.conf
    echo '	Load "freetype"' >> /etc/X11/xorg.conf
    echo "EndSection" >> /etc/X11/xorg.conf
    echo "Finished."
  fi
  run_with_prompt "pkg install mkfontscale"
  if [ ! -f ".xinitrc" ]; then
    echo ".xinitrc file did not exist, will copy it from template and chown to $user:$user"
    run_with_prompt "cp setup-files/xinitrc-template .xinitrc && chown $user:$user .xinitrc"
  fi

  for font_dir in $(find /usr/local/share/fonts -maxdepth 1 -mindepth 1)
  do
    run_with_prompt "cd $font_dir && mkfontscale && mkfontdir && cd /usr/home/$user"
    add_line_to_file_if_not_present "xset fp+ $font_dir" ".xinitrc"
  done
  add_line_to_file_if_not_present "xset fp rehash" ".xinitrc"
  run_with_prompt "pkg install xlsfonts"
  run_with_prompt "fc-cache -f"
  set_step "fonts"
else
  echo "Skipping the 'fonts' step since already completed."
fi
echo

if [ "$step" = "fonts" ]; then
  echo "Beginning 'monospace' step."
  echo "Choose a font family from 'fc-list' for monospace"
  read -p "Enter the filename portion for monospace font family (e.g. 'roboto-mono'): " mono_filename
  indexed_mono_filename="54-$mono_filename.conf"
  new_mono_avail_filename="/usr/local/etc/fonts/conf.avail/$indexed_mono_filename"
  run_with_prompt "cp setup-files/54-font-family.conf $new_mono_avail_filename"
  read -p "Enter the font family name as listed in fc-list (e.g. 'Roboto Mono'): " font_family
  echo "Editing the $new_mono_avail_filename file to point to font family $font_family:"
  run_with_prompt "sed -i'' -e 's/fontfamily/$font_family/g' $new_mono_avail_filename && rm $new_mono_avail_filename-e"
  echo "Symlinking $new_mono_avail_filename to be pointed to by ../conf.d/$indexed_mono_filename"
  run_with_prompt "cd /usr/local/etc/fonts/conf.d && ln -s ../conf.avail/$indexed_mono_filename $indexed_mono_filename && cd /usr/home/$user"
  echo "If symlink was successful it should appear below,"
  echo "and have higher priority (lower index) than other mono files:"
  echo
  ls -l /usr/local/etc/fonts/conf.d | grep mono
  echo
  run_with_prompt "fc-cache -f"
  echo "The monospace font is now: $(fc-match monospace)"
  echo
  set_step "monospace"
else
  echo "Skipping the 'monospace' step since already completed."
fi
echo  

if [ "$step" = "monospace" ]; then
  echo "Beginning 'configure-x-console' step."
  run_with_prompt "pkg install rxvt-unicode urxvt-font-size urxvt-perls"
  echo "Configuring shell autostart script to export urxvt as the default terminal."
  read -p "What is your shell autostart script filename (e.g. '.shrc')? " autostart_filename
  if [ -f "$autostart_filename" ]; then
    echo "Found autostart script at $autostart_filename."
    if [ $(grep -c 'export TERMINAL' $autostart_filename) -ne 0 ]; then
      echo "Found TERMINAL export was already in file, will not add it."
    else
      echo "Adding lines to export TERM and TERMINAL environment variables."
      add_line_to_file '
# use 256 color xterm
export TERM="xterm-256color"
# set urxvt as default terminal
export TERMINAL="/usr/local/bin/urxvtc"' "$autostart_filename"
    fi
  else
    echo "Could not find shell autostart script at $autostart_filename !"
    echo "Please configure shell correctly, check filename and rerun this setup script."
    printf "%s " "Press Enter to exit"
    read ans
    exit 1
  fi
  echo "Adding line to start urxvtd daemon on x startup"
  add_line_to_file_if_not_present "urxvtd -q -o -f" ".xinitrc"
  echo "Copying Xresources setup file to ~/.Xresources"
  echo "Note! Some defaults in this file may need to be adjusted."
  echo "To find the correct DPI for the file, start an X session"
  echo "with 'startx' and run 'xdpyinfo | grep -B2 resolution'"
  run_with_prompt "cp setup-files/Xresources .Xresources && chown $user:$user .Xresources"
  set_step "configure-x-console"
  echo
else
  echo "Skipping the 'configure-x-console' step since already completed."
fi
echo

if [ "$step" = "configure-x-console" ]; then
  echo "Beginning 'i3wm' step."
  echo "Installing i3wm and dmenu."
  run_with_prompt "pkg install -y i3 i3lock i3status"
  run_with_prompt "pkg install dmenu"
  add_line_to_file_if_not_present "/usr/local/bin/i3" ".xinitrc"
  setup_i3_config
  echo "The contents of .xinitrc are now:"
  echo
  cat .xinitrc    
  echo
  press_enter_to_continue
  echo "i3wm and dmenu have now been installed!"
  echo "Start i3wm with 'startx' after reboot to ensure config was successful."
  set_step "i3wm"
else
  echo "Skipping the 'i3wm' step since already completed."
fi
echo

if [ "$step" = "i3wm" ]; then
  echo "Beginning 'essential-progs' step."
  echo "Installing rsync."
  run_with_prompt "pkg install rsync"
else
  echo "Skipping the 'essential-progs' step since already completed."
fi
echo
