<#

.NOTES
┌─────────────────────────────────────────────────────────────────────────────────────────────┐ 
│ ORIGIN STORY                                                                                │ 
├─────────────────────────────────────────────────────────────────────────────────────────────┤ 
│   DATE        : 2021.05.07                                                                  |
│   AUTHOR      : TS-Management GmbH, Stefan Müller                                           | 
│   DESCRIPTION : Push Acronis Eentlog entry to PRTG                                          |
└─────────────────────────────────────────────────────────────────────────────────────────────┘
#>

####
# CONFIG START
####
$probeIP = "ADDRESS" # include https or http
$sensorPort = "PORT"
$sensorKey ="KEY"

$numLastEvents = 10
$eventSource = "Acronis Backup and Recovery"

####
# CONFIG END
####


####
# XML Header
####
$prtgresult = @"
<?xml version="1.0" encoding="UTF-8" ?>
<prtg>

"@

function sendPush(){
    Add-Type -AssemblyName system.web

    #write-host "result"-ForegroundColor Green
    #write-host $prtgresult 

    #$Answer = Invoke-WebRequest -Uri $NETXNUA -Method Post -Body $RequestBody -ContentType $ContentType -UseBasicParsing
    $answer = Invoke-WebRequest `
       -method POST `
       -URI ($probeIP + ":" + $sensorPort + "/" + $sensorKey) `
       -ContentType "text/xml" `
       -Body $prtgresult `
       -usebasicparsing

    if ($answer.statuscode -ne 200) {
       write-warning "Request to PRTG failed"
       write-host "answer: " $answer.statuscode
       exit 1
    }
    else {
       $answer.content
    }
}


# Get the Last Event from Log
$events = Get-EventLog -LogName Application -Newest $numLastEvents  -Source $eventSource

$eventsWarn = 0
$eventsInfo = 0
$eventsError = 0
$eventsUnknown = 0

$eventsWarnDates = "Warnings: "
$eventsErrDates = "Errors: "

foreach($event in $events){
    #write-host $event.EntryType
    switch ($event.EntryType){
        "Error"        {$eventsError++
                        $eventsErrDates += $event.TimeGenerated
                        $eventsErrDates += " | "
                       }
        "Information"  {$eventsInfo++}
        "Warning"      {$eventsWarn++
                        $eventsWarnDates += $event.TimeGenerated
                        $eventsWarnDates += " | "
                       }
        Default        {$eventsUnknown++}
    }



}

<#
write-host "Info: " $eventsInfo
write-host "Warn: " $eventsWarn
write-host "Error: " $eventsError
write-host "Unknown: " $eventsUnknown

write-host $eventsWarnDates
write-host $eventsErrDates
#>

$prtgText = ""
if($eventsError -ne 0){$prtgText += $eventsErrDates}
if($eventsWarn -ne 0){$prtgText += $eventsWarnDates}
#write-host $prtgText


####
# XML Content
#### 
$prtgresult += @"
    <result>
        <channel>Information</channel>
        <unit>Custom</unit>
        <value>$eventsInfo</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
    </result>
    <result>
        <channel>Warnings</channel>
        <unit>Custom</unit>
        <value>$eventsWarn</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
        <LimitMaxWarning>2</LimitMaxWarning>
        <LimitWarningMsg>$eventsWarn warnings in the Last $numLastEvents</LimitWarningMsg>
        <LimitMaxError>3</LimitMaxError>
        <LimitErrorMsg>$eventsWarn warnings in the Last $numLastEvents</LimitErrorMsg>
        <LimitMode>1</LimitMode>
    </result>
    <result>
        <channel>Errors</channel>
        <unit>Custom</unit>
        <value>$eventsError</value>
        <showChart>1</showChart>
        <showTable>1</showTable>
        <LimitMaxError>1</LimitMaxError>
        <LimitErrorMsg>$eventsError errors in the last $numLastEvents</LimitErrorMsg>
        <LimitMode>1</LimitMode>
    </result>
    <text>Last $numLastEvents events // $prtgText</text>
</prtg>

"@


#write-host $prtgresult

sendPush

