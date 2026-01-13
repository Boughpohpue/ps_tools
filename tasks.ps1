$script:Computer = $env:COMPUTERNAME
$script:beepNapLength = 369
$script:mainNapLength = 36963
$script:processesCount = 0
$script:processesHistory = @()

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

function Get-ProcessContainer {
	param (
		[array]$processes
	)

	$processContainer = @()
	foreach ($proc in $processes) {
		if (!$processContainer[$proc.SI]) {
			$processContainer[$proc.SI] = @()
		}
		
		if (!$processContainer[$proc.SI][$proc.UserName]) {
			$processContainer[$proc.SI][$proc.UserName] = @()
		}
		
		if (!$processContainer[$proc.SI][$proc.UserName][$proc.Name]) {
			$processContainer[$proc.SI][$proc.UserName][$proc.Name] = @()
		}
		
		$processContainer[$proc.SI][$proc.UserName][$proc.Name] += $proc
	}
	
	return 
}

function Update-ProcessContainer {
}



function Get-AllProcesses {
	$items = Get-process -IncludeUserName | Select-Object | ForEach-Object {  }
	
	$items = $items | ForEach-Object { $_.UserName = if (!$_.UserName) { '' } else { $_.UserName } } | Select-Object
	
	$processes = $items | 
		Select-Object Id, Name, StartTime, UserName, @{Name='CPU'; Expression={"{0:N0}" -f $_.CPU}}, Handles, SI, @{Name='ParentId'; Expression={$_.Parent.Id}}, @{Name='ParentName'; Expression={$_.Parent.Name}} | 
		Sort-Object SI, UserName, Name, StartTime
	
	return $processes
}

function Print-AllProcesses {
	try {
		$processes = Get-AllProcesses
		$apc = ($processes | Measure-Object).Count
		$header = Generate-Header -counter $apc -headerText "SYSTEM PROCESS" -underlineChar '='
		Write-Output "`r`n$header"	
		if ($apc -gt 0) {			
			$processes | Format-Table -AutoSize -Property @(
				'Id', 
				'Name', 
				'StartTime',
				'UserName',
				'CPU', 
				'Handles', 
				'SI',
				'ParentId',
				'ParentName'
			);
			if ($apc -gt $processesCount) {
				
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
	
	Print-AllProcesses
	
	#Write-Output $(Get-SeparatorLine)
	
	Write-Output $(Get-BorderBottom)
	
	Start-Sleep -Milliseconds $mainNapLength
}
