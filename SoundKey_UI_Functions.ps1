<#
    Helper functions for SoundKey UI
#>

function Initialize-LoopTimer {
    param(
        [hashtable]$ToggleControls,
        [int]     $IntervalMs = 100
    )
    # Creates and starts a WinForms timer that:
    # 1) calls Update-loops()
    # 2) synchronises chaque CheckBox toggle sur la valeur de $global:<Name>Flag
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = $IntervalMs
    $timer.Add_Tick({
        Update-loops
        foreach ($fname in $ToggleControls.Keys) {
            $ctrl    = $ToggleControls[$fname]
            $varName = "${fname}Flag"
            $var     = Get-Variable -Name $varName -Scope Global -ErrorAction SilentlyContinue
            if ($var) {
                $desired = [bool]$var.Value
                if ($ctrl.Checked -ne $desired) {
                    $ctrl.Checked = $desired
                }
            }
        }
    })
    
    $timer.Start()
    $script:__SoundKey_LoopTimer = $timer
    return $timer
}

function Create-SpecialFunctionControls {
    param(
        [System.Windows.Forms.Form] $Form,
        [hashtable]                 $SpecialFunctions,
        [int]                       $Margin,
        [System.Drawing.Size]       $ButtonSize,
        [ref]                       $GridStartY,
        [hashtable]                 $ToggleControls
    )
    # Place all special-function buttons/checkboxes in a row at the top,
    # puis décale $GridStartY en sortie.
    $x = $Margin
    foreach ($fname in $SpecialFunctions.Keys) {
        $spec = $SpecialFunctions[$fname]

        if ($spec.Toggle) {
            # Toggle → CheckBox
            $ctrl = New-Object System.Windows.Forms.CheckBox
            $var  = Get-Variable -Name ("${fname}Flag") -Scope Global -ErrorAction SilentlyContinue
            if ($var) { $ctrl.Checked = [bool]$var.Value }
            $ctrl.Add_Click({ & $spec.Action })
            $ToggleControls[$fname] = $ctrl
        }
        else {
            # Simple Button
            $ctrl = New-Object System.Windows.Forms.Button
            $ctrl.Add_Click({ & $spec.Action })
        }

        # Propriétés communes
        $ctrl.Text      = "$fname`n$($spec.Description)"
        $ctrl.TextAlign = 'MiddleCenter'
        $ctrl.AutoSize  = $false
        $ctrl.Size      = $ButtonSize
        $ctrl.Location  = New-Object System.Drawing.Point($x, $Margin)
        $Form.Controls.Add($ctrl)

        $x += $ButtonSize.Width + $Margin
    }

    # On décale le grid des boutons métier
    $GridStartY.Value += $ButtonSize.Height + $Margin
}

function Create-SoundButtonsGrid {
    param(
        [System.Windows.Forms.Form] $Form,
        [hashtable]                 $SoundTable,
        [string[]]                  $Keys,
        [int]                       $Margin,
        [System.Drawing.Size]       $ButtonSize,
        [int]                       $Columns,
        [int]                       $GridStartY
    )
    # Filtre les clés actives (au moins un MediaPlayer)
    $activeKeys = $Keys |
        Where-Object { $SoundTable.ContainsKey($_) -and $SoundTable[$_]['players'].Count -gt 0 }

    for ($i = 0; $i -lt $activeKeys.Count; $i++) {
        $key  = $activeKeys[$i]
        $list = $SoundTable[$key]
        $name = if ($list['name']) { $list['name'] } else { '' }

        # Alias DN → N
        if ($key -match '^D(\d+)$') { $disp = $matches[1] } else { $disp = $key }

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text      = "$disp`n$name"
        $btn.Size      = $ButtonSize
        $btn.TextAlign = 'MiddleCenter'
        $btn.Tag       = $key

        $row = [math]::Floor($i / $Columns)
        $col = $i % $Columns
        $x   = $Margin + ($ButtonSize.Width  + $Margin) * $col
        $y   = $GridStartY + ($ButtonSize.Height + $Margin) * $row

        $btn.Location = New-Object System.Drawing.Point -ArgumentList $x, $y
        $btn.Add_Click({ param($s,$e) Invoke-keyboard-Player -keySound $s.Tag -SequencePlay })
        $Form.Controls.Add($btn)
    }
}
