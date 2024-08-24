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
    1.0

.DATE
    2024-08-23

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
$loopFlag = $false

# $StackFlag: A global boolean variable that determines if multiple sounds should be played in parallel. It is toggled by the F3 key.
$StackFlag = $false

# Ordered array of keyboard keys mapped to sound lists; adapts to various keyboard layouts
$keys = @("D1","D2","D3","D4","D5","D6","D7","D8","D9","D0",
          "A","Z","E","R","T","Y","U","I","O","P",
          "Q","S","D","F","G","H","J","K","L","M",
          "W","X","C","V","B","N")
		  
##########################################################################################
#
#            Functions
#
##########################################################################################

# Function: Get-SortedAudioFiles
# Purpose: Retrieves and sorts .wav or .mp3 audio files from the specified directory.
# Parameters:
#   - [string]$directoryPath: The path to the directory containing the audio files.
# Returns:
#   - An array of full file paths to the sorted audio files.
# Usage:
#   $audioFiles = Get-SortedAudioFiles -directoryPath "C:\Music"
function Get-SortedAudioFiles {
    param (
        [string]$directoryPath
    )

    # Check if the directory exists
    if (-Not (Test-Path -Path $directoryPath)) {
        Write-Host "The specified directory does not exist."
        return $null
    }

    # Retrieve .wav or .mp3 files and sort them by name
    $audioFiles = Get-ChildItem -Path $directoryPath | Where-Object { $_.Extension -eq ".mp3" -or $_.Extension -eq ".wav" } | Sort-Object Name

    # Return the full names of the files in an array
    return $audioFiles.FullName
}


# ---------------------------------------------------------------
# Function: Get-SoundTableBySoundName
# ---------------------------------------------------------------
# This function retrieves the sound table associated with a specific sound name from the provided hashtable ($soundTable).
# 
# Parameters:
# - [string]$soundName: The name of the sound list to search for within the $soundTable hashtable.
# - [hashtable]$soundTable: The hashtable containing sound configurations, mapping keys to sound information.
#
# Returns:
# - If the sound name exists in $soundTable, it returns the corresponding sound table.
# - If the sound name does not exist, it returns $null and writes a message to the host.
#
# Example usage:
# Assuming $soundTable is a hashtable with sound names as keys:
# $result = Get-SoundTableBySoundName -soundName "Drums" -soundTable $soundTable
#
# This would search for a sound table named "Drums" in $soundTable and return it if found.

function Get-SoundTableBySoundName {
    param (
        [string]$soundName,          # The name of the sound table to find
        [hashtable]$soundTable       # The hashtable containing sound tables
    )

    if ($soundTable.ContainsKey($soundName)) {
        return $soundTable[$soundName]  # Return the sound table if found
    } else {
        Write-Host "The sound list '$soundName' does not exist."  # Print an error if not found
        return $null  # Return null if the sound table is not found
    }
}

# ---------------------------------------------------------------
# Function: Get-KeyBySoundName
# ---------------------------------------------------------------
# This function finds the key associated with a specific sound table name within the provided $soundTable.
#
# Parameters:
# - [string]$soundName: The name of the sound list to find the associated key for.
# - [hashtable]$soundTable: The hashtable containing sound configurations, mapping keys to sound information.
#
# Returns:
# - If a key associated with the provided sound name is found, it returns the corresponding key.
# - If no matching key is found, it returns $null and writes a message to the host.
#
# Global Variables Used:
# - $keys: This function uses the global $keys array to iterate through all possible keys to find the one associated with the specified sound name.
#
# Example usage:
# Assuming $soundTable contains a sound table named "Drums":
# $key = Get-KeyBySoundName -soundName "Drums" -soundTable $soundTable
#
# This would return the key associated with the "Drums" sound table if it exists.

