#requires -version 3

<#
    .SYNOPSIS
        Changes EXIF and IPTC information from images (especially JPEGs) and can also add a copyright to them.
    .DESCRIPTION
        Uses exiftool by Phil Harvey (https://sno.phy.queensu.ca/~phil/exiftool/)
    .NOTES
        Version:        2.3
        Author:         flolilo
        Creation Date:  2018-03-06

    .INPUTS
        files.
    .OUTPUTS
        the same files.

    .PARAMETER InputPath
        Path where images should be searched and edited (default: current path of console).
    .PARAMETER Filter
        Filter for files. E.g. "*IMG_*" for all files with IMG_ in their name.
    .PARAMETER EXIFtool
        Path to Exiftool.exe.
    .PARAMETER Debug
        Add a bit of verbose information about variables.

    .EXAMPLE
        exif_transfer -Filter "*image_525*" -EXIFtool "C:\exiftool.exe"
#>
param(
    [ValidateNotNullOrEmpty()]
    [array]$InputPath =     @("$((Get-Location).Path)"),
    [string]$Formats =      "*",
    [string]$EXIFtool =     "$($PSScriptRoot)\exiftool.exe",
    [int]$Debug =           0
)
# DEFINITION: Combine all parameters into a hashtable, then delete the parameter variables:
    [hashtable]$UserParams = @{
        InputPath = $InputPath
        Formats = $Formats
        EXIFtool = $EXIFtool
    }
    Remove-Variable -Name InputPath,Formats,EXIFtool

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
# DEFINITION: version number:
    $VersionNumber = "v2.3 - 2018-03-06"


# ==================================================================================================
# ==============================================================================
#    Defining generic functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Making Write-ColorOut much, much faster:
Function Write-ColorOut(){
    <#
        .SYNOPSIS
            A faster version of Write-ColorOut
        .DESCRIPTION
            Using the [Console]-commands to make everything faster.
        .NOTES
            Date: 2018-03-12
        
        .PARAMETER Object
            String to write out
        .PARAMETER ForegroundColor
            Color of characters. If not specified, uses color that was set before calling. Valid: White (PS-Default), Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkMagenta, DarkBlue
        .PARAMETER BackgroundColor
            Color of background. If not specified, uses color that was set before calling. Valid: DarkMagenta (PS-Default), White, Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkBlue
        .PARAMETER NoNewLine
            When enabled, no line-break will be created.

        .EXAMPLE
            Just use it like Write-ColorOut.
    #>
    param(
        [string]$Object = "Write-ColorOut was called, but no string was transfered.",

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$ForegroundColor,

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$BackgroundColor,

        [switch]$NoNewLine=$false,

        [ValidateRange(0,48)]
        [int]$Indentation=0
    )

    if($ForegroundColor.Length -ge 3){
        $old_fg_color = [Console]::ForegroundColor
        [Console]::ForegroundColor = $ForegroundColor
    }
    if($BackgroundColor.Length -ge 3){
        $old_bg_color = [Console]::BackgroundColor
        [Console]::BackgroundColor = $BackgroundColor
    }
    if($Indentation -gt 0){
        [Console]::CursorLeft = $Indentation
    }

    if($NoNewLine -eq $false){
        [Console]::WriteLine($Object)
    }else{
        [Console]::Write($Object)
    }
    
    if($ForegroundColor.Length -ge 3){
        [Console]::ForegroundColor = $old_fg_color
    }
    if($BackgroundColor.Length -ge 3){
        [Console]::BackgroundColor = $old_bg_color
    }
}

# DEFINITION: For the auditory experience:
Function Start-Sound(){
    <#
        .SYNOPSIS
            Gives auditive feedback for fails and successes
        .DESCRIPTION
            Uses SoundPlayer and Windows's own WAVs to play sounds.
        .NOTES
            Date: 2018-03-12

        .PARAMETER Success
            1 plays Windows's "tada"-sound, 0 plays Windows's "chimes"-sound.
        
        .EXAMPLE
            For success: Start-Sound 1
        .EXAMPLE
            For fail: Start-Sound 0
    #>
    param(
        [int]$Success = $(return $false)
    )
    try{
        $sound = New-Object System.Media.SoundPlayer -ErrorAction stop
        if($Success -eq 1){
            $sound.SoundLocation = "C:\Windows\Media\tada.wav"
        }else{
            $sound.SoundLocation = "C:\Windows\Media\chimes.wav"
        }
        $sound.Play()
    }catch{
        Write-Output "`a"
    }
}

# DEFINITION: Pause in Debug:
Function Invoke-Pause(){
    if($script:Debug -ne 0){
        Pause
    }
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    param(
        [ValidateRange(1,999999999)]
        [int]$PSPID = 999999999
    )
    Write-ColorOut "Exiting - This could take some seconds. Please do not close this window!" -ForegroundColor Magenta
    if($PSPID -ne 999999999){
        Stop-Process -Id $PSPID -ErrorAction SilentlyContinue
    }
    if($script:Debug -gt 0){
        Pause
    }

    $Host.UI.RawUI.WindowTitle = "Windows PowerShell"
    Exit
}

# DEFINITION: Start equivalent to PreventSleep.ps1:
Function Invoke-PreventSleep(){
    <#
        .NOTES
            v1.0 - 2018-02-22
    #>
    Write-ColorOut "$(Get-CurrentDate)  --  Starting preventsleep-script..." -ForegroundColor Cyan

$standby = @'
    # DEFINITION: For button-emulation:
    Write-Host "(PID = $("{0:D8}" -f $pid))" -ForegroundColor Gray
    $MyShell = New-Object -ComObject "Wscript.Shell"
    while($true){
        # DEFINITION:/CREDIT: https://superuser.com/a/1023836/703240
        $MyShell.sendkeys("{F15}")
        Start-Sleep -Seconds 90
    }
'@
    $standby = [System.Text.Encoding]::Unicode.GetBytes($standby)
    $standby = [Convert]::ToBase64String($standby)

    [int]$preventstandbyid = (Start-Process powershell -ArgumentList "-EncodedCommand $standby" -WindowStyle Hidden -PassThru).Id
    if($script:Debug -gt 0){
        Write-ColorOut "preventsleep-PID is $("{0:D8}" -f $preventstandbyid)" -ForegroundColor Gray -BackgroundColor DarkGray -Indentation 4
    }
    Start-Sleep -Milliseconds 25
    if((Get-Process -Id $preventstandbyid -ErrorVariable SilentlyContinue).count -ne 1){
        Write-ColorOut "Cannot prevent standby" -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 3
    }

    return $preventstandbyid
}

# DEFINITION: Getting date and time in pre-formatted string:
Function Get-CurrentDate(){
    return $(Get-Date -Format "yy-MM-dd HH:mm:ss")
}


# ==================================================================================================
# ==============================================================================
#    Defining specific functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Get user-values:
Function Test-UserValues(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Test-UserValues')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Testing EXE-path..." -ForegroundColor Cyan

    # DEFINITION: Search for exiftool:
    if((Test-Path -LiteralPath $UserParams.EXIFtool -PathType Leaf) -eq $false){
        if((Test-Path -LiteralPath "$($PSScriptRoot)\exiftool.exe" -PathType Leaf) -eq $true){
            [string]$UserParams.EXIFtool = "$($PSScriptRoot)\exiftool.exe"
        }else{
            Write-ColorOut "Exiftool not found - aborting!" -ForegroundColor Red -Indentation 2
            Start-Sound -Success 0
            Start-Sleep -Seconds 5
            return $false
        }
    }
    if((Test-Path -LiteralPath $UserParams.InputPath -PathType Container) -eq $false){
        Write-ColorOut "$($UserParams.InputPath) not found - aborting!" -ForegroundColor Red -Indentation 2
        Start-Sound -Success 0
        Start-Sleep -Seconds 5
        return $false
    }

    return $UserParams
}

# DEFINITION: Get user-values:
Function Get-InputFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-InputFiles')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting files..." -ForegroundColor Cyan

    [array]$original = @()
    [array]$jpg = @()
    [array]$WorkingFiles = @(Get-ChildItem -LiteralPath $UserParams.InputPath -Filter $UserParams.Filter -File | ForEach-Object {
        [PSCustomObject]@{
            BaseName = $_.BaseName
            FullName = $_.FullName
        }
    })

    [array]$WorkingFiles = @($WorkingFiles | Group-Object -Property BaseName | Where-Object {$_.Count -gt 1})

    for($i=0; $i -lt $WorkingFiles.Length; $i++){
        if($WorkingFiles[$i].Group.FullName.Length -gt 2){
            [array]$inter = @($WorkingFiles[$i].Group.FullName | Where-Object {$_ -notmatch ".jpg" -and $_ -notmatch ".jpeg"})

            Write-ColorOut "More than one source-file found. Please choose between:" -ForegroundColor Yellow -Indentation 2
            for($k=0; $k -lt $inter.Length; $k++){
                Write-ColorOut "$k - $($inter[$k])" -ForegroundColor Gray -Indentation 4
            }
            [int]$choice = 999
            while($choice -notin (0..$inter.Length)){
                try{
                    Write-ColorOut "Which one do you want?`t" -ForegroundColor Yellow -NoNewLine -Indentation 2
                    [int]$choice = Read-Host
                }catch{
                    Write-ColorOut "Wrong input!" -ForegroundColor Red -Indentation 4
                    continue
                }
            }
            $original += @($inter[$choice])
        }else{
            $original += @($WorkingFiles[$i].Group.FullName | Where-Object {$_ -notmatch ".jpg" -and $_ -notmatch ".jpeg"})
        }
        $jpg += @($WorkingFiles[$i].Group.FullName | Where-Object {$_ -match ".jpg" -or $_ -match ".jpeg"})
    }

    for($i=0; $i -lt $original.Length; $i++){
        Write-ColorOut "From:`t$($original[$i].Replace("$($UserParams.InputPath)","."))" -ForegroundColor Gray -Indentation 4
        Write-ColorOut "To:`t`t  $($jpg[$i].Replace("$($UserParams.InputPath)","."))" -Indentation 4
    }

    [array]$WorkingFiles = @()
    for($i=0; $i -lt $original.Length; $i++){
        $WorkingFiles += [PSCustomObject]@{
            SourceFullName = $original[$i]
            JPEGFullName = $jpg[$i]
        }
    }

    return $WorkingFiles
}

