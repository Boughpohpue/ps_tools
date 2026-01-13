# Set the path to the Veracrypt volume
$volumePath = "C:\Path\To\Volume.vcx"
$mountedLetter = "O:"
$usbDriveLetters = "DEFGH"
$passwordFileName = "pwd.txt"

# Function to get the password from the USB drive
function Get-VaultPassword {
	
	$password = ""
	while ($password -eq "") {
		foreach ($letter in $usbDriveLetters) {
			$passwordFilePath = "$($letter):\$($passwordFileName)"
			if (Test-Path -Path $passwordFilePath) {
				Write-Host "Password file found!"	
				$password = Get-Content -Path $passwordFilePath
				break
			}
		}
		
		if ($password -eq "") {
			Write-Host "Waiting for USB drive with password file..."
			Start-Sleep -Seconds 3
		}
	}
	
	return $password
}

# Set the list of authorized apps
$authorizedApps = @("chrome.exe", "brave.exe", "totalcmd.exe", "irfanview.exe")

# Function to mount the Veracrypt volume
function Mount-EncryptedVolume {
    $password = Get-VaultPassword
    Start-Process -FilePath "veracrypt.exe" -ArgumentList "/mount $volumePath C: /p $password /q"
}

# Function to unmount the Veracrypt volume
function Unmount-EncryptedVolume {
    Start-Process -FilePath "veracrypt.exe" -ArgumentList "/d C: /q"
}

# Monitor running processes and mount/unmount the volume
while ($true) {
    # Check if any of the authorized apps are running
    $runningApps = Get-Process -Name $authorizedApps -ErrorAction SilentlyContinue
    if ($runningApps.Count -gt 0) {
        # Mount the volume if it's not already mounted
        if (!(Test-Path "C:\")) {
            Mount-EncryptedVolume
        }
    }
    else {
        # Unmount the volume if no authorized apps are running
        if (Test-Path "C:\") {
            Unmount-EncryptedVolume
        }
    }

    # Wait for 5 seconds before checking again
    Start-Sleep -Seconds 3
}