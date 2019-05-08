#!/bin/bash

#!/bin/bash
#
# Identify Chrome Profile.sh
# Created by Max Gerhardt
#
#       This script checks the Chrome's Preference file for the signed-in account
#       and then uses that value to update the computer's "user and location" data
#       in a Jamf environment. 
#       
#       This is particularly useful when using an LDAP interface within Jamf when 
#       LDAP users are set as email addresses.
#
#       This script is confirmed to work in macOS 10.13+ and Google Chrome v70+ 
#       but relies on the end user using the profile feature. This is likely very
#       version dependent so always test before putting into production.
# 
###############################################################################
#   Basic Requirements
###############################################################################

# Check that we are running as sudo/root
if [[ $(whoami) != "root" ]]; then
    echo "FATAL: Script is not running with root privledges! Please run the script with sudo or as root."
    exit 2
fi

#####
# Script SpecificVariables
#####

userName="$(/usr/bin/stat -f%Su /dev/console)"
emailAddy=$(cat /Users/"$userName"/Library/Application\ Support/Google/Chrome/Default/Preferences | awk -F '[" ]' '{print $12}')


###############################################################################
# Main Runtime
###############################################################################

if [[ ${emailAddy} == *"@[YOURDOMAIN].com ]] ;
then 
    jamf recon -endUsername "$emailAddy"
    echo $emailAddy
    exit 0
else
    echo "Work Email Not Registered with Chrome"
    exit 1
fi