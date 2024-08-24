# SoundKey Application for Werewolf Game (Les Loups-garous de Thiercelieux)

## below french version of this text

## Overview

The SoundKey Application is a PowerShell script tailored for enhancing the gaming experience of "Les Loups-garous de Thiercelieux," a popular social deduction game. By allowing the game master to trigger sound effects through keyboard inputs, this tool enriches the narrative and interaction during gameplay. For more details about the game, visit [Les Loups-garous de Thiercelieux on Wikipedia](https://fr.wikipedia.org/wiki/Les_Loups-garous_de_Thiercelieux).

it is also ideal for custom soundboards, interactive audio projects, or adding atmosphere to tabletop RPGs as a game master’s tool.

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




# -------------------------------------------------------------------
# Traduction en français :


# Application SoundKey pour le jeu Les Loups-garous de Thiercelieux

## Vue d'ensemble

L'application SoundKey est un script PowerShell conçu pour améliorer l'expérience de jeu des "Loups-garous de Thiercelieux", un jeu de déduction sociale populaire. En permettant au maître du jeu de déclencher des effets sonores via des entrées clavier, cet outil enrichit la narration et l'interaction pendant le jeu. Pour plus de détails sur le jeu, visitez [Les Loups-garous de Thiercelieux sur Wikipedia](https://fr.wikipedia.org/wiki/Les_Loups-garous_de_Thiercelieux).

Il est également idéal pour des tableaux de son personnalisés, des projets audio interactifs ou pour ajouter une ambiance aux jeux de rôle sur table en tant qu'outil pour le maître du jeu.

## Fonctionnalités

- **Cartographie du clavier personnalisable :** Adaptez le script à différentes dispositions de clavier (par exemple, QWERTY) en modifiant la variable globale `$keys`.
- **Utilisations clés spéciales :**
  - Touche `Escape` (Esc) pour arrêter immédiatement tous les sons en cours, utile pour couper rapidement tous les effets lorsque nécessaire.
  - Touche `Delete` pour arrêter tous les sons et quitter le script en toute sécurité.

## Prérequis

Pour exécuter ce script, vous aurez besoin :
- D'un système d'exploitation Windows avec PowerShell 5.1 ou ultérieur.
- De fichiers sonores nommés selon un format spécifique (`XXX_nom (Y).ext` où `XXX` est un identifiant de groupe, `nom` est un nom descriptif, et `(Y)` est l'indice du son dans le groupe).

## Convention de nommage des fichiers

Assurez-vous que vos fichiers sonores sont nommés selon le modèle `XXX_nom (Y).wav` ou `XXX_nom (Y).mp3` :
- `XXX` : Identifiant à trois chiffres qui détermine l'ordre d'accès aux groupes de sons via le clavier.
- `nom` : Nom descriptif de la liste de sons.
- `(Y)` : Numéro d'indice au sein du groupe de sons qui détermine l'ordre des sons lors de la lecture.

### Exemples

- `001_Howl (1).wav` - Premier son dans le groupe de sons 'Howl' pour le jeu des Loups-garous.
- `002_Village (1).mp3` - Son d'ambiance de village, améliorant le cadre du jeu.
- `003_Nightfall (1).wav` - Son pour la tombée de la nuit, signalant un changement de phase dans le jeu.

## Configuration et installation

1. **Téléchargez le script** : Téléchargez `SoundKey.ps1` et les autres fichiers de script associés dans un dossier sur votre ordinateur.
2. **Préparez les fichiers audio** : Placez vos fichiers audio dans un dossier désigné. Assurez-vous qu'ils sont nommés selon la convention de nommage mentionnée ci-dessus.

## Utilisation

Pour utiliser l'application, suivez ces étapes :

1. **Ouvrez PowerShell** : Naviguez jusqu'au dossier contenant le script.
2. **Exécutez le script** :
   ```powershell
   ./SoundKey.ps1 -directoryPath "C:\Chemin\Vers\Vos\Fichiers\Audio"
   ```
   Remplacez `"C:\Chemin\Vers\Vos\Fichiers\Audio"` par le chemin du dossier contenant vos fichiers audio.

3. **Contrôlez les sons** :
   - Appuyez sur les touches désignées pour jouer ou arrêter les sons selon leur configuration.
   - Utilisez des touches spéciales pour gérer la lecture :
     - `Escape` (Esc) - Arrêtez immédiatement tous les sons.
     - `F1` - Affichez la table des sons actuelle.
     - `F2` - Activez ou désactivez la boucle du son en cours.
     - `F3` - Activez ou désactivez la superposition (lecture parallèle) des sons.
     - `Delete` - Arrêtez tous les sons et quittez le script.

## Personnalisation du clavier pour le maître du jeu

Pour rendre l'application conviviale pour le maître du jeu, de petits post-it avec des dessins représentant la liste de sons associée à chaque touche ont été collés sur le clavier. Cette aide visuelle permet d'identifier rapidement quelle touche presser pour déclencher l'effet sonore désiré pendant le jeu.

## Quitter l'application

Pour quitter l'application, appuyez sur la touche `Delete`. Cela arrêtera tous les sons et terminera le script en toute sécurité.

## Contribuer

Les contributions à ce projet sont les bienvenues. Veuillez fork le dépôt et soumettre une pull request avec vos améliorations.

## Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.