Function Start-Transfer(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-Transfer'),
        [ValidateNotNullOrEmpty()]
        [array]$WorkingFiles = $(throw 'WorkingFiles is required by Start-Transfer')
    )
    # DEFINITION: Create Exiftool process:
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $UserParams.EXIFtool
    $psi.Arguments = "-stay_open True -@ -"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $exiftoolproc = [System.Diagnostics.Process]::Start($psi)
    Start-Sleep -Seconds 1

    Write-ColorOut "$(Get-CurrentDate)  --  Transfering metadata..." -ForegroundColor Cyan
    $sw = [diagnostics.stopwatch]::StartNew()
    if($script:Debug -gt 0){
        [string]$debuginter = "$((Get-Location).Path)"
    }
    [int]$errorcounter = 0

    # DEFINITION: Pass arguments to Exiftool:
    for($i=0; $i -lt $WorkingFiles.length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Transfering metadata..." -Status "File # $i - $($WorkingFiles[$i].jpg)" -PercentComplete $($i * 100 / $WorkingFiles.length)
            $sw.Reset()
            $sw.Start()
        }

        [string]$ArgList = "-tagsfromfile`n$($WorkingFiles[$i].SourceFullName)`n-All:All`n-xresolution=300`n-yresolution=300`n-overwrite_original`n$($WorkingFiles[$i].JPEGFullName)"
        if($script:Debug -gt 0){
            Write-ColorOut $ArgList.Replace("`n"," ").Replace("$debuginter",".") -ForegroundColor DarkGray -Indentation 4
        }
        $exiftoolproc.StandardInput.WriteLine("$ArgList`n-execute`n")
    }
    $exiftoolproc.StandardInput.WriteLine("-stay_open`nFalse`n")

    [array]$outputerror = @($exiftoolproc.StandardError.ReadToEnd().Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))
    [string]$outputout = $exiftoolproc.StandardOutput.ReadToEnd()
    $outputout = $outputout -replace '========\ ','' -replace '\[1/1]','' -replace '\ \r\n\ \ \ \ '," - " -replace '{ready}\r\n',''
    [array]$outputout = @($outputout.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))

    $exiftoolproc.WaitForExit()
    Write-Progress -Activity "Transfering metadata..." -Status "Complete!" -Completed

    for($i=0; $i -lt $WorkingFiles.length; $i++){
        Write-ColorOut "$($WorkingFiles[$i].JPEGFullName.Replace("$script:InputPath",".")):`t" -ForegroundColor Gray -NoNewLine -Indentation 2
        if($outputerror[$i].Length -gt 0){
            Write-ColorOut "$($outputerror[$i])`t" -ForegroundColor Red -NoNewline
            $errorcounter++
        }
        Write-ColorOut "$($outputout[$i])" -ForegroundColor Yellow
    }
    Write-Progress -Activity "Transfering metadata..." -Status "Done!" -Completed

    return $errorcounter
}

