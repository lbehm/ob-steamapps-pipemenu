#!/bin/bash

if [ -f ./ob-steamapps-pipemenu.pl ]; then
  echo "File are now copied to: /usr/bin"
  install -o0 -g0 -m755 ./ob-steamapps-pipemenu.pl /usr/bin/ob-steamapps-pipemenu
  echo "Please insert this line into your menu.xml:"
  echo '<menu execute="ob-steamapps-pipemenu" id="pipe-gamesmenu" label="Steam"/>'
else
  echo "Couldn't found File: suspend!"
fi
