# Battery-Low alarm

. .\morse.ps1

$script:refreshSleep = 60000
$script:minBatteryLevel = 50
$script:alertDifference = 10

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
		
		return [PSCustomObject] @{
			IsPwrPlugged			= $statusData.PowerOnline
			IsCharging				= $statusData.Charging
			ChargeRate				= $statusData.ChargeRate
			Voltage					= $statusData.Voltage			
			IsDischarging			= $statusData.Discharging
			DischargeRate			= $statusData.DischargeRate
			RemainingCapacity		= $statusData.RemainingCapacity
			EstRunTimeW32			= $w32battery.EstimatedRunTime
			RechargeTime			= $w32battery.BatteryRechargeTime
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
function Print-BatteryInfo {
	param($batteryInfo)
	if ($batteryInfo -eq $null) {
		return;
	}
	Write-Host "`n`r`n`r$([datetime]::Now)"
	Write-Host "`n`rBATTRY INFO:"
	Write-Host "============"
	$batteryInfo | Select-Object *	
}

try {
	$batteryStaticInfo = Get-BatteryStaticInfo
	$beeped = $script:minBatteryLevel + $script:alertDifference
	while ($true) {
		try {
			$bi = Get-BatteryInfo -staticInfo $batteryStaticInfo
			if (-not $bi.IsPwrPlugged) { 
				Print-BatteryInfo -batteryInfo $bi
				$cr = $bi.ChargeRemaining
				if ($cr -le $beeped - $script:alertDifference) {
					$beeped = $cr
					Morse-Encode -text "Battery low $($cr)" -beep
				}				
			}
			Start-Sleep -Milliseconds $script:refreshSleep
		}
		catch {
			Write-Error "An error occurred while obtaining battery info: $_"
		}
	}
}
catch {
	Write-Error "An error occurred while obtaining battery info: $_"
}