# DEFINITION: Start everything:
Function Start-Everything(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-Everything')
    )
    Write-ColorOut "                                              A" -BackgroundColor DarkGray -ForegroundColor DarkGray
    Write-ColorOut "         flolilo's EXIF transfer tool          " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "               $script:VersionNumber               " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))                               `r`n" -ForegroundColor Gray -BackgroundColor DarkGray
    $Host.UI.RawUI.WindowTitle = "EXIF transfer $script:VersionNumber"

    [int]$preventstandbyid = 999999999
    [int]$preventstandbyid = Invoke-PreventSleep

    $UserParams = Test-UserValues -UserParams $UserParams
    if($script:Debug -gt 1){
        $UserParams | Format-List
    }
    if($UserParams -eq $false -or $UserParams.GetType().Name -ne "hashtable"){
        Invoke-Close -PSPID $preventstandbyid
    }
    Invoke-Pause

    [array]$WorkingFiles = @(Get-InputFiles -UserParams $UserParams)
    if($WorkingFiles -eq $false){
        Start-Sound -Success 0
        Invoke-Close -PSPID $preventstandbyid
    }elseif($WorkingFiles.Length -le 0){
        Write-ColorOut "Zero files to process!" -ForegroundColor Yellow -Indentation 2
        Start-Sound -Success 1
        Start-Sleep 2
        Invoke-Close -PSPID $preventstandbyid
    }
    if($script:Debug -gt 1){
        $WorkingFiles | Format-Table -AutoSize
    }
    Write-ColorOut "Continue?`t" -ForegroundColor Yellow -NoNewLine -Indentation 2
    Pause

    if((Start-Transfer -UserParams $UserParams -WorkingFiles $WorkingFiles) -gt 0){
        Write-ColorOut "Errors occured in transfer" -ForegroundColor Red -Indentation 2
        Start-Sound -Success 0
        Start-Sleep -Seconds 2
        Invoke-Close -PSPID $preventstandbyid
    }
    Invoke-Pause

    Write-ColorOut "$(Get-CurrentDate)  --  Done!" -ForegroundColor Green
    Start-Sound -Success 1
    Start-Sleep -Seconds 5
    Invoke-Close -PSPID $preventstandbyid
}

Start-Everything -UserParams $UserParams
