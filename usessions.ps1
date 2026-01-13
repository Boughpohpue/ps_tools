$script:Computer = $env:COMPUTERNAME
$script:beepNapLength = 369
$script:mainNapLength = 9693
$script:loggedInUsersCount = 1
$script:loggedInUsersHistory = @()
$script:orphanProcessesCount = 0
$script:orphanProcessesHistory = @()
$script:remoteConnectionsCount = 0
$script:remoteConnectionsHistory = @()
$script:usersLogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "_alm_users.log"
$script:processesLogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "_alm_processes.log"
$script:connectionsLogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "_alm_connections.log"


function Beep($times = 1, $nap = $script:beepNapLength) {
	for ($i = 0; $i -lt $times; $i++) {
		[Console]::Beep()
		if ($times -lt $i + 1) {
			Start-Sleep -Milliseconds $nap
		}
	}
}

function Generate-Header {
	param (
		[int]$counter,
		[string]$headerText,
		[char]$underlineChar
	)
	$header = "$counter $headerText"
	if ($counter -ne 1) {
		$header += if ($headerText[-1] -eq 'S') { "ES" } else { "S" }
	}
	$header += ":"
	$underline = ''.PadLeft($header.Length, $underlineChar)
	
	return "$header`r`n$underline"
}
function Get-BorderTop {
	return "`r`n/^~~~------===oOo===***<><> ALASTOR'S EYE <><>***===oOo===------~~~^\`r`n"
}
function Get-BorderBottom {
	return "`r`n\.~~~------===oOo===oOo<><><> VvVvVvVvV <><><>oOo===oOo===------~~~./`r`n`r`n"
}
function Get-SeparatorLine {
	return ">------~~~oOo~~~---===---oOo<>o<&369&>o<>oOo---===---~~~oOo~~~------<`r`n`r`n"
}

