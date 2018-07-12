#!/bin/sh
#
# OSUpgrade.sh
# Created by Max Gerhardt on July 5th 2018
#
#   Purpose:    Designed for in-place upgrades, this script checks for Free space,
#               presence of external power, or whether there is over 50% of battery
#               charge left. The script uses "CocoaDialog" to interact with users in
#               the following ways:
#                   1)  If there is insufficient free space, the end user is prompted
#                       to email your internal support address via Argument 4, and then
#                       exits.
#                   2)  If there is below 50% battery charge and it is not connected to
#                       power, then it prompts the end user to connect to power and
#                       launches the macOS Installer app with the GUI (which requires
#                       power to be connected to run)
#               If power is connected and the other checks pass, then it runs the installer
#               silently and reboots as is needed.
#
#               Use Jamf's built in Deferral mechanism to prompt end users for saving their
#               documents before deploying so that they are not interrupted during meetings
#
### Script Arguments ###
#   Arguments 1-3 are reserved by JAMF
#   Argument 4: The best email address to contact IT
#
### Exit Codes ###
#   0: Success
#   1: No installer Present - Should not be within scope, and needs to be pushed via VPP
#   2: Insufficient free space to run installation
#   3: Running on battery with insufficient charge percentage. Opening macOS Installer app instead
#   4: Helpertool Crashed... removing installer and running recon to redownload app from VPP
#   5: Startup Disk could not be verified
#
###############################################################################
#   BootStrap Logging and Basic Requirements
###############################################################################

# Check that we are running as sudo/root
if [[ $(whoami) != "root" ]]; then
    echo "FATAL: Script is not running with root privledges! Please run the script with sudo or as root."
    exit 2
fi

# Enable Logging
    logFile="/var/log/Jamf Initiated 10.13 Upgrade.log"
    log() {
        echo "$1"
        echo "$(date '+%Y-%m-%d %H:%M:%S:' ) $1" >> $logFile
    }
    #Insert a Log Header so each run is easier to tell apart.
    echo "

    *** Logging Enabled Successfully ***
    Script Start Time: $(date)" >> $logFile
    echo "*** Logging Enabled Sucessflly ***"

#####
# Paths to various utilities used for user interaction
#####
CDPath="/Library/Application Support/JAMF/bin/cocoaDialog.app/Contents/MacOS/cocoaDialog"

#####
# Read in Parameters
#####
ITemail="$4"

#####
# Script SpecificVariables
#####
FreeSpace=$(df -H / | tail -1 | awk '{print $4}' | tr -d "G")
PluggedInYN=$(pmset -g ps | grep "Power" | cut -c 18- | tr -d "'")
BatteryPercentage=$(pmset -g ps | tail -1 | awk -F ";" '{print $1}' | awk -F "\t" '{print $2}' | tr -d "%")

###############################################################################
# Check Dependencies
###############################################################################
log "Checking Dependencies..."

#   Cocoa Dialog Installed?   #
if [[ -e "$CDPath" ]]; then
    log "cocoaDialog is Present"
else
    log "cocoaDialog missing - running jamf policy to install"
    jamf policy -event updateJamfBin -verbose >> $logFile
fi

#   Can't install what isn't cached. #
if [[ -e "/Applications/Install macOS High Sierra.app" ]]; then
    log "macOS installer is present"
else
    jamf recon
    log "macOS installer missing and the computer was improperly scoped"
    exit 1
fi

###############################################################################
# Define Functions
###############################################################################

StartInstall ()
{
killall "InstallAssistant"
sleep 5
/Applications/Install\ macOS\ High\ Sierra.app/Contents/Resources/startosinstall --applicationpath /Applications/Install\ macOS\ High\ Sierra.app --agreetolicense  --nointeraction
}

StartInstallGUI ()
{
killall "InstallAssistant"
sleep 5
/Applications/Install\ macOS\ High\ Sierra.app/Contents/MacOS/InstallAssistant
exit 3
}

HelperToolCheck ()
{
if [[ $? -eq 255 ]]; then
    log "exited with status 255, removing the installer, clearing softwareupdate catelog, and running recon"
    rm -Rf "/Applications/Install macOS High Sierra.app"
    softwareupdate --clear-catalog
    jamf recon
    exit 4
else
    log "Installation successful"
    exit 0
    fi
}

###############################################################################
# Main Runtime
###############################################################################

#   Can your startup disk be verified?  #
diskutil verifyVolume /
if [[ $? -eq 0 ]]; then
    log "Starup Disk verified"
else
    "$CDPath" msgbox --title 'Startup Disk Error' \
        --text 'There is something wrong with Macintosh HD' \
        --informative-text "When preparing to run a required update, an error was encountered.

Please email $ITemail for assistance" \
        --button1 " OK " --float --icon stop
    log "Startup Disk could not be verified. Human prompted to request assistance. Installation aborted."
    exit 5
fi


#   Do you have less that 10GB of space?  #
if [ $FreeSpace -lt 10 ]; then
    "$CDPath" msgbox --title 'Low on free space' \
        --text 'Your computer has less than 10GB of free storage.' \
        --informative-text "You have only $FreeSpace GB of space free. MacOS High Sierra requires at least 10 GB of free space available.

If you need help with freeing up space, please email $ITemail" \
        --button1 " OK " --float --icon stop
    log "Not enough storage space"
    exit 2
fi

### are we plugged in? ###
if [ "$PluggedInYN" = "AC Power" ]; then
    log "The computer is plugged into power. Lets start the installation"
    StartInstall
    HelperToolCheck

else
### do we have enough power? ###
    if [ $BatteryPercentage -ge 50 ]; then
    log "laptop over 50% power. Lets start the installation"
    StartInstall
    HelperToolCheck

    else
        "$CDPath" ok-msgbox --title 'Low on Battery Power' \
        --text 'Please plug your computer into power before proceeding' \
        --informative-text "Please plug your laptop in while installing. You only have $BatteryPercentage% power left which may not be enough to complete the installation.

An unexpected loss of power during a macOS upgrade may cause data loss and require assistance from IT." \
        --button1 " OK " --float
        log "The computer needs power to avoid data loss. The human has been prompted to connect power"
        log "Launching Install macOS.app with GUI instead"
        StartInstallGUI

    fi
fi
