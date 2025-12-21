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

    # Ferme la fenêtre principale SoundKey si elle est active
function Exit-SoundKeyUI {
    Write-Host "Fermeture de l'interface SoundKey..."
    Write-Host "form : $($global:Form) viible : $($global:Form.Visible)"
    if ($global:Form -and $global:Form.Visible) {

        $global:Form.Close()
    }
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
        
            $ctrl.Tag = $fname
            $ctrl.Add_Click({
                param($s,$e)
        
                Write-verbose "Toggle Control '$($s.Tag)'"
                if ($specialFunctions.ContainsKey($s.Tag)) {
                    & $specialFunctions[$s.Tag].Action
                }

                if ($s.Tag -eq 'Escape') {
                    if (Get-Command -Name Hide-AllSoundProgressLabels -ErrorAction SilentlyContinue) {
                        Hide-AllSoundProgressLabels -Form $global:Form
                    }
                }

            })
            $ToggleControls[$fname] = $ctrl
        }
        else {
            # Simple Button
            $ctrl = New-Object System.Windows.Forms.Button
        
            $ctrl.Tag = $fname
            $ctrl.Add_Click({
                param($s,$e)
            
                Write-verbose "Toggle Control '$($s.Tag)'"
                if ($specialFunctions.ContainsKey($s.Tag)) {
                    & $specialFunctions[$s.Tag].Action
                }

                if ($s.Tag -eq 'Escape') {
                    if (Get-Command -Name Hide-AllSoundProgressLabels -ErrorAction SilentlyContinue) {
                        Hide-AllSoundProgressLabels -Form $global:Form
                    }
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

function Create-KeyLabel {
    param(
        [System.Windows.Forms.Form] $Form,
        [string]                    $KeyDisplay,
        [int]                       $ButtonX,
        [int]                       $ButtonY,
        [int]                       $ButtonWidth
    )
    # Crée un label circulaire vert avec la touche
    $keyLabel = New-Object System.Windows.Forms.Label
    $keyLabel.Text = $KeyDisplay
    $keyLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $keyLabel.ForeColor = [System.Drawing.Color]::White
    $keyLabel.BackColor = [System.Drawing.Color]::Green
    $keyLabel.TextAlign = 'MiddleCenter'
    $keyLabel.AutoSize = $false
    $keyLabel.Margin = New-Object System.Windows.Forms.Padding(0)
    $keyLabel.Padding = New-Object System.Windows.Forms.Padding(0)
    
    # Taille du cercle
    $circleSize = 40
    $keyLabel.Size = New-Object System.Drawing.Size($circleSize, $circleSize)
    $keyLabel.Tag = "KeyLabel"  # Tag pour identifier les labels lors du nettoyage
    
    # Position en haut à droite du bouton
    $labelX = $ButtonX + $ButtonWidth - $circleSize - 2
    $labelY = $ButtonY - 5
    $keyLabel.Location = New-Object System.Drawing.Point -ArgumentList $labelX, $labelY
    
    # Créer un chemin circulaire
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, $circleSize, $circleSize)
    $keyLabel.Region = New-Object System.Drawing.Region($path)
    $path.Dispose()
    
    $Form.Controls.Add($keyLabel)
    $keyLabel.BringToFront()
    
    return $keyLabel
}

function Create-SoundButton {
    param(
        [System.Windows.Forms.Form] $Form,
        [string]                    $Key,
        [string]                    $DisplayKey,
        [string]                    $Name,
        [System.Drawing.Size]       $Size,
        [int]                       $X,
        [int]                       $Y
    )
    # Crée le bouton de son
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "$DisplayKey`n$Name"
    $btn.Size      = $Size
    $btn.TextAlign = 'MiddleCenter'
    $btn.Tag       = $Key

    # Vérifie si une image correspondante existe basée sur "name" (png ou jpg)
    $imagePathPng = "soundkey-images/$Name.png"
    $imagePathJpg = "soundkey-images/$Name.jpg"
    if (Test-Path $imagePathPng) {
        $btn.BackgroundImage = [System.Drawing.Image]::FromFile($imagePathPng)
        $btn.BackgroundImageLayout = 'Stretch'
        Write-Verbose "Image ajoutée pour le son '$Name' : $imagePathPng"
    } elseif (Test-Path $imagePathJpg) {
        $btn.BackgroundImage = [System.Drawing.Image]::FromFile($imagePathJpg)
        $btn.BackgroundImageLayout = 'Stretch'
        Write-Verbose "Image ajoutée pour le son '$Name' : $imagePathJpg"
    } else {
        Write-Verbose "Aucune image trouvée pour le son '$Name'"
    }

    $btn.Location = New-Object System.Drawing.Point -ArgumentList $X, $Y
    $btn.Add_Click({ param($s,$e) Invoke-keyboard-Player -keySound $s.Tag -SequencePlay })
    $Form.Controls.Add($btn)
    
    return $btn
}

function Create-SoundProgressLabel {
    param(
        [System.Windows.Forms.Form] $Form,
        [string]                    $Key,
        [int]                       $CurrentIndex,
        [int]                       $TotalCount,
        [int]                       $ButtonX,
        [int]                       $ButtonY,
        [int]                       $ButtonWidth,
        [int]                       $ButtonHeight
    )
    # Crée un rectangle bleu avec le numéro de son (courant/total)
    # Toujours créer le label, même si aucun son n'est en cours
    $soundNum = $CurrentIndex + 1  # +1 car les indices commencent à 0
    $progressLabel = New-Object System.Windows.Forms.Label
    if ($CurrentIndex -ge 0 -and $CurrentIndex -lt $TotalCount) {
        $progressLabel.Text = "$soundNum/$TotalCount"
    } else {
        $progressLabel.Text = ""
        $progressLabel.Visible = $false
    }
    $progressLabel.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
    $progressLabel.ForeColor = [System.Drawing.Color]::White
    $progressLabel.BackColor = [System.Drawing.Color]::Blue
    $progressLabel.TextAlign = 'MiddleCenter'
    $progressLabel.AutoSize = $false
    $progressLabel.Margin = New-Object System.Windows.Forms.Padding(0)
    $progressLabel.Padding = New-Object System.Windows.Forms.Padding(2)
    
    # Taille du rectangle
    $labelWidth = 45
    $labelHeight = 25
    $progressLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $progressLabel.Tag = "SoundProgress:$Key"  # Tag pour identifier et mettre à jour
    
    # Position en bas à gauche du bouton
    $labelX = $ButtonX + 5
    $labelY = $ButtonY + $ButtonHeight - $labelHeight - 5
    $progressLabel.Location = New-Object System.Drawing.Point -ArgumentList $labelX, $labelY
    
    $Form.Controls.Add($progressLabel)
    $progressLabel.BringToFront()
    
    return $progressLabel
}

function Update-SoundProgressDisplay {
    param(
        [System.Windows.Forms.Form] $Form,
        [string]                    $Key,
        [int]                       $CurrentIndex,
        [int]                       $TotalCount
    )
    # Trouve et met à jour le label de progression
    $progressLabel = $Form.Controls | Where-Object { $_.Tag -eq "SoundProgress:$Key" }
    
    if ($null -ne $progressLabel) {
        if ($CurrentIndex -ge 0 -and $CurrentIndex -lt $TotalCount) {
            # Mettre à jour le texte
            $soundNum = $CurrentIndex + 1
            $progressLabel.Text = "$soundNum/$TotalCount"
            $progressLabel.Visible = $true
        } else {
            # Masquer le label quand aucun son ne joue
            $progressLabel.Visible = $false
        }
    }
}

function Clear-SoundProgressLabels {
    param(
        [System.Windows.Forms.Form] $Form,
        [string]                    $Key
    )
    # Supprime le label de progression pour une clé donnée
    $progressLabel = $Form.Controls | Where-Object { $_.Tag -eq "SoundProgress:$Key" }
    
    if ($null -ne $progressLabel) {
        $Form.Controls.Remove($progressLabel)
        $progressLabel.Dispose()
    }
}

function Hide-AllSoundProgressLabels {
    param(
        [System.Windows.Forms.Form] $Form
    )
    $labels = $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and ($_.Tag -like "SoundProgress:*") }
    foreach ($lbl in $labels) { $lbl.Visible = $false }
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
        $totalSounds = $list['players'].Count

        # Alias DN → N
        if ($key -match '^D(\d+)$') { $disp = $matches[1] } else { $disp = $key }

        $row = [math]::Floor($i / $columns)
        $col = $i % $columns
        $x   = $Margin + ($buttonWidth  + $Margin) * $col
        $y   = $GridStartY.Value + ($buttonHeight + $Margin) * $row

        $btnSize = New-Object System.Drawing.Size([math]::Floor($buttonWidth), [math]::Floor($buttonHeight))
        
        # Crée le bouton principal
        $btn = Create-SoundButton -Form $Form -Key $key -DisplayKey $disp -Name $name -Size $btnSize -X $x -Y $y
        
        # Crée le label circulaire avec la touche
        Create-KeyLabel -Form $Form -KeyDisplay $disp -ButtonX $x -ButtonY $y -ButtonWidth ([math]::Floor($buttonWidth))
        
        # Crée le label de progression en fonction de l'index courant
        Create-SoundProgressLabel -Form $Form -Key $key -CurrentIndex $list['lastSound'] -TotalCount $totalSounds -ButtonX $x -ButtonY $y -ButtonWidth ([math]::Floor($buttonWidth)) -ButtonHeight ([math]::Floor($buttonHeight))
    }
}
