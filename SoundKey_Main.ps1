<#
.SYNOPSIS
    This PowerShell script plays audio files (.wav or .mp3) from a specified directory. It allows users to control playback using keyboard keys, including playing sequences of sounds, looping, and stacking sounds for simultaneous playback.

.DESCRIPTION
    The script initializes a table of audio sounds from the specified directory, associates them with keyboard keys, and allows users to interactively control playback. 
    Users can play, stop, loop, and sequence sounds using predefined keyboard keys.
    It provides a non-blocking listener for keyboard inputs, enabling real-time sound control without interrupting the script's flow.

.AUTHOR
    Yves WOLFF

.VERSION
    1.2

.DATE
    2025-04-23

.LICENCING
	MIT

.PARAMETER directoryPath
    Specifies the directory where the audio files are located. Default is the current directory.

.EXAMPLE
    ./SoundKey.ps1 -directoryPath "C:\Music"

    This command will run the script and load audio files from the "C:\Music" directory.

.NOTES
    Audio files should be named following the format 'XXX_name (Y).wav' or 'XXX_name (Y).mp3', where:
    - 'XXX' is a three-digit identifier that determines the order in which sound groups are accessed via the keyboard.
    - 'name' is a descriptive name of the sound list.
    - '(Y)' is the index number within the sound group that determines the order of the sounds when played.

	# Example file names adhering to the specified format:
		001_Birds (1).wav      # First sound in the 'Birds' sound group.
		001_Birds (2).wav      # Second sound in the 'Birds' sound group.
		002_Drums (1).mp3      # First sound in the 'Drums' sound group.
		002_Drums (2).mp3      # Second sound in the 'Drums' sound group.
		003_Rain (1).wav       # First sound in the 'Rain' sound group.
		003_Rain (2).wav       # Second sound in the 'Rain' sound group.
		003_Rain (3).wav       # Third sound in the 'Rain' sound group.

	# This structured naming scheme allows the script to easily organize sounds into groups and subgroups, facilitating
	# easier access and control over playback, especially when mapped to keyboard keys for triggering sounds.

#>

param (
    [string]$directoryPath=".\"
)

##########################################################################################
#
#            Initialization
#
##########################################################################################

# Load the Windows Presentation Foundation (WPF) assembly required for MediaPlayer
Add-Type -AssemblyName PresentationCore


# include
. .\SoundKey_Functions.ps1
# Charge les helpers UI (fonctions)
. .\SoundKey_UI_Functions.ps1
# Load the UI from SoundKey_UI.ps1
. .\SoundKey_UI.ps1

# ---------------------------------------------------------------
# Global Variables
# ---------------------------------------------------------------
# $soundTable: A hashtable that maps key presses (e.g., 'A', 'B') to sound configurations. 
#              Each key points to another hashtable containing:
#              - 'lastSound': The index of the last played sound.
#              - 'players': An array of sound player objects.
#              - 'loop': A flag indicating if the sound should loop.
#              - 'paralleled': A flag indicating if sounds should be played simultaneously.
#              - 'name': The name of the sound or sound list.
#
# $loopFlag: A global boolean variable that determines if the sound should loop. It is toggled by the F2 key.
#
# $StackFlag: A global boolean variable that determines if multiple sounds should be played in parallel. It is toggled by the F3 key.
# ---------------------------------------------------------------


# Array of sorted audio file paths
$SortedAudioFiles = @()

# $soundTable: A hashtable that maps key presses (e.g., 'A', 'B') to sound configurations. 
#              Each key points to another hashtable containing:
#              - 'lastSound': The index of the last played sound.
#              - 'players': An array of sound player objects.
#              - 'loop': A flag indicating if the sound should loop.
#              - 'paralleled': A flag indicating if sounds should be played simultaneously.
#              - 'name': The name of the sound or sound list.
$soundTable = @{}

# $loopFlag: A global boolean variable that determines if the sound should loop. It is toggled by the F2 key.
$global:loopFlag = $false

# $StackFlag: A global boolean variable that determines if multiple sounds should be played in parallel. It is toggled by the F3 key.
$global:StackFlag = $false

# Ordered array of keyboard keys mapped to sound lists; adapts to various keyboard layouts
$keys = @("D1","D2","D3","D4","D5","D6","D7","D8","D9","D0",
          "A","Z","E","R","T","Y","U","I","O","P",
          "Q","S","D","F","G","H","J","K","L","M",
          "W","X","C","V","B","N")
		  

##########################################################################################
#
#            Main
#
##########################################################################################

##### initialization #####

# Retrieve and add sorted audio files from the specified directory.
$SortedAudioFiles += Get-SortedAudioFiles -directoryPath $directoryPath; $audioFiles = $SortedAudioFiles

# Initialize the sound table mapping keys to sound configurations.
New-SoundTable
Wait-ForAllMediaPlayersInitialization -soundTable $soundTable

# Stop any currently playing sounds, that came one during the init phase
Stop-AllSound
Clear-Host

# Display the sound table and available key mappings.
Show-SoundTable -soundTable $soundTable -keys $keys

##### Main #####
#
        # Start listening to keyboard input and play corresponding sounds.
     #   Start-Listening-Keyboard

     $special = @{
        'F1' = @{
          Action      = { set-key-beavior -key 'F1' -soundTable $soundTable }
          Description = 'Affiche la liste des sons.'
        }
        'F2' = @{
          Action      = { set-key-beavior -key 'F2' -soundTable $soundTable }
          Description = 'Sons en boucles.'
          Toggle      = $true
        }
        'F3' = @{
          Action      = { set-key-beavior -key 'F3' -soundTable $soundTable }
          Description = 'Sons en meme temps.'
          Toggle      = $true
        }
        'Escape' = @{
          Action      = { set-key-beavior -key 'Escape' -soundTable $soundTable }
          Description = 'Stoppe tous les sons.'
        }
        'Delete' = @{
          Action      = { set-key-beavior -key 'Delete' -soundTable $soundTable;  Exit-SoundKeyUI }
          Description = 'Fermer SoundKey.'
        }
      }
    
    Show-SoundKeyUI -soundTable $soundTable -keys $keys -specialFunctions $special
    
    
#
##### END  #####

# Stop all sounds currently playing.
Stop-AllSound
Dispose-SoundTable -soundTable $soundTable
Write-Host "Script completed. Sounds stopped."
