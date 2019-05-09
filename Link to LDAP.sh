#!/bin/bash
#
# Link to LDAP.sh
# Created by Max Gerhardt on May 8th, 2019
#
#       This script uses the local user's full name to guess the end user's work 
#       email address, and then uses that value to update the computer's "user
#       and location" data within Jamf. If the Local User's "Full Name" doesn't
#       include a last name, this script checks the Chrome Profile instead before
#       assuming "firstname@company.com"
#       
#       This is particularly useful when using an LDAP interface within Jamf when 
#       LDAP users are set as email addresses, and if Chrome is the standard browser
#       for your company. Additonally, the standard email format is set as 
#       first.last@company.com, so any deviation will need to be adjusted.
#
#       The Chrome component of this script is confirmed to work in macOS 10.13+
#       and Google Chrome v70+. This component is likely very version dependent
#       so always test before putting into production.
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

firstName=$(id -P $(stat -f%Su /dev/console) | awk -F '[: ]' '{print $8}' | tr '[:upper:]' '[:lower:]')
lastName=$(id -P $(stat -f%Su /dev/console) | awk -F '[: ]' '{print $9}' | tr '[:upper:]' '[:lower:]')
userName="$(/usr/bin/stat -f%Su /dev/console)"
chromeEmail=$(cat /Users/"$userName"/Library/Application\ Support/Google/Chrome/Default/Preferences | awk -F '[" ]' '{print $12}')

###############################################################################
# Main Runtime
###############################################################################

if [[ ${lastName} == "/users/"* ]] ;
then
    if [[ ${chromeEmail} == *"@[YOURDOMAIN].com" ]] ;
    then 
        jamf recon -endUsername "$chromeEmail"
        echo "$chromeEmail"
        exit 0
    else
        jamf recon -endUsername "$firstName@instacart.com"
        echo "$firstName@instacart.com"
        exit 0
    fi
else
    jamf recon -endUsername "$firstName.$lastName@instacart.com"
    echo "$firstName.$lastName@instacart.com"
    exit 0
fi