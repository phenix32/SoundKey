# Charge les helpers
. ./SoundKey_UI_Functions.ps1

function Show-SoundKeyUI {
    param(
        [hashtable] $soundTable,
        [string[]]  $keys,
        [hashtable] $specialFunctions,
        [switch]    $Verbose
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Création du Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text          = "SoundKey Interface"
    $form.Size          = New-Object System.Drawing.Size(800,600)
    $form.StartPosition = "CenterScreen"
    $form.KeyPreview    = $true

    # Prépare la synchro des toggles
    $toggleControls = @{}

    # Démarre le timer (loop + sync flags)
    Initialize-LoopTimer -ToggleControls $toggleControls -IntervalMs 100

    # Paramètres de layout
    $margin     = 10
    $buttonSize = New-Object System.Drawing.Size(100,60)
    $cols       = [math]::Floor(( $form.ClientSize.Width - 2 * $margin ) / ( $buttonSize.Width + $margin ))
    $gridStartY = $margin

    # Ajoute les controls “Special Functions” en haut
    Create-SpecialFunctionControls `
        -Form $form `
        -SpecialFunctions $specialFunctions `
        -Margin $margin `
        -ButtonSize $buttonSize `
        -GridStartY ([ref]$gridStartY) `
        -ToggleControls $toggleControls

    # Crée la grille de boutons métiers
    Create-SoundButtonsGrid `
        -Form $form `
        -SoundTable $soundTable `
        -Keys $keys `
        -Margin $margin `
        -ButtonSize $buttonSize `
        -Columns $cols `
        -GridStartY ([ref]$gridStartY)

    # start timer
    Initialize-LoopTimer -ToggleControls $ToggleControls -IntervalMs 100

    # Gestion des frappes clavier
    $form.Add_KeyDown({
        param($s,$e)
        $k = $e.KeyCode.ToString()
        if ($specialFunctions.ContainsKey($k)) {
            & $specialFunctions[$k].Action
        }
        elseif ($soundTable.ContainsKey($k)) {
            Invoke-keyboard-Player -keySound $k -SequencePlay
        }
    })

    # Gestion du redimensionnement de la fenêtre avec délai
    $global:resizeTimer = $null
    $form.Add_Resize({
        if ($global:resizeTimer -ne $null -and $global:resizeTimer.Enabled) {
            $global:resizeTimer.Stop()
            $global:resizeTimer.Dispose()
        }

        $global:resizeTimer = New-Object System.Windows.Forms.Timer
        $global:resizeTimer.Interval = 300 # Attendre 300ms après la fin du redimensionnement
        $global:resizeTimer.Add_Tick({
            if ($global:resizeTimer -ne $null) {
                Write-Verbose "Redimensionnement terminé, mise à jour de la grille des boutons..."

                $global:resizeTimer.Stop()
                $global:resizeTimer.Dispose()
                $global:resizeTimer = $null

                # Recalculer le nombre de colonnes en fonction de la nouvelle taille de la fenêtre
                $cols = [math]::Floor(( $form.ClientSize.Width - 2 * $margin ) / ( $buttonSize.Width + $margin ))

                # Supprimer tous les anciens boutons avant de redessiner la grille
				# Suspendre le layout pour éviter les rafraîchissements intermédiaires
				$form.SuspendLayout()

				# Prendre un snapshot (array) des boutons à supprimer
				$buttonsToRemove = @(
				    $form.Controls |
				        Where-Object { ($_ -is [System.Windows.Forms.Button]) -and ($_.Tag -ne $null) }
				)

				foreach ($btn in $buttonsToRemove) {
				    try {
				        Write-Verbose "Suppression du bouton pour la clé '$($btn.Tag)'"
				        $form.Controls.Remove($btn)
				        $btn.Dispose()
				    } catch {
				        Write-Verbose "Erreur lors de la suppression d'un bouton : $_"
				    }
				}

				# Recréation des boutons en fonction de la nouvelle taille
				$GridStartY = $margin + $buttonSize.Height + $margin
				Create-SoundButtonsGrid `
				    -Form $form `
				    -SoundTable $soundTable `
				    -Keys $keys `
				    -Margin $margin `
				    -ButtonSize $buttonSize `
				    -Columns $cols `
				    -GridStartY ([ref]$GridStartY)

				# Rétablir le layout et forcer le rendu
				$form.ResumeLayout()
				$form.PerformLayout()
				$form.Refresh()
            }
        })
        $global:resizeTimer.Start()
    })

    [void]$form.ShowDialog()
}
