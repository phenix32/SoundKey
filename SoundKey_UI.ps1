function Show-SoundKeyUI {
    param(
        [hashtable] $soundTable,
        [string[]] $keys,
        [hashtable] $specialFunctions
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Initialise le Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text          = "SoundKey Interface"
    $form.Size          = New-Object System.Drawing.Size(800,600)
    $form.StartPosition = "CenterScreen"
    $form.KeyPreview    = $true

    # Layout parameters
    $margin      = 10
    $buttonSize  = New-Object System.Drawing.Size(100,60)
    $cols        = [math]::Floor(( $form.ClientSize.Width - 2*$margin ) / ( $buttonSize.Width + $margin ))
    # Position de départ du grid métier (sera décalée si specialFunctions existe)
    $gridStartY  = $margin

    #
    # --- Special Function Keys en haut ---
    #
# Special function keys en haut
    # --- Special Function Keys en haut ---
    if ($specialFunctions) {
        $x = $margin
        foreach ($fname in $specialFunctions.Keys) {
            $spec = $specialFunctions[$fname]

            if ($spec.Toggle) {
                $ctrl = New-Object System.Windows.Forms.CheckBox
                # état initial depuis la variable globale F?Flag
                $var = Get-Variable -Name ("${fname}Flag") -Scope Global -ErrorAction SilentlyContinue
                if ($var) { $ctrl.Checked = [bool]$var.Value }

                # stocke l’action et déclenche sur CheckedChanged
                $ctrl.Tag = $spec.Action
                $ctrl.Add_CheckedChanged({ param($s,$e) & $s.Tag })
            }
            else {
                $ctrl = New-Object System.Windows.Forms.Button
                $ctrl.Tag = $spec.Action
                $ctrl.Add_Click({ param($s,$e) & $s.Tag })
            }

            # propriétés communes
            $ctrl.Text      = "$fname`n$($spec.Description)"
            $ctrl.TextAlign = 'MiddleCenter'
            $ctrl.AutoSize  = $false
            $ctrl.Size      = $buttonSize
            $ctrl.Location  = New-Object System.Drawing.Point($x, $margin)
            $form.Controls.Add($ctrl)

            $x += $buttonSize.Width + $margin
        }
        $gridStartY += $buttonSize.Height + $margin
    }

    #
    # --- Boutons métier : on garde TON code tel quel ---
    #
    # Filter keys with associated sounds
    $activeKeys = $keys |
        Where-Object { $soundTable.ContainsKey($_) -and $soundTable[$_]['players'].Count -gt 0 }

    # Create sound buttons in grid
    for ($i = 0; $i -lt $activeKeys.Count; $i++) {
        $key  = $activeKeys[$i]
        $list = $soundTable[$key]
        $name = if ($list['name']) { $list['name'] } else { '' }
        # Alias DxN -> DN (drop 'x')
        if ($key -match '^Dx(\d+)$') { $disp = "$($matches[1])" } else { $disp = $key }

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text      = "$disp`n$name"
        $btn.Size      = $buttonSize
        $btn.TextAlign = 'MiddleCenter'
        $btn.Tag       = $key

        $row = [math]::Floor($i / $cols)
        $col = $i % $cols
        $x   = $margin + ( $buttonSize.Width  + $margin ) * $col
        $y   = $gridStartY + ( $buttonSize.Height + $margin ) * $row
        $btn.Location = New-Object System.Drawing.Point -ArgumentList $x, $y
        $btn.Add_Click({ param($s,$e) Invoke-keyboard-Player -keySound $s.Tag -SequencePlay })
        $form.Controls.Add($btn)
    }

    # KeyDown : jouer aussi au clavier
    $form.Add_KeyDown({
        param($s,$e)
        $k = $e.KeyCode.ToString()
        if ($specialFunctions.ContainsKey($k)) {
            & $specialFunctions[$k].Action
        } elseif ($soundTable.ContainsKey($k)) {
            Invoke-keyboard-Player -keySound $k -SequencePlay
        }
    })

    [void]$form.ShowDialog()
}

<# Usage:
. "./SoundKey.ps1"
$audioFiles = Get-ChildItem -Path 'C:\audio' -Filter '*.wav' -Recurse
$keys       = @('A','S','D','F','G','H','J','K','D1','D2')
$special    = @{
    'F1'     = { Show-SoundTable -soundTable $soundTable -keys $keys }
    'F2'     = { $global:loopFlag = -not $global:loopFlag }
    'F3'     = { $global:StackFlag = -not $global:StackFlag }
    'Escape' = { Stop-AllSound }
    'Delete' = { Stop-AllSound; [System.Windows.Forms.Application]::Exit() }
}
Create-SoundTable -audioFiles $audioFiles -keys $keys -soundTable $soundTable
Show-SoundKeyUI -soundTable $soundTable -keys $keys -specialFunctions $special
#>