function Get-KeyBySoundName {
    param (
        [string]$soundName,          # The name of the sound table to find the associated key
        [hashtable]$soundTable       # The hashtable containing sound tables
    )

    # Iterate over all valid keys to find the one that matches the given sound name
    foreach ($key in $keys) {
        if ($soundTable.ContainsKey($key) -and $soundTable[$key]["name"] -eq $soundName) {
            return $key  # Return the key associated with this sound name
        }
    }

    # If no matching key is found, print an error and return null
    Write-Host "No key associated with the sound list '$soundName' was found."
    return $null
}

# ---------------------------------------------------------------
# Function: Wait-ForMediaPlayerInitialization
# ---------------------------------------------------------------
# This function waits for a single MediaPlayer object to be initialized, specifically waiting for it to be ready to play audio.
#
# Parameters:
# - [System.Windows.Media.MediaPlayer]$player: The MediaPlayer object to be checked for initialization.
#
# Returns:
# - None. This function waits until the MediaPlayer is ready or until a timeout occurs.
# - If the timeout is reached before the MediaPlayer is initialized, a message is displayed in red.
# - If the MediaPlayer is successfully initialized within the timeout period, a confirmation message is displayed in green with the elapsed time.
#
# Example usage:
# $mediaPlayer = New-Object System.Windows.Media.MediaPlayer
# Wait-ForMediaPlayerInitialization -player $mediaPlayer
#
# This example creates a new MediaPlayer object and waits for it to be ready to play audio using the Wait-ForMediaPlayerInitialization function.

function Wait-ForMediaPlayerInitialization {
    param (
        [System.Windows.Media.MediaPlayer]$player  # The MediaPlayer object to monitor for initialization
    )

    $timeout = 10 # Timeout in seconds
    $elapsedTime = 0  # Initialize elapsed time counter

    # Loop until the MediaPlayer is ready or the timeout is reached
    while ($player.HasAudio -eq $false -and $elapsedTime -lt $timeout) {
        Start-Sleep -Milliseconds 100  # Wait for 100 milliseconds
        $elapsedTime += 0.1  # Increment elapsed time by 0.1 seconds
    }

    # Check if the timeout was reached
    if ($elapsedTime -ge $timeout) {
        Write-Host "Timeout: The MediaPlayer could not be initialized within the allocated time." -ForegroundColor red
    } else {
        Write-Host "OK: Sound initialized in $elapsedTime seconds." -ForegroundColor Green
    }
}

# ---------------------------------------------------------------
# Function: Wait-ForAllMediaPlayersInitialization
# ---------------------------------------------------------------
# This function waits for all MediaPlayer objects in a given sound table to be initialized, specifically waiting for each player to be ready to play audio.
#
# Parameters:
# - [hashtable]$soundTable: A hashtable where keys are mapped to sound configurations. Each key points to another hashtable that includes a "players" array, which contains MediaPlayer objects.
#
# Returns:
# - None. This function waits until all MediaPlayer objects in the sound table are ready to play audio.
# - For each MediaPlayer that becomes ready, the function displays a green message with the elapsed time since the initialization process started.
# - Once all MediaPlayer objects are ready, a final message is displayed confirming that all players are initialized.
#
# Global Variables Used:
# - None. This function only uses the parameters provided during the call.
#
# Example usage:
# Assuming $soundTable contains keys mapped to sound configurations:
# Wait-ForAllMediaPlayersInitialization -soundTable $soundTable
#
# This example waits for all MediaPlayer objects in the provided sound table to be initialized.

