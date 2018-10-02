#!/bin/sh
#
# RemoveSSID.sh
# Created by Max Gerhardt on Octover 1st, 2018
#
#   This script confirms what network interface your computer has for its AirPort card and then
#   removes a "Guilty SSID" of your choosing. This is best scoped to a smart group that is bound
#   to an extension attribute that is checking for a particular SSID's presence.
#
#   Running this will not cause the computer to disassociate from the network, but rather, when
#   the computer attempts to connect to the network next, it will no longer default to the SSID
#   that you've removed.


# Identify Wifi's Interface ID (eg en0 vs en1 etc)
WiFiInterface=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')

# Run a SSID removal
networksetup -removepreferredwirelessnetwork $WiFiInterface "Guilty SSID"