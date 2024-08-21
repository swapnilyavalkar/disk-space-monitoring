# Function to create log file if it doesn't exist
function Create-LogFile {
    param (
        [string]$LogFilePath,
        [string]$LogFile
    )

    if (-not (Test-Path -Path $LogFilePath)) {
        $null | New-Item -Path $LogFilePath -ItemType File
    }

    if (-not (Test-Path -Path $LogFile)) {
        $null | New-Item -Path $LogFile -ItemType File
    }
}

# Function to send email
function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    $From = ""
    $To = ""
    $Cc = ""
    $SMTPServer = ""

    $Message = New-Object System.Net.Mail.MailMessage $From, $To
    $Message.Subject = $Subject
    $Message.Body = $Body
    $Message.IsBodyHTML = $true
    $Message.CC.Add($Cc)

    $SMTP = New-Object Net.Mail.SmtpClient($SMTPServer)
    $SMTP.Send($Message)
}

# Function to send error email
function Send-ErrorEmail {
    param (
        [string]$Server,
        [string]$ErrorMessage,
        [string]$LogFile
    )

    $Subject = "Disk Space Monitoring Alert: Execution Failed on $Server"
    $Body = "An error occurred in the disk space monitoring script on server $Server. Error details:<br><br>$ErrorMessage"

    Send-Email -Subject $Subject -Body $Body
}

# Function to get disk space on a remote server
function Get-RemoteDiskSpace {
    param (
        [string]$Server,
        [string]$Username,
        [string]$Password
    )

    try {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

        $Disks = Invoke-Command -ComputerName $Server -Credential $Credential -ScriptBlock {
            Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and ($_.DeviceID -eq 'C:' -or $_.DeviceID -eq 'D:') } # Mention required server drive names here to monitor. e.g. 'C:' or 'D:'
        }

        $DiskInfo = @{}
        foreach ($Disk in $Disks) {
            $TotalSpace = [math]::Round($Disk.Size / 1GB, 2)
            $FreeSpace = [math]::Round($Disk.FreeSpace / 1GB, 2)
            $UtilizedSpace = $TotalSpace - $FreeSpace
            $PercentFree = [math]::Round(($FreeSpace / $TotalSpace) * 100, 2)

            $DiskInfo[$Disk.DeviceID] = @{
                "TotalSpace(GB)" = $TotalSpace
                "UtilizedSpace(GB)" = $UtilizedSpace
                "FreeSpace(GB)" = $FreeSpace
                "FreeSpacePercentage" = $PercentFree
            }
        }

        return $DiskInfo
    } catch {
        $ErrorMessage = "Error occurred while retrieving disk space information from $Server : $_"
        Send-ErrorEmail -Server $Server -ErrorMessage $ErrorMessage -LogFile $LogFile
        return $null
    }
}

# Function to log error
function Log-Error {
    param (
        [string]$ErrorMessage,
        [string]$LogFile
    )
    Write-Host $LogFile
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$TimeStamp] $ErrorMessage"
}

# Function to delete old log file
function Delete-OldLogFile {
    param (
        [string]$LogFilePath
    )

    $CurrentDate = Get-Date
    $LogFileDate = (Get-Item $LogFilePath).LastWriteTime

    $MonthDifference = ($CurrentDate - $LogFileDate).Days / 30

    if ($MonthDifference -ge 1) {
        Remove-Item -Path $LogFilePath -Force
        Write-Output "Log file deleted successfully as it is older than 1 month."
    } else {
        Write-Output "Log file is not older than 1 month."
    }
}

# Function to delete large log file
function Delete-LargeLogFile {
    param (
        [string]$LogFilePath
    )

    try {
        $LogSize = (Get-Item $LogFilePath).Length / 1MB
        if ($LogSize -gt 10) {
            Remove-Item -Path $LogFilePath -Force
            Write-Output "Log file deleted successfully."
        } else {
            Write-Output "Log file size is within the limit."
        }
    } catch {
        $ErrorMessage = "Error deleting log file: $_"
        Log-Error -ErrorMessage $ErrorMessage -LogFile $LogFile
        Send-ErrorEmail -Server $Server -ErrorMessage $ErrorMessage -LogFile $LogFile
    }
}

# Main function
function Main {
    $LogFilePath = "D:\scripts\disk_space_monitoring\disk_space_monitor.log"
    $LogFile = "D:\scripts\disk_space_monitoring\error.log"  

    Create-LogFile -LogFilePath $LogFilePath -LogFile $LogFile
    Delete-LargeLogFile -LogFilePath $LogFilePath
    Delete-OldLogFile -LogFilePath $LogFile

    # List of remote servers
    $RemoteServers = @("") # Mention hostnames\IP addresses of the servers.
	$Username = "" # Mention the username.
	$Password = "" # Mention the password.

    foreach ($Server in $RemoteServers) {
        try {
            $DiskInfo = Get-RemoteDiskSpace -Server $Server -Username $Username -Password $Password -LogFile $LogFile
			$percentage_to_check = 20 # update % if required
            if ($DiskInfo) {
                foreach ($Drive in $DiskInfo.Keys) {
                    $PercentFree = $DiskInfo[$Drive]["FreeSpacePercentage"]
                    if ($PercentFree -le $percentage_to_check) {
                        $DiskSpaceSubject = "Disk Space Monitoring Alert: $Server"
                        $DiskSpaceBody = @"
                            <html>
                            <body>
                                <p>Disk space information for $Server :</p>
                                <table border='1'>
                                    <tr style='background-color: #0073e6; color: white;'>
                                        <th>Drive</th>
                                        <th>Total Space (GB)</th>
                                        <th>Utilized Space (GB)</th>
                                        <th>Free Space (GB)</th>
                                        <th>Free Space %</th>
                                    </tr>
                                    <tr>
                                        <td>$Drive</td>
                                        <td>$($DiskInfo[$Drive]["TotalSpace(GB)"])</td>
                                        <td>$($DiskInfo[$Drive]["UtilizedSpace(GB)"])</td>
                                        <td>$($DiskInfo[$Drive]["FreeSpace(GB)"])</td>
                                        <td>$($DiskInfo[$Drive]["FreeSpacePercentage"])</td>
                                    </tr>
                                </table>
                            </body>
                            </html>
"@
                        Send-Email -Subject $DiskSpaceSubject -Body $DiskSpaceBody
                    }
                } 
            }
        } catch {
            $ErrorMessage = "Error occurred while processing server $Server : $_"
            Log-Error -ErrorMessage $ErrorMessage -LogFile $LogFile
            Send-ErrorEmail -Server $Server -ErrorMessage $ErrorMessage -LogFile $LogFile
        }
    } 
}
try {
    Main
    } catch {
            $ErrorMessage = "Error occurred while processing server $Server : $_"
            Log-Error -ErrorMessage $ErrorMessage -LogFile $LogFile
            Send-ErrorEmail -Server $Server -ErrorMessage $ErrorMessage -LogFile $LogFile
    }