function Wait-ForAllMediaPlayersInitialization {
    param (
        [hashtable]$soundTable  # The hashtable containing sound configurations and MediaPlayer objects
    )

    $allInitialized = $false  # Flag to check if all players are initialized
    $startTime = Get-Date  # Record the start time for tracking elapsed time
    $initializedPlayers = @{}  # Hashtable to track players that have already been initialized

    Write-Host "Initializing sounds..." -ForegroundColor Yellow

    # Loop until all players are initialized
    while (-not $allInitialized) {
        $allInitialized = $true  # Assume all players are initialized unless proven otherwise

        foreach ($key in $soundTable.Keys) {
            # Check if the current entry is a hashtable (i.e., it's a valid sound configuration)
            if ($soundTable[$key] -is [hashtable]) {
                foreach ($player in $soundTable[$key]["players"]) {
                    if ($player.HasAudio -eq $false) {
                        $allInitialized = $false  # At least one player is not yet initialized
                    } elseif (-not $initializedPlayers.ContainsKey($player)) {
                        # Calculate elapsed time and display a message for the initialized player
                        $elapsedTime = (Get-Date) - $startTime
                        Write-Host ("$($soundTable[$key]["name"]) is ready after {0:N2} seconds" -f $elapsedTime.TotalSeconds) -ForegroundColor Green
                        
                        # Add the player to the hashtable of initialized players
                        $initializedPlayers[$player] = $true
                    }
                }
            }
        }

        if (-not $allInitialized) {
            Start-Sleep -Milliseconds 100  # Wait before checking again
        }
    }

    Write-Host "All MediaPlayer objects are initialized."
}

<#
	This function processes each audio file in the $audioFiles array and organizes them into sound lists.
	Each list is associated with a key from the $keys array. If a key is already associated with a list,
	the function adds the sound to that list. If not, it creates a new list.

	Global Variables Used:
	- $audioFiles: List of audio files to process.
	- $keys: List of keys to associate with the sound lists.
	- $soundTable: Hashtable that will store the sound lists.
    example Set up the global variables:
       $audioFiles = Get-ChildItem -Path "C:\path\to\audio\files" -Filter "*.wav" -Recurse
       $keys = @('A', 'B', 'C', 'D')  # Define the keys available for associating sound lists
       $soundTable = @{}  # Initialize the hashtable

	Example of usage:
	Create-SoundTable
#>
function Create-SoundTable {
    # Initialize the index for associating keys
    $indexKey = 0

    # Iterate over each audio file in the array
    foreach ($file in $audioFiles) {
        $fileName = Split-Path $file -leaf

        # Extract information from the file name using a regex pattern
        if ($fileName -match '^(\d{3})_(.+?) \(\d+\)\.(mp3|wav)$') {
            $index = $matches[1]
            $soundName = $matches[2]

            # Ensure there are enough keys to associate with the sounds
            if ($indexKey -eq $keys.Count) {
                Write-Host "No more available keys for associating the sound $fileName"
                continue 
            }

            # Create a MediaPlayer object and prepare it
            Write-Host "$soundName"
            $player = New-Object System.Windows.Media.MediaPlayer
            $player.Open([uri]::new($file))
            $player.Stop()
            $player.position = [timespan]::Zero

            # Check if a key is already associated with the sound list
            $key = Get-KeyBySoundName -soundName $soundName -soundTable $soundTable
            
            # If no key is associated with the list, create a new one
            if ($null -eq $key) {

                # Assign the next available key
                $key = $keys[$indexKey]

                # Initialize the new list in the soundTable if it doesn't exist
                if (-not $soundTable.ContainsKey("$key")) {
                    Write-Host "Creating a new sound list: $soundName"

                    $soundTable[$key] = @{
                        "name" = $soundName    # Name of the sound list
                        "players" = @()        # Array of MediaPlayer objects (sounds)
                        "lastSound" = -1       # Index of the last played sound
                        "loop" = $false        # Whether the sound should loop
                        "paralleled" = $false  # Whether sounds in the list play in parallel
                        "paralleleOn" = $false # Controls parallel sound playback
                        "random" = $false      # Whether sounds are played randomly
                        "sequential" = $true   # Default playback mode: sequential
                    }

                    # Add an entry by name for easier retrieval
                    $soundTable[$soundName] = $soundTable[$key]

                    # Move to the next key in the $keys array
                    $indexKey += 1                
                }
            }

            # Add the MediaPlayer object to the corresponding sound list
            $soundTable[$key]["players"] += $player
        }
    }
}

