# Battery info
$sleepLength = 10000
$secondsInMinute = 60
$secondsInHour = 60 * 60
$secondsInDay = 24 * 3600

function Convert-BoolToString {
	param([bool]$boolValue)
	
	if ($boolValue) { return "YES" }
	else { return "NO" }
}

function Convert-MinutesToTimeString {
	param([int]$minutes)
	
	$hrs = 0
	$mnts = $minutes
	while ($mnts -ge 60) {
		$hrs += 1
		$mnts -= 60
	}
	
	$timeString = ""
	if ($hrs -ge 1) { $timeString += "$($hrs)h " }
	$timeString += "$($mnts)m"
	
	return $timeString
}

function Convert-TimeStringToDateTime {
	param([string]$ts)
	try {
		$ts = 
		$tsParts = ($ts -replace '~', '').split(" ")
		foreach ($tsp in $tsParts) {
			
		}
	}
	catch {
		return $null
	}
}

function Convert-MinutesToDateTimeString {
	param([int]$minutes)
	
	$dt = ([datetime]::Now).AddMinutes($minutes)
	$retval = "{0:hh\:mm}" -f $dt
	return $retval
}

function Get-EstimatedTimeLeftString {
	param([int]$full, [int]$current, [int]$rate)
	
	if ($current -ge $full) {
		return "FULL"
	}
	if ($rate -le 0) {
		return "N/A"
	}
	
	$est = ""
	$days = 0
	$hours = 0
	$minutes = 0
	# convert mA's to FULL / charge rate mAh to seconds
	$seconds = [int]((( $full - $current) / $rate) * $secondsInHour)
	while ($seconds -ge $secondsInDay) {
		$days += 1
		$seconds -= $secondsInDay
	}
	if ($days -gt 0) {
		$est += "$($days)d "
	}
	while ($seconds -ge $secondsInHour) {
		$hours += 1
		$seconds -= $secondsInHour
	}
	if (($est.Length -gt 0) -or ($hours -gt 0)) {
		$est += "$($hours)h "
	}
	while ($seconds -ge $secondsInMinute) {
		$minutes += 1
		$seconds -= $secondsInMinute
	}
	if (($est.Length -gt 0) -or ($minutes -gt 0)) {
		$est += "$($minutes)m "
	}		
	$est += "$($seconds)s"
	return "~$est"
}

function Get-EstimatedTime {



}

function Get-BatteryStaticInfo {
	try {
		return [PSCustomObject] @{
			DesignVoltage			= (Get-WmiObject win32_battery).DesignVoltage
			DesignedCapacity		= (Get-WmiObject -class BatteryStaticData -Namespace ROOT\WMI).DesignedCapacity
			FullChargedCapacity		= (Get-WmiObject -class BatteryFullChargedCapacity -Namespace ROOT\WMI).FullChargedCapacity
			CycleCounter			= (Get-WmiObject -class BatteryCycleCount -Namespace ROOT\WMI).CycleCount
		}
	}
	catch {
		return $null
	}	
}

function Get-BatteryInfo {
	param($staticInfo)
	try {
		$w32battery					= Get-WmiObject win32_battery | Select-Object BatteryRechargeTime, EstimatedRunTime, EstimatedChargeRemaining
		$statusData 				= Get-WmiObject -class BatteryStatus -Namespace ROOT\WMI | Select-Object PowerOnline, Voltage, Charging, ChargeRate, Discharging, DischargeRate, RemainingCapacity
		$estRunTime					= Get-EstimatedTimeLeftString -full $statusData.RemainingCapacity -current 0 -rate ($statusData.DischargeRate - $statusDate.ChargeRate)
		$estRechargeTime			= Get-EstimatedTimeLeftString -full $staticInfo.FullChargedCapacity -current $statusData.RemainingCapacity -rate ($statusData.ChargeRate - $statusData.DischargeRate)
		
		return [PSCustomObject] @{
			IsPwrPlugged			= $statusData.PowerOnline
			IsCharging				= $statusData.Charging
			ChargeRate				= $statusData.ChargeRate
			Voltage					= $statusData.Voltage			
			IsDischarging			= $statusData.Discharging
			DischargeRate			= $statusData.DischargeRate
			RemainingCapacity		= $statusData.RemainingCapacity
			EstRunTimeW32			= $w32battery.EstimatedRunTime
			EstRunTime				= $estRunTime
			RechargeTime			= $w32battery.BatteryRechargeTime
			EstRechargeTime 		= $estRechargeTime
			ChargeRemaining			= $w32battery.EstimatedChargeRemaining			
			CycleCounter			= $staticInfo.CycleCounter
			DesignVoltage			= $staticInfo.DesignVoltage
			DesignedCapacity		= $staticInfo.DesignedCapacity
			FullChargedCapacity		= $staticInfo.FullChargedCapacity
		}
	}
	catch {
		return $null
	}
}


