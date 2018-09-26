#!/bin/bash
#
# EA FV2 Status.sh
#
#   This extermely basic EA just outright checks FV status via the fdesetup command
#   since some of Jamf's built in statuses do not account for T2 chip security.
#   Subsequently, some Jamf versions will think that T2 based computers are already
#   encrypted, even though FileVault is disabled. 
#
#   It doesn't hurt to double check ¯\_(ツ)_/¯ 

FV2=$(fdesetup status)
echo "<result>$FV2</result>"
