# PRTG-PushWindowsEventLog
*This project is as it is*

## Description
Sends Eventlog entries to a PRTG Push Sensor

## Install
- Create a PRTG-Push Sensor Advanced
- Copy the Powershell-Script to the Source-Machine
- Edit probeIP, sensorPort, sensorKey, eventSource, and numLastEvents (LastXEventLogEntries.ps1 only)
- Create a Scheduled Task which is run an entry with the same eventSource as in Script is created