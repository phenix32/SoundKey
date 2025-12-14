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
            $action = $spec.Action
            $ctrl.Add_Click({
                if ($action -is [scriptblock]) {
                    & $action
                } elseif ($action) {
                    Invoke-Expression $action
                }
            })
            $ToggleControls[$fname] = $ctrl
        }
        else {
            # Simple Button
            $ctrl = New-Object System.Windows.Forms.Button
            $action = $spec.Action
            $ctrl.Add_Click({
                if ($action -is [scriptblock]) {
                    & $action
                } elseif ($action) {
                    Invoke-Expression $action
                }
            })
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
        [ref]                       $GridStartY,
        [hashtable]                 $ToggleControls
    )
    # Filtre les clés actives (au moins un MediaPlayer)
    $activeKeys = $Keys |
        Where-Object { $SoundTable.ContainsKey($_) -and $SoundTable[$_]['players'].Count -gt 0 }

    # Calculer la taille des boutons en fonction de la taille de la fenêtre
    $availableWidth = $Form.ClientSize.Width - (2 * $Margin)
    $availableHeight = $Form.ClientSize.Height - $GridStartY.Value - $Margin

    $columns = [math]::Ceiling([math]::Sqrt($activeKeys.Count))
    $rows = [math]::Ceiling($activeKeys.Count / $columns)

    $buttonWidth = ($availableWidth - ($columns - 1) * $Margin) / $columns
    $buttonHeight = ($availableHeight - ($rows - 1) * $Margin) / $rows

    for ($i = 0; $i -lt $activeKeys.Count; $i++) {
        $key  = $activeKeys[$i]
        $list = $SoundTable[$key]
        $name = if ($list['name']) { $list['name'] } else { '' }

        # Alias DN → N
        if ($key -match '^D(\d+)$') { $disp = $matches[1] } else { $disp = $key }

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text      = "$disp`n$name"
        $btn.Size      = New-Object System.Drawing.Size([math]::Floor($buttonWidth), [math]::Floor($buttonHeight))
        $btn.TextAlign = 'MiddleCenter'
        $btn.Tag       = $key

        # Vérifie si une image correspondante existe basée sur "name" (png ou jpg)
        $imagePathPng = "soundkey-images/$name.png"
        $imagePathJpg = "soundkey-images/$name.jpg"
        if (Test-Path $imagePathPng) {
            $btn.BackgroundImage = [System.Drawing.Image]::FromFile($imagePathPng)
            $btn.BackgroundImageLayout = 'Stretch'
             Write-Verbose  "Image ajoutée pour le son '$name' : $imagePathPng"
        } elseif (Test-Path $imagePathJpg) {
            $btn.BackgroundImage = [System.Drawing.Image]::FromFile($imagePathJpg)
            $btn.BackgroundImageLayout = 'Stretch'
             Write-Verbose  "Image ajoutée pour le son '$name' : $imagePathJpg"
        } else {
             Write-Verbose  "Aucune image trouvée pour le son '$name'"
        }

        $row = [math]::Floor($i / $columns)
        $col = $i % $columns
        $x   = $Margin + ($buttonWidth  + $Margin) * $col
        $y   = $GridStartY.Value + ($buttonHeight + $Margin) * $row

        $btn.Location = New-Object System.Drawing.Point -ArgumentList $x, $y
        $btn.Add_Click({ param($s,$e) Invoke-keyboard-Player -keySound $s.Tag -SequencePlay })
        $Form.Controls.Add($btn)

        
    }
}
