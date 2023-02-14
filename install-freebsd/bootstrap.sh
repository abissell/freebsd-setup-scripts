#!/bin/sh

. ./common.sh
ensure_working_directory "/usr/home/$(logname)"
ensure_root

echo
echo "Pinging pkg.freebsd.org"
ping -c 1 pkg.freebsd.org
echo "Updating pkg ..."
pkg update -f
echo "... updating pkg succeeded."
echo
echo "Installing sudo ..."
pkg install sudo
echo "... installing sudo succeeded."
echo
echo "While still root, run 'visudo'"
echo "and uncomment the line:"
echo "# %wheel ALL=(ALL) ALL"
echo
echo "Once done, initial bootstrap is complete!"
echo
