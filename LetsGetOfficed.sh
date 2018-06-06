#!/bin/bash
#
# Lets_Get_Officed v1.1
# Created by Max Gerhardt on June 5th 2018
#
#	Purpose: 	This script is for both deploying Microsoft Office for macOS, as well as running 
#				Office Suite updates using the CLI compatible version of MAU. If Office is not detected, 
#				it will download and install the suite for you and then exit. If Office is already installed
#				it will run updates via the "msupdate" command included in MAU 3.18 and later. If the installed
#				version of MAU does not support CLI, it will update MAU to the latest CLI support version before 
#				running the updates for the suite. All script based installations come from Microsoft's servers
#				but if the URLs change, this script will break until new url's are added for both MAU and the full suite.
#
###	Exit Codes	###
#	0 = Sucessful, or an otherwise non-blocking error. See the log for details.
#	1 = Generic Error. See the log output for details.
#	2 = Not running as Root (or with Sudo)
#	3 = Office is not Installed
#
### Script Arguments ###
#	Arguments 1-3 are reserved by JAMF 
#
###############################################################################
#	BootStrap Logging and Basic Requirements
###############################################################################
# Check that we are running as sudo/root
if [[ $(whoami) != "root" ]]; then
	echo "FATAL: Script is not running with root privledges! Please run the script with sudo or as root."
	exit 2
fi

# Enable Logging
	logFile="/var/log/MicrosoftUpdaterCLI.log"
	log() {
		echo "$1"
		echo "$(date '+%Y-%m-%d %H:%M:%S:' ) $1" >> $logFile
	}
	#Insert a Log Header so each run is easier to tell apart.
	echo "

	*** Logging Enabled Successfully ***
	Script Start Time: $(date)" >> $logFile
	echo "*** Logging Enabled Sucessflly ***"

###############################################################################
# Setup Global Variables and Process Parameters
###############################################################################
log "Setting up Variables..."

#####
# Paths to various utilities used for user interaction
#####
MAUPath="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
APP_PATH="/Applications/Microsoft Word.app"
MAU_URL="https://go.microsoft.com/fwlink/?linkid=830196"
MSO_URL="https://go.microsoft.com/fwlink/?linkid=525133"
MSO_PATH="/tmp/MSO.pkg"
PKG_PATH="/tmp/MAU4.pkg"
MS_UPDATE="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"

#####
# Variable commands with useful outputs
#####

# Optional method to identify MAU version number, and redirect that output to another Function
# MAU-Version=$(mdls $MAUPath -name kMDItemVersion | grep -Eo '[0-9].[0-99]') 

###############################################################################
# Define Functions
###############################################################################

Install-MS-Office () { #Checks if Microsoft Office is installed, and installs it if not
if [[ -e "$APP_PATH" ]]; then
	log "Microsoft Office is Present"
else
	curl --retry 3 -L "$MSO_URL" -o "$MSO_PATH"
	installer -store -pkg "$MSO_PATH" -target /
	rm "$MSO_PATH"
	log "Microsoft Office has been installed successfully"
	exit
fi
}

MAU-CLI-Check() { #Checks for installed MAU version, and if it is under 3.18, it installs the latest
if [[ -e "$MS_UPDATE" ]]; then
	log "MAU supports CLI"
else
	curl --retry 3 -L "$MAU_URL" -o "$PKG_PATH"
	installer -store -pkg "$PKG_PATH" -target /
	rm "$PKG_PATH"
	log "MAU has been updated to support CLI"
fi
}

Install-MS-Updates() { #Runs available automatic updates for Microsoft Offce
	"$MS_UPDATE" --install
}

###############################################################################
# Main Script Runtime
###############################################################################

Install-MS-Office
MAU-CLI-Check
Install-MS-Updates