<#
	This function displays detailed information about each sound list in the $soundTable.
	It shows the key associated with each list, the name of the list, the number of sounds, and details about each MediaPlayer object.

	Global Variables Used:
	- $soundTable: Hashtable containing the sound lists.

	Example of usage:
	show-detail-SoundList
#>
function show-detail-SoundList {

    foreach ($key in $soundTable.Keys) {
        Write-Host "Key: $key"
        Write-Host "Sound list name: $($soundTable[$key]['name'])"
        Write-Host "Number of sounds: $($soundTable[$key]['players'].Count)"
        Write-Host "Details of MediaPlayer objects:"

        # Display information for each MediaPlayer object associated with the key
        foreach ($player in $soundTable[$key]['players']) {
            Write-Host "  - File: $($player.Source)"
        }

        Write-Host "-----------------------------"
    }
}

<#
	This function displays a summary of the available sound lists stored in the $soundTable.
	It lists each key, the name of the associated sound list, and the number of sounds in each list.

	Example of usage:
	Show-SoundTable -soundTable $soundTable -keys $keys
#>
function Show-SoundTable {
    param (
        [hashtable]$soundTable,  # Hashtable containing the sound lists
        [array]$keys             # Array of keys to display the associated sound lists
    )


    Write-Host "List of available sounds:"
    Write-Host "--------------------------------"

    foreach ($key in $keys) {
        # Check if the key is present in the soundTable
        if ($soundTable.ContainsKey($key)) {
            $soundName = $soundTable[$key]["name"]
            $soundCount = $soundTable[$key]["players"].Count
            Write-Host "Key '$key' : $soundName [Number of sounds: $soundCount]"
        }
    }
    
    Write-Host "--------------------------------"
}

