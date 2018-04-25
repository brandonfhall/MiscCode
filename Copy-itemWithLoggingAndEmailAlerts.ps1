#requires -version 4.0
#file copier with email notificaions and logging
#Author: Brandon Hall 06/28/2017
#Version 1.0 

#CMDLet Binding
[CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,Position=0,HelpMessage='Please enter the folder path you would like to copy')]
    $Source,
    [Parameter(Mandatory=$true,Position=1,HelpMessage='Please enter the folder path you would like to copy the source to')]
    $Destination,
    [Parameter(Mandatory=$true,Position=2,HelpMessage='Please a Name for the copy Job. This will be used as the subject of the alert emails')]
    $JobName,
    [Parameter(Mandatory=$false,HelpMessage='Sends Email if specfied.')]
    [switch]$SendEmail,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the email address you would like alerts to come from. Will default to the computer name the script is running on.')]
    $EmailFrom = ($env:COMPUTERNAME + "@thadmin.com"),
    [Parameter(Mandatory=$false,HelpMessage='Please enter the Emails you would like to notify when the job runs and finishes.')]
    [array]$EmailTo,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the SMTP server you would like to use. Will default to tasha.thadmin.com')]
    $SMTPServer = "tasha.thadmin.com",
    [Parameter(Mandatory=$false,HelpMessage='Please Enter the Directory to log to. If not entered it will log to the same directory as the script')]
    $LogDir = ($PSScriptRoot + "\logs")
)

Function Send-Email {
    [CmdletBinding()]
     param (
       [Parameter(Mandatory=$true,Position=0,HelpMessage='Please enter the body of the email you would like to send. Accepts HTML email')]
       $EmailBody
     )

    If ($SendEmail) {
        
        Try {

            Send-MailMessage -To $EmailTo -From $EmailFrom -Subject $JobName -SmtpServer $SMTPServer -BodyAsHtml $EmailBody -ErrorAction Stop

            $Step = "Email Notificaion"
            $Info = "Email sent to $EmailTo"
            LogTo-CSV -Step $Step -Info $Info

        } Catch {
            
            $Step = "Email Notificaion Error"
            $Info = "Error Sending Email please verify Addresses and SMTP server"
            LogTo-CSV -Step $Step -Info $Info

        }
    }
}


Function LogTo-CSV {

    [CmdletBinding()]
     param (
       [Parameter(Mandatory=$true,Position=0,HelpMessage='Please enter the Step name for logging')]
       $Step,
       [Parameter(Mandatory=$true,Position=0,HelpMessage='Please enter the Info of the current stap, this will be logged an emailed')]
       $Info
    )

    #Builting a PSObject for each #User in $Users that contains the values we care about. 
    $TempExport = New-Object PSObject
    $TempExport | Add-Member -MemberType NoteProperty -Name "Date" -Value (Get-Date -Format yyyy-MM-ddTHH:mm:ss) 
    $TempExport | Add-Member -MemberType NoteProperty -Name "JobName" -Value $JobName
    $TempExport | Add-Member -MemberType NoteProperty -Name "Source" -Value $Source
    $TempExport | Add-Member -MemberType NoteProperty -Name "Destination" -Value $Destination
    $TempExport | Add-Member -MemberType NoteProperty -Name "Step" -Value $Step
    $TempExport | Add-Member -MemberType NoteProperty -Name "Info" -Value $Info


    #Exports the PSObject from above to a CSV file.
    Try {
        
        Export-Csv -InputObject $TempExport -Path ($LogDir + "\" +(get-date -Format yyyy-MM-dd)+ "-runlog.csv") -Append -NoTypeInformation
    
    } Catch [FileOpenFailure,Microsoft.PowerShell.Commands.ExportCsvCommand] {

        Write-Host "Could not open log file. Please verify that it is not open else where"
        
        #Sending Alert email if possilbe
        $Info = "Could not open log file. Please verify that its not open else where" 
        $Step = "Error opening log file"
        Send-Email -Info $Info -Step  $Step

    } Catch {
        
        $Info = "Could not write to log file. Please investigate. " 
        $Step = "Error writing log file"
        Send-Email -Info $Info -Step  $Step

    }
}
        

Write-Verbose "Checking that Logging Directory at $LogDir exists" 
If (!(Test-Path -Path $LogDir)) {
    
    Write-Verbose "Attempting to create $LogDir" 
    New-Item -ItemType Directory -Path $LogDir
    LogTo-CSV -Step "Creating Log Directory" -Info "$LogDir did not exist and was created"

} else {

    Write-Verbose "$LogDir Exists" 
}

Write-Verbose "Sending start email"
$Step = "Initilizing"
$Info = "Starting the copy job from """" $Source """" to """" $Destination """" a follow up email will be sent once finshed"
LogTo-CSV -Info $Info -Step $Step 
Send-Email -EmailBody $Info 


#Tests that the source and destination are reachable. If not send an email and close the script. 

If (!(Test-Path -Path $Source)) { 
    
    Write-Verbose "checking for the Source path."
    $Step = "Testing Source Path"
    $Info = "The source file location at """" $Source """" was not reachable. The copy job has been terminated"
    LogTo-CSV -Info $Info -Step $Step 
    Send-Email -EmailBody $Info  
    exit

}

Write-Verbose "Starting copy"
LogTo-CSV -Info "Starting Copy operation" -Step "Starting Copy"
#Try catch satement for future error handeling. Right now it just runs the copy and sends an email if it completes or catches all errors and sends an error email 
Try {

    Copy-Item -Path $Source -Destination $Destination -Recurse -Verbose -ErrorVariable CopyErrors -ErrorAction Stop

} Catch {
    #catches any unhandled exceptions and sends an email saying it broke with the error
    Write-Verbose "copy has encounted errors sending error email"
    $Step = "Error Log"
    $Info = "The copy job from """" $Source """" to """" $Destination """" has encounted an error. <br> Error: <hr> $CopyErrors[0]"
    LogTo-CSV -Info $Info -Step $Step
    LogTo-CSV -Info $CopyErrors -Step $Step
    Send-Email -EmailBody $Info  
    exit

}

#assuming nothing broke send an email saying it worked, or at least it didn't break in a way we thought of.
Write-Verbose "copy has finshed sending completion email"
$Step = "Finished"
$Info = "The copy job from """" $Source """" to """" $Destination """" has finshed."
LogTo-CSV -Info $Info -Step $Step 
Send-Email -EmailBody $Info