function Write-ToLog {
	param (
		[string]$logContent,
		[string]$logFilePath
	)
	
	if (-not $logContent) {
		return "Log content cannot be null or empty."
	}
	if (-not $logFilePath) {
		return "Log file path cannot be null or empty."
	}
	if (-not (Test-Path -Path (Split-Path -Path $logFilePath -Parent))) {
		return "The specified log file path is invalid or the directory does not exist."
	}
	
	$separator = Get-SeparatorLine
	$dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$logEntry = "$dateTime : $logContent`r`n$separator"
	
	Add-Content -Path $logFilePath -Value $logEntry
}
function Log-LoggedInUsers {
    param (
        [array]$items
    )

    function Generate-UserLogText {
        param (
			[string]$action,
            [string]$username,
            [string]$sessionName,
            [int]$id,
            [string]$state,
            [string]$idleTime,
            [datetime]$logonTime
        )

        return "Action: $action, Username: $username, SessionName: $sessionName, ID: $id, State: $state, Idle Time: $idleTime, Logon Time: $logonTime"
    }
	
	if ($items -eq $null -or ($items | Measure-Object).Count -eq 0) {
		return
	}	
	
	if ($items[0].PSObject.Properties.Name -contains 'SideIndicator') {
		foreach ($item in $items) {
			$action = if ($item.SideIndicator -eq '=>') { 'LogIn' } else { 'LogOut' }
			$logEntry = Generate-UserLogText -action $action -username $item.InputObject.USERNAME -sessionName $item.InputObject.SESSIONNAME -id $item.InputObject.ID -state $item.InputObject.STATE -idleTime $item.InputObject.'IDLE TIME' -logonTime $item.InputObject.'LOGON TIME'
			
			Write-ToLog -logContent $logEntry -logFilePath $usersLogFilePath
		}
	}
	elseif ($items[0].PSObject.Properties.Name -contains 'USERNAME') {
		foreach ($connection in $items) {
			$logEntry = Generate-UserLogText -action 'Current' -username $user.USERNAME -sessionName $user.SESSIONNAME -id $user.ID -state $user.STATE -idleTime $user.'IDLE TIME' -logonTime $user.'LOGON TIME'
			
			Write-ToLog -logContent $logEntry -logFilePath $usersLogFilePath
		}	
	}			
}
function Log-RemoteConnections {
    param (
        [array]$items
    )

    function Generate-ConnectionLogText {
        param (
			[string]$action,
            [string]$state,
            [string]$localAddress,
            [int]$localPort,
            [string]$remoteAddress,
            [int]$remotePort,
            [int]$owningProcess,
            [datetime]$creationTime
        )

        return "Action: $action, State: $state, Remote Address: $remoteAddress, Remote Port: $remotePort, Local Port: $localPort, Owning Process: $owningProcess, Creation Time: $creationTime, Local Address: $localAddress"
    }

	if ($items -eq $null -or ($items | Measure-Object).Count -eq 0) {
		return
	}

	if ($items[0].PSObject.Properties.Name -contains 'SideIndicator') {
		foreach ($item in $items) {
			$action = if ($item.SideIndicator -eq '=>') { 'Connect' } else { 'Disconnect' }
			$logEntry = Generate-ConnectionLogText -action $action -state $item.InputObject.State -localAddress $item.InputObject.LocalAddress -localPort $item.InputObject.LocalPort -remoteAddress $item.InputObject.RemoteAddress -remotePort $item.InputObject.RemotePort -owningProcess $item.InputObject.OwningProcess -creationTime $item.InputObject.CreationTime
			
			Write-ToLog -logContent $logEntry -logFilePath $connectionsLogFilePath
		}
	}
	elseif ($items[0].PSObject.Properties.Name -contains 'LocalPort') {
		foreach ($connection in $items) {
			$logEntry = Generate-ConnectionLogText -action 'Active' -state $connection.State -localAddress $connection.LocalAddress -localPort $connection.LocalPort -remoteAddress $connection.RemoteAddress -remotePort $connection.RemotePort -owningProcess $connection.OwningProcess -creationTime $connection.CreationTime
			
			Write-ToLog -logContent $logEntry -logFilePath $connectionsLogFilePath
		}	
	}
}
function Log-OrphanProcesses {
    param (
        [array]$items
    )
	
    function Generate-ProcessLogText {
        param (
            [string]$action,
            [int]$pid,
            [string]$name,
			[datetime]$startTime,
			[int]$sid
        )

        return "Action: $action, PID: $pid, Name: $name, Started: $startTime, SID: $sid"
    }

	if ($items -eq $null -or ($items | Measure-Object).Count -eq 0) {
		return
	}
	
	if ($items[0].PSObject.Properties.Name -contains 'SideIndicator') {
		foreach ($item in $items) {
			$action = if ($item.SideIndicator -eq '=>') { 'Start' } else { 'Exit' }
			$logEntry = Generate-ProcessLogText -action $action -pid $item.InputObject.Id -name $item.InputObject.Name -startTime $item.InputObject.StartTime -sid $item.InputObject.SI 

			Write-ToLog -logContent $logEntry -logFilePath $processesLogFilePath
		}
	}
	elseif ($items[0].PSObject.Properties.Name -contains 'CPU') {
		foreach ($process in $items) {
			$logEntry = Generate-ProcessLogText -action 'Running' -pid $process.Id -name $process.Name -startTime $process.StartTime -sid $process.SI
			
			Write-ToLog -logContent $logEntry -logFilePath $processesLogFilePath
		}	
	}
}
function Append-EntityHistory {
    param (
        [Parameter(Mandatory = $true)]
        [array]$newEntities,
		
        [Parameter(Mandatory = $true)]
        [array]$historyContainer,

        [Parameter(Mandatory = $true)]
        [array]$compareProperties,
		
        [Parameter(Mandatory = $true)]
        [array]$logFilePath,
		
        [Parameter(Mandatory = $true)]
        [scriptblock]$logFunction
    )

    if ($historyContainer.Count -eq 0) {
		& $logFunction -items $newEntities
        $historyContainer += $newEntities
        #return $newEntities
    } 
    else {
        $diff = Compare-Object -ReferenceObject $historyContainer[-1] -DifferenceObject $newEntities -Property $compareProperties
        if ($diff) {
            & $logFunction -items $diff
            $historyContainer += $newEntities
            #return $diff
        }
    }

    #return @()
}

function Get-LoggedInUsers {
    [CmdletBinding()]
    param()

    $rawQuser = quser 2>&1

    if ($LASTEXITCODE -ne 0 -or $rawQuser -match 'not recognized' -or $rawQuser -match 'Access is denied') {
        throw "Failed to retrieve user sessions. Access is denied."
    }
	
	$header = 'USERNAME','SESSIONNAME','ID','STATE','IDLE TIME','LOGON TIME'

    $rawQuser = $rawQuser | Where-Object { $_ -notmatch '^\s*USERNAME' }

    $cleanedUsers = $rawQuser | Where-Object { $_.Trim() -match '\S' } | ForEach-Object {
        ($_ -replace '\s{2,}', ',').Trim() -replace '>', ''
    }

    $cleanedUsers = $cleanedUsers | ConvertFrom-Csv -Header $header | Sort-Object USERNAME, SESSIONNAME
	
	if (($cleanedUsers | Measure-Object).Count -gt 0 -and 
		($script:loggedInUsersHistory | Measure-Object).Count -eq 0) {
		$script:loggedInUsersHistory += $cleanedUsers
	}
	
	return $cleanedUsers		
	
}
function Get-RemoteConnections {
    [CmdletBinding()]
    param()

	$connections = Get-NetTCPConnection -State Established, Listen -LocalAddress 127.0.0.1 | Where-Object {
		$_.RemoteAddress -ne '127.0.0.1' -and $_.RemoteAddress -ne '0.0.0.0'
	}

	if ($connections -eq $null -or $connections.Count -eq 0) {
		return @()
	}

	$connections = $connections | Sort-Object RemoteAddress, LocalPort
	
	if (($connections | Measure-Object).Count -gt 0 -and 
		($script:remoteConnectionsHistory | Measure-Object).Count -eq 0) {
		$script:remoteConnectionsHistory += $connections
	}
	
	return $connections	
}
function Get-OrphanProcesses {
	$items = Get-process -IncludeUserName | Select-Object
	
	$processes = @()
	foreach ($itm in $items) {
		if (!$itm.UserName) {
			$processes += $itm
		}
	}
	
	$processes = $processes | 
		Select-Object Id, Name, StartTime, @{Name='CPU'; Expression={"{0:N0}" -f $_.CPU}}, Handles, SI | 
		Sort-Object -Descending CPU, StartTime
		
	if (($processes | Measure-Object).Count -gt 0 -and 
		($script:orphanProcessesHistory | Measure-Object).Count -eq 0) {
		$script:orphanProcessesHistory += $processes
	}
	
	return $processes
}

