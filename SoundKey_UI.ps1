# Charge les helpers
. ./SoundKey_UI_Functions.ps1

function Show-SoundKeyUI {
    param(
        [hashtable] $soundTable,
        [string[]]  $keys,
        [hashtable] $specialFunctions
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
        -GridStartY $gridStartY

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

    [void]$form.ShowDialog()
}
