#!/bin/bash
#
# PKG_Install.sh
# 
#       This script is designed as a basic and reusable tool for installing any
#       .pkg from the internet from a static URL. PKG_URL can be set explicitly
#       or by using an assignable parameter from the JSS on a per-policy basis. 
#
#       If using with the JSS, set "Paramenter 4" as "Package URL" in the JSS
#       options tab, and then set that parameter as your package's URL when you
#       set up the policy
#
#       ***THIS SCRIPT ONLY WORKS FOR .pkg INSTALLERS***
#       ***THIS SCRIPT WILL NOT WORK FOR .dmg INSTALLERS***
# 
###############################################################################
#   BootStrap Logging and Basic Requirements
###############################################################################

#####
# Paths to various utilities used for user interaction
#####

PKG_URL="$4"
PKG_PATH="/tmp/pkg.pkg"

# Check that we are running as sudo/root
if [[ $(whoami) != "root" ]]; then
    echo "FATAL: Script is not running with root privledges! Please run the script with sudo or as root."
    exit 2
fi

curl --retry 3 -L "$PKG_URL" -o "$PKG_PATH"
installer -pkg "$PKG_PATH" -target /