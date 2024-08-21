---

# Disk Space Monitoring Script

This PowerShell script monitors disk space on remote servers and sends email alerts when disk space is low. The script also manages log files by deleting old or large log files automatically.

## Prerequisites

Before using this script, ensure you have the following:

- **PowerShell**: The script is written in PowerShell, so you need to have PowerShell execution rights on the machine where the script will be executed.
- **SMTP Server Details**: To send email notifications.
- **Remote Server Access**: Credentials for the servers you want to monitor.

## How to Use the Script

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/swapnilyavalkar/Disk-Space-Monitoring.git
cd Disk-Space-Monitoring
```

### 2. Open the Script

Open the `disk-space-monitoring.ps1` script in your preferred text editor or PowerShell IDE.

### 3. Configure the Script

Update the following variables within the script:

- **$LogFilePath**: Path for the main log file.
- **$LogFile**: Path for the error log file.
- **$RemoteServers**: List of remote servers to monitor.
- **$Username**: Username for remote server access.
- **$Password**: Password for remote server access.
- **$SMTPServer**: Specify the SMTP server address.
- **$From**: Define the sender's email address.
- **$To**: Define recipient email addresses.
- **$Cc**: (Optional) Specify any CC recipients.
- **$percentage_to_check**: Update % if required.

### 4. Run the Script

Run the script using PowerShell:

```powershell
.\disk-space-monitoring.ps1
```

### 5. Schedule the Script Using Task Scheduler

To automate the script execution, you can schedule it using Windows Task Scheduler.

#### Steps to Schedule:

1. **Open Task Scheduler**:
   - Search for "Task Scheduler" in the Windows Start menu and open it.

2. **Create a New Task**:
   - Click on **"Create Task..."** from the right-hand Actions pane.

3. **General Tab**:
   - **Name**: Give the task a meaningful name, e.g., "Disk Space Monitoring."
   - **Description**: Add a description if needed.
   - **Security Options**: Choose "Run whether user is logged on or not" and check "Run with highest privileges."

4. **Triggers Tab**:
   - Click **"New..."** to create a new trigger.
   - **Begin the task**: Choose "On a schedule."
   - **Settings**: Set the desired schedule (e.g., daily, weekly).
   - **Advanced settings**: Configure any additional settings like repeat intervals or delays if necessary.

5. **Actions Tab**:
   - Click **"New..."** to create a new action.
   - **Action**: Select "Start a Program."
   - **Program/script**: Enter `powershell.exe`.
   - **Add arguments (optional)**: Enter the path to your script:
     ```plaintext
     -ExecutionPolicy Bypass -File "C:\path\to\disk-space-monitoring.ps1"
     ```

6. **Conditions Tab**:
   - Configure any conditions like only running on AC power or network availability if required.

7. **Settings Tab**:
   - Configure additional settings such as allowing the task to run on demand or stopping it if it runs for too long.

8. **Save the Task**:
   - Click **"OK"** to save the task. If prompted, enter your Windows credentials.

### 6. Check Email Alerts

If any disks on the monitored servers fall below N% free space, an email alert will be sent to the specified recipients with detailed information as shown in below screenshot.

![image](https://github.com/user-attachments/assets/b21ca1cf-0f37-4d01-8a81-cbfea87de8af)


## Script Workflow

1. **Log File Management**: The script checks and manages the size and age of log files, deleting them if necessary.
2. **Disk Space Retrieval**: The script connects to each specified server and retrieves disk space information.
3. **Alert Trigger**: If any disk has less than N% free space, an email alert is triggered.
4. **Error Handling**: Errors are logged, and an error email is sent if the script encounters issues.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contributions

Contributions are welcome! Please fork this repository and submit a pull request with your changes.

---
