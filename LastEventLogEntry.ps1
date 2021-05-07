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
$probeIP = "ADDRESS"
$sensorPort = "PORT"
$sensorKey ="KEY"

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

    write-host "result"-ForegroundColor Green
    write-host $prtgresult 

    #$Answer = Invoke-WebRequest -Uri $NETXNUA -Method Post -Body $RequestBody -ContentType $ContentType -UseBasicParsing
    $answer = Invoke-WebRequest `
       -method POST `
       -URI ("http://" + $probeIP + ":" + $sensorPort + "/" + $sensorKey) `
       -ContentType "text/xml" `
       -Body $prtgresult `
       -usebasicparsing

       #-Body ("content="+[System.Web.HttpUtility]::UrlEncode.($prtgresult)) `
    #http://prtg.ts-man.ch:5055/637D334C-DCD5-49E3-94CA-CE12ABB184C3?content=<prtg><result><channel>MyChannel</channel><value>10</value></result><text>this%20is%20a%20message</text></prtg>   
    if ($answer.statuscode -ne 200) {
       write-warning "Request to PRTG failed"
       write-host "answer: " $answer.statuscode
       exit 1
    }
    else {
       $answer.content
    }
}

write-host $env:COMPUTERNAME

# Get the Last Event from Log
$event = Get-EventLog -LogName Application -Newest 1 -Source $eventSource

switch ($event.EntryType){
    "Error"         {$eventType = 1}
    "Information"   {$eventType = 2}
    "Warning"       {$ecentType = 3}
    "FailureAudit"  {$eventType = 4}
    "SuccessAudit"  {$eventType = 5}
    Default         {$eventType = 0}
}


#$eventType = $event.EntryType
$eventTimeGenerated = $event.TimeGenerated
write-host $eventType
write-host $eventTimeGenerated

# Get the relvant info
$strings = $event.ReplacementStrings -Split("\n")
$eventReplacementStrings = $event.ReplacementStrings

$task = $strings[1] -Split"'"
$taskType = $task[1]
$taskState = $task[2].trimStart(" ")

write-host $taskType
write-host $taskState 

####
# XML Content
#### 
$prtgresult += @"
    <result>
        <channel>Event Type</channel>
        <unit>Custom</unit>
        <value>$eventType</value>
        <showChart>1</showChart>
        <showTable>1</showTable
    </result>
    <text>$eventTimeGenerated</text>
</prtg>

"@


write-host $prtgresult

sendPush

