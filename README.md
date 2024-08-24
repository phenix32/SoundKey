# SoundKey Application for "Loup Garou" Game

## Overview

The SoundKey Application is a PowerShell script tailored for enhancing the gaming experience, specifically designed to add atmospheric sounds to the "Loup Garou" game. By allowing the game master to trigger sound effects through keyboard inputs, this tool enriches the narrative and interaction during gameplay. it is also ideal for custom soundboards, interactive audio projects, or adding atmosphere to tabletop RPGs as a game master’s tool.

## Features

- **Customizable Keyboard Mapping:** Adapt the script to different keyboard layouts (e.g., QWERTY) by modifying the global `$keys` variable.
- **Special Key Uses:** 
  - `Escape` (Esc) key to immediately stop all playing sounds, useful for quickly muting all effects when needed.
  - `Delete` key to stop all sounds and exit the script safely.

## Prerequisites

To run this script, you will need:
- Windows operating system with PowerShell 5.1 or later.
- Sound files named according to a specific format (`XXX_name (Y).ext` where `XXX` is a group identifier, `name` is a descriptive name, and `(Y)` is the sound index within the group).

## File Naming Convention

Ensure your sound files are named following the pattern `XXX_name (Y).wav` or `XXX_name (Y).mp3`:
- `XXX`: Three-digit identifier that determines the order which sound groups are accessed via the keyboard.
- `name`: Descriptive name of the sound list.
- `(Y)`: Index number within the sound group that determines the order of the sounds when played.

### Examples

- `001_Howl (1).wav` - First sound in the 'Howl' sound group for the Werewolf game.
- `002_Village (1).mp3` - Ambient village sound, enhancing the game setting.
- `003_Nightfall (1).wav` - Sound for nightfall, signaling a shift in the game phase.

## Setup and Configuration

1. **Download the Script**: Download `SoundKey.ps1` and other related script files to a folder on your computer.
2. **Prepare Audio Files**: Place your audio files in a designated folder. Ensure they are named according to the aforementioned naming convention.

## Usage

To use the application, follow these steps:

1. **Open PowerShell**: Navigate to the folder containing the script.
2. **Run the Script**:
   ```powershell
   ./SoundKey.ps1 -directoryPath "C:\Path\To\Your\Audio\Files"
   ```
   Replace `"C:\Path\To\Your\Audio\Files"` with the path to the folder containing your audio files.

3. **Control Sounds**:
   - Press designated keys to play or stop sounds based on their configurations.
   - Use special keys to manage playback:
     - `Escape` (Esc) - Immediately stop all sounds.
     - `F1` - Show the current sound table.
     - `F2` - Toggle looping of the current sound.
     - `F3` - Toggle stacking (parallel playback) of sounds.
     - `Delete` - Stop all sounds and exit the script.

## Game Master Keyboard Customization

To make the application user-friendly for the game master, small Post-it notes with drawings representing the sound list associated with each key were attached to the keyboard. This visual aid helps in quickly identifying which key to press to trigger the desired sound effect during the game.

## Exiting the Application

To exit the application, press the `Delete` key. This will stop all sounds and safely terminate the script.

## Contributing

Contributions to this project are welcome. Please fork the repository and submit a pull request with your enhancements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