function Get-BatteryChargingInfo {
	param ($batteryInfo)
	
	if (-not $batteryInfo) {
		return $null
	}
	
	try {
		$chargingInfo 		= Convert-BoolToString -boolValue $batteryInfo.IsCharging
		$dischargingInfo 	= Convert-BoolToString -boolValue $batteryInfo.IsDischarging
		
		if ($batteryInfo.ChargeRate -eq $batteryInfo.DischargeRate) {
		}
		elseif ($batteryInfo.ChargeRate -gt $batteryInfo.DischargeRate) {
		}
		else {
		}
		
		if ($batteryInfo.ChargeRate -gt 0) {
			$chargingInfo += ", $($batteryInfo.ChargeRate) [mA]"
		}
		if ($batteryInfo.DischargeRate -gt 0) {
			$dischargingInfo += ", $($batteryInfo.DischargeRate) [mA]"
		}

		return [PSCustomObject] @{
			Remaining				= "$($batteryInfo.ChargeRemaining)%"
			IsPwrPlugged			= Convert-BoolToString -boolValue $batteryInfo.IsPwrPlugged
			IsCharging				= $chargingInfo
			EstRechargeTime	= $batteryInfo.EstRechargeTime
			IsDischarging			= $dischargingInfo
			EstRunTime		= $batteryInfo.EstRunTime
		}
	}
	catch {
		return $null
	}	
}

function Get-BatteryStatusInfo {
	param ($batteryInfo)
	
	if (-not $batteryInfo) {
		return $null
	}
	
	try {

		$info = ""
		if ($batteryInfo.IsPwrPlugged) { 
			$info += "(plugged-in"
			if ($batteryInfo.IsCharging) {
				$info += ", charging"
			}
			$info += ")"
		}
		
		if (-not $batteryInfo.IsCharging) {
			return [PSCustomObject] @{
				Remaining		= "$($batteryInfo.ChargeRemaining)% $info"
				EstRunTime		= "$($batteryInfo.EstRunTime)" # ($estRunUntil)"
				Voltage			= "$($batteryInfo.Voltage)mV"
				DesignVoltage	= "$($batteryInfo.DesignVoltage)mV"
			}			
		}
		else { 
			return [PSCustomObject] @{
				Remaining				= "$($batteryInfo.ChargeRemaining)% $info"
				EstRechargeTime 	= "$($batteryInfo.EstRechargeTime)"
				Voltage			= "$($batteryInfo.Voltage)mV"
				DesignVoltage	= "$($batteryInfo.DesignVoltage)mV"				
			}			
		}
	}
	catch {
		Write-Host "error $_"
		return $null
	}	
}

function Get-BatteryHealthInfo {
	param ($staticInfo)
	if (-not $staticInfo) {
		return $null
	}
	try {
		$health = [Math]::Round(($staticInfo.FullChargedCapacity / $staticInfo.DesignedCapacity * 100), 1)
		return [PSCustomObject] @{
			Cycle				= $staticInfo.CycleCounter
			Health				= "$($health)%"
			FullChargedCapacity	= "$($staticInfo.FullChargedCapacity) [mAh]"
			DesignedCapacity	= "$($staticInfo.DesignedCapacity) [mAh]"
			
		}
	}
	catch {
		return $null
	}
}


$noCapaIncrCounter = 1
$prevRemainingCapacity = -1
try {
	$batteryStaticInfo = Get-BatteryStaticInfo
		
#	Write-Host $batteryStaticInfo
	$batteryHealthInfo = Get-BatteryHealthInfo -staticInfo $batteryStaticInfo
	
	while ($true) {

		try {
			# | Format-Table -AutoSize
			$batteryInfo = Get-BatteryInfo -staticInfo $batteryStaticInfo
			
			Write-Host "`n`r`n`r$([datetime]::Now)"
			Write-Host "`n`rBATTRY INFO:"
			Write-Host "============"
			$batteryInfo | Select-Object *

			Write-Host "`n`rSTATUS INFO:"
			Write-Host "============"
			Get-BatteryStatusInfo -batteryInfo $batteryInfo | Select-Object *

			Write-Host "`n`rCHARGE INFO:"
			Write-Host "============"
			Get-BatteryChargingInfo -batteryInfo $batteryInfo | Select-Object *

			Write-Host "`n`rHEALTH INFO:"
			Write-Host "============"
			$batteryHealthInfo | Select-Object *
			
			Start-Sleep -Milliseconds $sleepLength
		}
		catch {
			Write-Error "An error occurred while obtaining battery info: $_"
		}
	}
}
catch {
	Write-Error "An error occurred while obtaining battery info: $_"
}