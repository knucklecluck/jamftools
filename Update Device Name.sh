#!/bin/bash
#
#   Script to identify "First Name" and Serial Number values,
#   and then combine both to set as the computer's hostname
#
#   eg. "John-C02XXXXXF6T6"
#
#   Needs to be run as root :)

FName="$(id -P $(stat -f%Su /dev/console) | awk -F '[: ]' '{print $8}')-"
Serial=$(system_profiler SPHardwareDataType | sed '/^ *Serial Number (system):*/!d;s###;s/ //')

scutil --set HostName "$FName$Serial"
scutil --set LocalHostName "$FName$Serial"
scutil --set ComputerName "$FName$Serial"
dscacheutil -flushcache