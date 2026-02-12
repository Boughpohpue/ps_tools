<#
.SYNOPSIS
    Audio beep utilities for playing system sounds.

.DESCRIPTION
    Provides functions to generate beep sounds with customizable frequency, duration, and timing.
    Includes single beep, repeatable beep, and multiple beep sequence functionality.

.FUNCTIONS
    Beep-Sound       	- Play a single beep with specified parameters
	Beep-RepeatSound    - Repeat playing beep with same parameters X times
    Beep-Sounds      	- Play a sequence of different beeps provided as an array

.EXAMPLE
    Beep-Sound 			-frq 693 -dur 96 -nap 69
	Beep-RepeatSound 	-frq 693 -dur 96 -nap 69 -times 3
    Beep-Sounds 		-sounds @(@{frq=693; dur=96; nap=69}, @{frq=369; dur=69; nap=96})

.NOTES
    Author: Lukas Kulik
    Version: 1.0
#>

function Beep-Sound {
	param(
		[int]$frq = 693, 
		[int]$dur = 69, 
		[int]$nap = 144
	)	
	if ($frq -gt 0 -and $dur -gt 0) {
		[Console]::Beep($frq, $dur)
	}
	if ($nap -gt 0) {
		Start-Sleep -Milliseconds $nap
	}
}
function Beep-Sounds {
	param([array]$sounds)
	foreach ($snd in $sounds) {
		Beep-Sound -frq $snd.frq -dur $snd.dur -nap $snd.nap
	}
}
function Beep-RepeatSound {
	param(
		[int]$frq = 693, 
		[int]$dur = 69, 
		[int]$nap = 144,
		[int]$times = 1
	)
	for ($i = 0; $i -lt $times; $i++) {
		Beep-Sound -frq $frq -dur $dur -nap $nap
	}
}
