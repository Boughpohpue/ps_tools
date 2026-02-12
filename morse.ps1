<#
.SYNOPSIS
    Morse code encoding, decoding, and audio playback.

.DESCRIPTION
    Converts text to Morse code and vice versa. Supports audio playback of Morse code sequences.
    Requires beep.ps1 for audio functionality.

.FUNCTIONS
    MorseCode-Convert     - Convert single character to/from Morse code
    MorseCode-TextToCode  - Encode text to Morse code with formatting
    MorseCode-CodeToText  - Decode Morse code to text
    MorseCode-GetSounds   - Get sound parameters for Morse code sequence
    MorseCode-Beep        - Play Morse code as audio
    Morse-Encode          - Encode text with optional beep and print
    Morse-Decode          - Decode Morse code with optional beep and print

.EXAMPLE
    Morse-Encode -text "Hello" -beep -print
    Morse-Decode -code "||....|.|.-...|.-...|---||" -print

.NOTES
    Author: Lukas Kulik
    Version: 1.0
    Requires: beeps.ps1
#>

. .\beeps.ps1

function MorseCode-Convert {
	param(
		[string]$value,
		[switch]$decode
	)
	$codes = @{
		[char]' ' = ""
		[char]'a' = ".-"
		[char]'b' = "-..."
		[char]'c' = "-.-."
		[char]'d' = "-.."
		[char]'e' = "."
		[char]'f' = "..-."
		[char]'g' = "--."
		[char]'h' = "...."
		[char]'i' = ".."
		[char]'j' = ".---"
		[char]'k' = "-.-"
		[char]'l' = ".-.."
		[char]'m' = "--"
		[char]'n' = "-."
		[char]'o' = "---"
		[char]'p' = ".--."
		[char]'q' = "--.-"
		[char]'r' = ".-."
		[char]'s' = "..."
		[char]'t' = "-"
		[char]'u' = "..-"
		[char]'v' = "...-"
		[char]'w' = ".--"
		[char]'x' = "-..-"
		[char]'y' = "-.--"
		[char]'z' = "--.."
		[char]'1' = ".----"
		[char]'2' = "..---"
		[char]'3' = "...--"
		[char]'4' = "....-"
		[char]'5' = "....."
		[char]'6' = "-...."
		[char]'7' = "--..."
		[char]'8' = "---.."
		[char]'9' = "----."
		[char]'0' = "-----"
		[char]'.' = ".-.-.-"
		[char]',' = "--..--"
		[char]'?' = "..--.."
		[char]'@' = ".--.-."
		[char]'/' = "-..-."
	}
	if ($decode) {
		return $codes.GetEnumerator() | Where-Object {$_.Value -eq $value} | ForEach-Object {$_.Name}
	}
	elseif ($codes.ContainsKey([char]$value[0])) {
		return $codes[[char]$value[0]]
	}
	return $null
}
function MorseCode-TextToCode {
	param([string]$text)
	return ($text.ToLower().toCharArray() | ForEach-Object {MorseCode-Convert -value $_} | Where-Object {$_ -ne $null}) | &{$ofs='|';"$input"} | ForEach-Object {"||$($_)||"}
}
function MorseCode-CodeToText {
	param([string]$code)
	return ($code.split('|') | ForEach-Object {MorseCode-Convert -value $_ -decode} | Where-Object {$_ -ne $null}) | &{$ofs='';"$input"} | ForEach-Object {$_ -replace '  ', ''}
}
function Morse-Encode {
	param(
		[string]$text,
		[switch]$beep,
		[switch]$print
	)
	$code = MorseCode-TextToCode -text $text
	if ($print -eq $true) {
		Write-Host "$($text) => $($code)"
	}
	if ($beep -eq $true) {
		MorseCode-Beep -code $code
	}
	return $code
}
function Morse-Decode {
	param(
		[string]$code,
		[switch]$beep,
		[switch]$print
	)
	if ($beep -eq $true) {
		MorseCode-Beep -code $code
	}	
	$text = MorseCode-CodeToText -code $code
	if ($print -eq $true) {
		Write-Host "$($code) => $($text)"
	}
	return $text
}
function MorseCode-GetSounds {
	param([string]$code)
	$morseSounds = @{
		[char]'.' = @{
			frq=693 
			dur=69 
			nap=33
		}
		[char]'-' = @{
			frq=693 
			dur=207 
			nap=33
		}
		[char]'|' = @{
			frq=693 
			dur=0 
			nap=240
		}
	}
	return $code.toCharArray() | ForEach-Object {$morseSounds[[char]$_]}
}
function MorseCode-Beep {
	param([string]$code)
	Beep-Sounds -sounds (MorseCode-GetSounds -code $code)
}