function Print-LoggedInUsers {
	try {
		$loggedInUsers = Get-LoggedInUsers
		$luc = ($loggedInUsers | Measure-Object).Count
		$header = Generate-Header -counter $luc -headerText "LOGGED IN USER" -underlineChar '='
		Write-Output $header
		if ($luc -gt 0) {			
			$loggedInUsers | Format-Table -AutoSize -Property @(
				'USERNAME', 
				'SESSIONNAME', 
				'ID', 
				'STATE', 
				'IDLE TIME', 
				'LOGON TIME'
			);
			if ($luc -gt $loggedInUsersCount) {
				Beep(3)
				Append-EntityHistory -newEntities $loggedInUsers -historyContainer $script:loggedInUsersHistory -compareProperties @("USERNAME", "SESSIONNAME") -logFilePath $script:usersLogFilePath -logFunction { Log-LoggedInUsers }
			}
		}
		else {
			Write-Output "`r`nNo logged in users.`r`n`r`n"
		}
		$LoggedInUsersCount = $luc
	}
	catch {
		Write-Warning "`r`nError while retrieving user sessions: $_`r`n`r`n"
	}
}
function Print-RemoteConnections {
	try {
		$remoteConnections = Get-RemoteConnections
		$rcc = ($remoteConnections | Measure-Object).Count
		$header = Generate-Header -counter $rcc -headerText "REMOTE NETWORK CONNECTION" -underlineChar '='
		Write-Output $header
		if ($rcc -gt 0) {		
			$remoteConnections | Format-Table -AutoSize -Property @(
				'State',
				'LocalAddress',
				'LocalPort',
				'RemoteAddress',
				'RemotePort',
				'OwningProcess',
				'CreationTime'
			);
			if ($rcc -gt $remoteConnectionsCount) {
				Beep(3)
				Append-EntityHistory -newEntities $remoteConnections -historyContainer $script:remoteConnectionsHistory -compareProperties @("RemoteAddress", "RemotePort", "LocalPort") -logFilePath $script:connectionsLogFilePath -logFunction { Log-RemoteConnections }
			}
		}
		else {
			Write-Output "`r`nNo connections.`r`n"
		}
		$remoteConnectionsCount = $rcc
	}
	catch {
		Write-Error "`r`nError while retrieving remote connections: $_`r`n"
	}
}
function Print-OrphanProcesses {
	try {
		$orphanProcesses = Get-OrphanProcesses
		$opc = ($orphanProcesses | Measure-Object).Count
		$header = Generate-Header -counter $opc -headerText "ORPHAN PROCESS" -underlineChar '='
		Write-Output "`r`n$header"	
		if ($opc -gt 0) {			
			$orphanProcesses | Format-Table -AutoSize -Property @(
				'Id', 
				'Name', 
				'StartTime', 
				'CPU', 
				'Handles', 
				'SI'
			);
			if ($opc -gt $orphanProcessesCount) {
				Append-EntityHistory -newEntities $orphanProcesses -historyContainer $script:orphanProcessesHistory -compareProperties @("Id", "Name") -logFilePath $script:processesLogFilePath -logFunction { Log-OrphanProcesses }
			}
		}
		else {
			Write-Output "`r`nNo orphan processes.`r`n`r`n"
		}
		$orphanProcessesCount = $opc
	}
	catch {
		Write-Warning "`r`nError while retrieving orphan processes: $_`r`n`r`n"
	}
}


# Main worker loop
while ($true) {
	
	Write-Output $(Get-BorderTop)
	
	Print-OrphanProcesses
	
	Write-Output $(Get-SeparatorLine)

	Print-LoggedInUsers

	Write-Output $(Get-SeparatorLine)
	
	Print-RemoteConnections
	
	Write-Output $(Get-BorderBottom)
	
	Start-Sleep -Milliseconds $mainNapLength
}
