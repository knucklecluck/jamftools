#!/bin/bash
#
#   Script to identify "First Name" and Serial Number values,
#   and then combine both to set as the computer's name and hostname
#
#   eg. "John-C02XXXXXF6T6"
#
#   Needs to be run as root :)

FirstName="$(id -P $(stat -f%Su /dev/console) | awk -F '[: ]' '{print $8}')-"
Serial=$(system_profiler SPHardwareDataType | sed '/^ *Serial Number (system):*/!d;s###;s/ //')

scutil --set HostName "$FirstName$Serial"
scutil --set LocalHostName "$FirstName$Serial"
scutil --set ComputerName "$FirstName$Serial"
dscacheutil -flushcache