function Stop-AllSound {
    <#
        This function stops all currently playing sounds that are associated with keys in the $keys array.
        It iterates through each key, checks if the key is present in the $soundTable, and stops all MediaPlayer objects associated with that key.

        Global Variables Used:
        - $keys: The list of keys to check.
        - $soundTable: The hashtable containing the sound lists.

        Example of usage:
        Stop-AllSound
    #>

    foreach ($key in $keys) {
        # Check if the key is present in the soundTable
        if ($soundTable.ContainsKey($key)) {
            foreach ($player in $soundTable[$key]["players"]) {
                if ($player -is [System.Windows.Media.MediaPlayer]) {
                    try {
                        $player.Stop()
                        # Optional logging (commented out)
                        #Write-Host "The sound associated with key '$key' has been stopped." -ForegroundColor Green
                    } catch {
                        # Optional error handling (commented out)
                        #Write-Host "Error stopping the sound for key '$key': $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

function Dispose-SoundTable {
    param (
        [hashtable]$soundTable  # Hashtable containing the sound lists to dispose of
    )

    <#
        This function releases all MediaPlayer objects from memory by closing each one.
        It iterates through each key in the $keys array, checks if the key is present in the $soundTable, and disposes of all MediaPlayer objects associated with that key.

        Global Variables Used:
        - $keys: The list of keys to check.
        - $soundTable: The hashtable containing the sound lists.

        Example of usage:
        Dispose-SoundTable -soundTable $soundTable
    #>

    foreach ($key in $keys) {
        # Check if the key is present in the soundTable
        if ($soundTable.ContainsKey($key)) {
            foreach ($player in $soundTable[$key]["players"]) {
                if ($player -is [System.Windows.Media.MediaPlayer]) {
                    try {
                        $player.Close()
                        $name = $soundTable[$key]['name']
                        Write-Host "The sound '$name' associated with key '$key' has been successfully unloaded from memory." -ForegroundColor Green
                    } catch {
                        Write-Host "Error disposing the sound for key '$key': $_" -ForegroundColor Red
                    }
                }
            }
        }
    }

    Write-Host "All MediaPlayer objects have been disposed."
}


# ---------------------------------------------------------------
# Function: Invoke-keyboard-Player
# ---------------------------------------------------------------
# This function plays or stops a sound based on the input parameters and the global sound table ($soundTable).
#
# Parameters:
# - $keySound: The key associated with the list of sounds to be played.
# - $wantedSound: The index of a specific sound to play (default is -1, meaning no specific sound is targeted).
# - [Switch]$unikPlay: A flag to play a specific sound from the list, determined by $wantedSound.
# - [Switch]$SequencePlay: A flag to play sounds sequentially from the list.
# - [Switch]$RandomPlay: [NOT IMPLEMENTED] A flag to play sounds in a random order.
#
# Global Variables Used:
# - $soundTable: Retrieves and updates the sound list and its current state.
# - $loopFlag: Updates the loop state of the current sound list.
# - $StackFlag: Determines whether to stop the current sound or layer it with a new one.
#
# Returns:
# - None. The function directly plays or stops sounds based on the conditions.
#
# Example usage:
# Assuming you want to play the sounds associated with the key "A" sequentially:
# Invoke-keyboard-Player -keySound "A" -SequencePlay
# This will play the next sound in the sequence from the list associated with "A".
function Invoke-keyboard-Player {
    param (
        $keySound,             # Key associated with the sound list.
		$wantedSound = -1,     # Index of the specific sound to play.
		[Switch]$unikPlay,     # Flag to play a specific sound.
		[Switch]$SequencePlay, # Flag to play sounds sequentially.
		[Switch]$RandomPlay    # [NOT IMPLEMENTED] Flag to play sounds randomly.
    )

	# Retrieve sound list information from $soundTable
	$lastIndex     = $soundTable[$keySound]['lastSound']
	$players       = $soundTable[$keySound]['players']
	$countSound    = $players.Count
	$sequential    = $soundTable[$keySound]['sequential']
	$random        = $soundTable[$keySound]['random']
	$paralleled    = $soundTable[$keySound]['paralleled']
	$paralleledOn  = $soundTable[$keySound]['paralleledOn']
	$name  		   = $soundTable[$keySound]['name']
	
	# Update loop and parallel flags based on global variables
	$soundTable[$keySound]['loop'] = $loopFlag
	$soundTable[$keySound]['paralleled'] = $StackFlag

	# Stop the currently playing sound if StackFlag is not set
	if ($lastIndex -ne -1 -and -not ($StackFlag)  ) {
		$player = $players[$lastIndex]
		Toggle-Sound -player $player -stop				
	}

	# Play a specific sound if unikPlay is set
	if ($unikPlay) {
		if ($wantedSound -gt -1 -and $wantedSound -lt $countSound) {

			$soundTable[$keySound]['lastSound'] = $wantedSound  # Update last played sound index
			$player                             = $players[$wantedSound]		
			
			Write-Host "Playing sound: $name number [$wantedSound]"
			Toggle-Sound -player $player
			
		} 
		return # Operation completed
	}

	# Handle sequential playback
	if ($SequencePlay) {
	
		# Check if the last sound in the list was played
		if ($lastIndex -eq $($countSound )) {
		
			Write-Host "Sound list: ($name) completed" -ForegroundColor Cyan
	
			# Reset index and do not play new sounds
			$soundTable[$keySound]['lastSound'] = -1

			return # Operation completed
		
		} else {			
		
			
			# Move to the next sound in the list
			$lastIndex += 1
			$soundTable[$keySound]['lastSound'] = $lastIndex
			if ($lastIndex -eq $countSound) {
				# End the list after the last sound
				Invoke-keyboard-Player -keySound $keySound -SequencePlay
				return # Operation completed, list ended	
			}

			# Play the next sound
			Write-Host "Sound list: ($name), playing sound number = $lastIndex"
			$player = $players[$lastIndex]
			$player.position = [timespan]::Zero
			
			if ($StackFlag) {Toggle-Sound -player $player -play} else {Toggle-Sound -player $player}

			return # Operation completed
		}		 

	}

}

# ---------------------------------------------------------------
# Function: Toggle-Sound
# ---------------------------------------------------------------
# This function starts or stops a sound based on the given player object and switch flags.
#
# Parameters:
# - $player: The sound player object associated with the sound to be played or stopped.
# - $soundInfo: [Optional] Additional sound information, not used in this function.
# - [switch]$play: If set, forces the player to play the sound.
# - [switch]$stop: If set, forces the player to stop the sound.
#
# Global Variables Used:
# - None.
#
# Returns:
# - None. The function directly controls the sound player based on the conditions.
#
# Example usage:
# Assuming $player is a sound player object:
# Toggle-Sound -player $player -play
# This will force the player to start playing the sound.
function Toggle-Sound {
    param (
		$player, 				   # Player associated with the sound to be played or stopped.
		$soundInfo = $null,        # [Optional] Sound information, not used in this function.
		[switch]$play,             # Flag to force the player to play the sound.
		[switch]$stop              # Flag to force the player to stop the sound.
	)

	if ($null -eq $player) {return}

	# Play the sound if it's at the beginning or the end
	if ($player.position -eq [TimeSpan]::Zero -or $player.position -eq $player.NaturalDuration.TimeSpan) {			
		# Play the sound once
		$player.Play()
		Write-Host "play"
	} else {
		# Stop the sound if it is already playing
		$player.Stop()
		Write-Host "stop"
	}

	# Force the sound to play if the play switch is set
	if ($play) {
		$player.Play()
		Write-Host "force play"
	}
	
	# Force the sound to stop if the stop switch is set
	if ($stop) {
		$player.stop()
		Write-Host "force stop"
	}
}

# ---------------------------------------------------------------
# Function: Update-loops
# ---------------------------------------------------------------
# This function checks and updates the playback state of looping sounds.
# It is primarily used to restart sounds that have reached the end of their natural duration if looping is enabled.
#
# Parameters:
# - None.
#
# Global Variables Used:
# - $soundTable: Retrieves the sound list and its current loop status.
# - $StackFlag: Determines whether to handle looping sounds in parallel or individually.
#
# Returns:
# - None. The function directly manages sound playback based on looping conditions.
#
# Example usage:
# Update-loops
# This function is typically called within a loop to continuously manage sound playback.
function Update-loops {

	foreach ($keySound in $soundTable.Keys) {

		# Retrieve sound list information
		$lastindex   = $soundTable[$keySound]['lastSound']
		$players     = $soundTable[$keySound]['players']
		$player      = $players[$lastindex]
		$loop        = $soundTable[$keySound]['loop']
		
		# Check if the sound is at the end and looping is enabled
		if ($true -eq $loop) {

			if ($StackFlag) {

				# Handle sounds played in parallel
				for($i=0; $i -lt ($lastindex+1); $i++) {
					$player = $players[$i]

					if ($player.Position -eq $player.NaturalDuration.TimeSpan ) {
					
						# Restart the sound
						$player.Position = 0
						$player.play()
					}
	
				}
			} else {

				# Handle a single sound
				if ($player.Position -eq $player.NaturalDuration.TimeSpan ) {
					
					# Restart the sound
					$player.Position = 0
					$player.play()
				}
			}
		}
	}
}

# ---------------------------------------------------------------
# Function: Read-KeyNonBlocking
# ---------------------------------------------------------------
# This function reads a key press in a non-blocking manner, meaning it does not pause the program while waiting for input.
#
# Parameters:
# - None.
#
# Global Variables Used:
# - None.
#
# Returns:
# - [System.ConsoleKey]: The key that was pressed, or $null if no key was pressed.
#
# Example usage:
# $key = Read-KeyNonBlocking
# This will check if a key has been pressed and return it, or return $null if no key was pressed.
function Read-KeyNonBlocking {
    # Save the original configuration
    $oldMode = [System.Console]::KeyAvailable
    $oldMode = $oldMode::Original

    # Configure to not block the flow
    [System.Console]::TreatControlCAsInput = $true

    # Check if a key is pressed
    if ([System.Console]::KeyAvailable) {
        $key = [System.Console]::ReadKey($true)  # $true to prevent the key from being displayed
        return $key.Key
    } else {
        return $null
    }
}

# ---------------------------------------------------------------
# Function: Start-Listening-Keyboard
# ---------------------------------------------------------------
# This is the main function that continuously listens for key presses in the background.
# It reacts to specific keys to control sound playback, loops, and parallel playback.
#
# Parameters:
# - None.
#
# Global Variables Used:
# - $loopFlag: Toggles looping on and off with the F2 key.
# - $StackFlag: Toggles parallel playback on and off with the F3 key.
# - $soundTable: Used to identify and play sounds based on key presses.
#
# Returns:
# - None. This function runs continuously until a termination key (Delete) is pressed.
#
# Example usage:
# Start-Listening-Keyboard
# This function starts listening for key presses and handles sound playback accordingly.
function Start-Listening-Keybaord {
    Write-Host "Press a key to play a sound"
    $running = $true
	
    while ($running) {
        $key = Read-KeyNonBlocking
        if ($null -ne $key) {
			$key = $($key | Out-String).trim()
            Write-Host "Key pressed: [$key]"
			
            if ($key -eq 'Delete') {
                $running = $false
				Stop-AllSound
				Write-Host "Program ended"    
            }

            if ($key -eq 'Escape') {
				Stop-AllSound
				Write-Host "All sounds stopped."  
				continue  
			}
			
            if ($key -eq 'F1') {
				Clear-host
				Show-SoundTable -soundTable $soundTable -keys $keys
				continue
			}
				
			# Toggle looping on/off with F2
			if ($key -eq 'F2') {
				$loopFlag = -not ($loopFlag)
				if ($loopFlag -eq $true) {
					write-host "Loop active" -ForegroundColor green
				} else {
					write-host "Loop stopped" -ForegroundColor red
				}

				continue
			}

			# Toggle parallel sound playback with F3
			if ($key -eq 'F3') {
				$StackFlag = -not ($StackFlag)
				if ($StackFlag -eq $true) {
					write-host "Parallel playback active" -ForegroundColor green
				} else {
					write-host "Single playback mode" -ForegroundColor red
				}

				continue
			}
			

			# Play/stop a sound
			if ($soundTable.ContainsKey($key)) {
				Invoke-keyboard-Player -keySound $key -SequencePlay
			} else {
				
				write-host "No sound found"
			}
			
			
        }
        # Manage looping sounds every 100ms
        Start-Sleep -Milliseconds 100		
		Update-loops
		
    }
    Write-Host "Loop ended."
}

##########################################################################################
#
#            Main
#
##########################################################################################

##### initialization #####

	$SortedAudioFiles += Get-SortedAudioFiles -directoryPath $directoryPath     # This will store the sorted audio files in the $SortedAudioFiles array.
	$audioFiles = $SortedAudioFiles												# This assigns the sorted list of audio files to $audioFiles for further processing.


	Create-SoundTable															# This will create a sound table mapping keys (derived from audio file names) to sound configurations.


	Wait-ForAllMediaPlayersInitialization -soundTable $soundTable               # This will pause the script execution until all media players in the sound table are initialized.
	Stop-AllSound

	Write-host "système prêt"													# This sequence notifies the user that the system is ready, pauses for user input, clears the console, and then shows the available sound mappings.
	Clear-host
	Show-SoundTable -soundTable $soundTable -keys $keys

##### Main loop #####

	Start-Listening-Keybaord													# This will start the process of listening for key presses and playing the corresponding sounds.

##### END  #####

	
	Stop-AllSound																# This will stop all the sounds currently being played by the media players in the sound table.

	Dispose-SoundTable -soundTable $soundTable									# This will dispose of all media players in the sound table, freeing up system resources.
	Write-Host "Script terminé. Sons arrêtés."
