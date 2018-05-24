#!/bin/bash
# 
# WhoGoesThere v1.1
# Created by Max Gerhardt on May 24th 2018
# 
# 	Purpose: 	This script relies on CocoaDialog to prompt end users for their name or email address depending on your wording,
# 				and then updates the "username" field within jamf's computer information section. If the email address that is 
# 				submit matches a user in LDAP, it will populate the rest of the relevant fields as well.
#
# 	The LDAP check requires that your JSS's Inventory Collection settings (under "Management") has the preference
# 	enabled to "Collect user and location information from LDAP"
#
###	Exit Codes	###
#	0 = Sucessful, or an otherwise non-blocking error. See the log for details.
#	1 = Generic Error. See the log output for details.
#	2 = Not running as Root (or with Sudo)
#	3 = Variables were missing
### Script Arguments ###
#	Arguments 1-3 are reserved by JAMF
#	Argument 4: Your company's domain address, eg company.com
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
	logFile="/var/log/WhoGoesThere.log"
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
# Read in Parameters
#####
DOMAIN="$4" # Your org's domain, eg company.com

#####
# Paths to various utilities used for user interaction
#####
CDPath="/Library/Application Support/JAMF/bin/cocoaDialog.app/Contents/MacOS/cocoaDialog"

###############################################################################
# Check Dependencies
###############################################################################
log "Checking Dependencies..."

#   Cocoa Dialog Installed?   #
if [[ -e "$CDPath" ]]; then
	log "cocoaDialog is Present"
else
	log "cocoaDialog missing - Calling JAMF to install"
	jamf policy -event updateJamfBin -verbose >> $logFile
fi

# Sanity check varaibles
sanityVariables=("$DOMAIN")
for t in "${sanityVariables[@]}"; do
	if [[ "$t" = "" ]]; then
		log "FATAL: A required script argument is blank. Check the arguments being passed to the script and try again."
		echo "${sanityVariables[@]}"
		exit 3
	fi
done

###############################################################################
# Define Functions
###############################################################################

WhoGoesThere-Prompt-Name() { # Prompt the user for their email address
	ItIsI=$("$CDPath" inputbox --informative-text "Please Enter your work or company Email Address. IT is debating about who your computer is assigned to." \
		--title "Who Goes There?" --button1 "It is I" --float \ | grep $DOMAIN)
}

WhoGoesThere-Prompt-Success() { # Notify the user everything worked
	"$CDPath" msgbox --title 'It is YOU' \
		--text 'Thank You!' \
		--informative-text 'Delighted to make your acquaintence!' \
		--button1 " This was Fun " --float --no-show --icon notice
}

WhoGoesThere() { ### Asks for for identification and thanks them	###

	## Prompt the user for their name
		WhoGoesThere-Prompt-Name

	if [[ $WhoGoesThereResult -eq 0 ]]; then
		log "$ItIsI"
		log "Houston, We've made contact"
	## Tell the user everything worked!
		WhoGoesThere-Prompt-Success
		jamf recon -endUsername "$ItIsI"
		return 0

	else
		## Somthing didn't go right! Return to the Key Check function with a non-zero code after killing CocoaDialog
		killall cocoaDialog
		log "WhoGoesThere Failed!"
		return 1
	fi
}		

###############################################################################
# Main Script Runtime
###############################################################################

WhoGoesThere
