#!/bin/bash
#
# EA SSID Presence.sh
# Created by Max Gerhardt on September 18th, 2018
#
#   This script is designed as an extension attribute (EA) to check 
#   for an SSID of your preference and then tell the JSS whether the
#   SSID is presnet. This can be used for grouping device at your org
#   if you are needing to remove an undesired network for org owned
#   devices
#
#   ***Change "GUEST SSID" below with the SSID you are needing to check for***

# What SSID are we checking for?
GuiltySSID="Guest SSID"

# Identify Wifi's Interface ID (eg en0 vs en1 etc)
WiFiInterface=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')

# Collect preferred wireless SSIDs and send back to the JSS
ExistingNetworks=$(networksetup -listpreferredwirelessnetworks "$WifiInterface" | grep "$GuiltySSID" | cut -c 2-16)

if [ "$ExistingNetworks" = "$GuiltySSID" ]
then
    echo "<result>Has Guest SSID</result>"
else
    echo "<result>Not Present</result>"
fi