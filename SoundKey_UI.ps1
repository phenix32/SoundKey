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

    # Lance un timer toutes les 100ms pour gérer les boucles
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({
        Update-loops
    })
    $timer.Start()

    # Layout parameters
    $margin      = 10
    $buttonSize  = New-Object System.Drawing.Size(100,60)
    $cols        = [math]::Floor(( $form.ClientSize.Width - 2*$margin ) / ( $buttonSize.Width + $margin ))
    $gridStartY  = $margin

    #
    # --- Special Function Keys en haut ---
    #
    $global:control = @()
    if ($specialFunctions) {
        $x = $margin
        foreach ($fname in $specialFunctions.Keys) {
            $spec = $specialFunctions[$fname]

            if ($spec.Toggle) {
                $ctrl = New-Object System.Windows.Forms.CheckBox
                $var = Get-Variable -Name ("${fname}Flag") -Scope Global -ErrorAction SilentlyContinue
                if ($var) { $ctrl.Checked = [bool]$var.Value }
                $ctrl.Tag = $spec.Action
                $ctrl.Add_CheckedChanged({ param($s,$e) & $s.Tag })
                $global:control += $ctrl
            }
            else {
                $ctrl = New-Object System.Windows.Forms.Button
                $ctrl.Tag = $spec.Action
                $ctrl.Add_Click({ param($s,$e) & $s.Tag })
            }

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
    # --- Boutons métier : ton bloc conservé ---
    #
    $activeKeys = $keys |
        Where-Object { $soundTable.ContainsKey($_) -and $soundTable[$_]['players'].Count -gt 0 }

    for ($i = 0; $i -lt $activeKeys.Count; $i++) {
        $key  = $activeKeys[$i]
        $list = $soundTable[$key]
        $name = if ($list['name']) { $list['name'] } else { '' }
        if ($key -match '^D(\d+)$') { $disp = "$($matches[1])" } else { $disp = $key }

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

            # manage the beavior after the key is pressed
            $spec = $specialFunctions[$k]
            if ($spec.Toggle) {
                $ctrl = $global:control | Where-Object { $_.Tag -eq $spec.Action }
                if ($ctrl) {
                    $ctrl.Checked = -not $ctrl.Checked                
                }

            } else {
                if ($spec.Action) { 
                   $running = & $spec.Action 
                   if (-not $running) {
                       $form.Close()
                   }
                }
            }

        } elseif ($keys -contains $k) {
            Invoke-keyboard-Player -keySound $k -SequencePlay
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
