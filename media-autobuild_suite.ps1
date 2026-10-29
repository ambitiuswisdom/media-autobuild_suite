#requires -Version 5.1
<#
.SYNOPSIS
Sets up MSYS2 and builds FFmpeg and other media tools on Windows.
.DESCRIPTION
PowerShell 5.1 entry point, also compatible with PowerShell 7 on Windows.
The BAT launcher retains the default-option data read by the unchanged Bash helper.
Copyright (C) 2013 jb_alvarado. Licensed under GPL-3.0-or-later; see LICENSE.
.PARAMETER NonInteractive
Uses the existing INI and fails if a required answer is missing or invalid.
.PARAMETER ValidateOnly
Validates the existing configuration without writing files, downloading or building.
.EXAMPLE
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\media-autobuild_suite.ps1
.EXAMPLE
pwsh.exe -NoProfile -File .\media-autobuild_suite.ps1 -ValidateOnly
#>
[CmdletBinding()]
param([switch]$NonInteractive, [switch]$ValidateOnly)

function Write-Section([string]$Text) {
    Write-Host ('-' * 79)
    Write-Host $Text
    Write-Host ('-' * 79)
}

function Pause-Suite {
    if (-not $NonInteractive) { [void](Read-Host 'Press Enter to continue') }
}

function Write-Utf8File([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}

function Set-IniValue([string]$Key, [string]$Value) {
    if (-not $script:IniValues.ContainsKey($Key) -or $script:IniValues[$Key] -cne $Value) {
        $script:IniValues[$Key] = $Value
        $script:DeleteIni = $true
    }
}

function Read-IniFile {
    if (-not (Test-Path -LiteralPath $script:IniPath -PathType Leaf)) { return }
    foreach ($line in Get-Content -LiteralPath $script:IniPath) {
        if ($line -match '^\s*([^#;\s][^=]*)=(.*)$') {
            $script:IniValues[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

function Read-Choice($Definition) {
    $raw = [string]$script:IniValues[$Definition.Key]
    # Older suites had more Av1an choices; they now mean disabled.
    $number = 0
    if ($Definition.Key -eq 'av1an' -and
        [int]::TryParse($raw, [ref]$number) -and $number -gt 2) {
        $raw = '2'
    }
    while ($true) {
        $number = 0
        if ([int]::TryParse($raw, [ref]$number) -and
            $number -ge 1 -and $number -le $Definition.Max) {
            break
        }
        if ($NonInteractive -or $ValidateOnly) {
            throw ('Missing or invalid configuration value: {0}' -f $Definition.Key)
        }
        Write-Section $Definition.Question
        $raw = Read-Host $Definition.Prompt
    }
    Set-IniValue $Definition.Key ([string]$number)
    $script:Config[$Definition.Name] = $Definition.Map[[string]$number]
}

function Resolve-SuitePath([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $resolved = Resolve-Path -LiteralPath $Value -ErrorAction SilentlyContinue
    if ($null -eq $resolved) { return $Value }
    $path = $resolved.Path.Replace('\', '/')
    if ($path -match '^([A-Za-z]):(.*)$') {
        return ('/{0}{1}' -f $matches[1].ToLowerInvariant(), $matches[2])
    }
    return $path
}

function Convert-FFmpegOptions([string[]]$Options) {
    $out = foreach ($option in $Options) {
        if ($option.StartsWith('--')) { $option }
        elseif ($option.StartsWith('#--')) { $option }
        elseif ($option.StartsWith('#')) { '#--enable-' + $option.Substring(1) }
        else { '--enable-' + $option }
    }
    return ($out -join [Environment]::NewLine)
}

function Convert-MpvOptions([string[]]$Options) {
    $out = foreach ($option in $Options) {
        if ($option.StartsWith('-')) { $option }
        elseif ($option.StartsWith('#-')) { $option }
        elseif ($option.StartsWith('#')) { '#-D' + $option.Substring(1) + '=enabled' }
        else { '-D' + $option + '=enabled' }
    }
    return ($out -join [Environment]::NewLine)
}

function Get-DefaultOptions {
    # Read data only. Never evaluate the batch file or source it as PowerShell.
    $file = Join-Path $script:SuiteRoot 'media-autobuild_suite.bat'
    $text = (Get-Content -LiteralPath $file -Raw) -replace '\^\r?\n', ''
    $result = @{}
    foreach ($match in [regex]::Matches($text, '(?m)^set ((?:ffmpeg|mpv)_options_\w+)=(.*)\r?$')) {
        $value = $match.Groups[2].Value.Replace('"', '').Trim()
        $result[$match.Groups[1].Value] = @($value -split '\s+')
    }
    $names = @(
        'ffmpeg_options_builtin', 'ffmpeg_options_basic', 'ffmpeg_options_zeranoe'
        'ffmpeg_options_full', 'ffmpeg_options_full_shared'
        'mpv_options_builtin', 'mpv_options_basic', 'mpv_options_full'
    )
    foreach ($name in $names) {
        if (-not $result.ContainsKey($name)) {
            throw ('Missing default options: {0} in {1}' -f $name, $file)
        }
    }
    return $result
}

function New-OptionFiles {
    $defaults = Get-DefaultOptions
    $ffmpegBuiltin = $defaults.ffmpeg_options_builtin
    $ffmpegBasic = $defaults.ffmpeg_options_basic
    $ffmpegZeranoe = $defaults.ffmpeg_options_zeranoe
    $ffmpegFull = $defaults.ffmpeg_options_full
    $ffmpegShared = $defaults.ffmpeg_options_full_shared
    $mpvBuiltin = $defaults.mpv_options_builtin
    $mpvBasic = $defaults.mpv_options_basic
    $mpvFull = $defaults.mpv_options_full

    $ffmpeg = @(
        '# Lines starting with this character are ignored'
        '# To override shared build options, create ffmpeg_options_shared.txt'
        ''
        '# Basic built-in options, removable with --disable-autodetect'
        (Convert-FFmpegOptions $ffmpegBuiltin)
        ''
        '# Common options'
        (Convert-FFmpegOptions $ffmpegBasic)
        ''
        '# Zeranoe'
        (Convert-FFmpegOptions $ffmpegZeranoe)
        ''
        '# Full'
        (Convert-FFmpegOptions $ffmpegFull)
        ''
        '# Full plus options that add shared dependencies'
        (Convert-FFmpegOptions $ffmpegShared)
    ) -join [Environment]::NewLine
    $mpv = @(
        '# Lines starting with this character are ignored'
        ''
        '# Built-in options, use =disabled to disable them'
        (Convert-MpvOptions $mpvBuiltin)
        ''
        '# Common options or overriden defaults'
        (Convert-MpvOptions $mpvBasic)
        ''
        '# Full'
        (Convert-MpvOptions $mpvFull)
    ) -join [Environment]::NewLine
    $ffmpegPath = Join-Path $script:BuildRoot 'ffmpeg_options.txt'
    if (-not (Test-Path -LiteralPath $ffmpegPath)) {
        Write-Utf8File $ffmpegPath ($ffmpeg + "`n")
        Write-Section ('File with default FFmpeg options was created in {0}' -f $ffmpegPath)
        Pause-Suite
    }
    $mpvPath = Join-Path $script:BuildRoot 'mpv_options.txt'
    if (Test-Path -LiteralPath $mpvPath) {
        if ((Get-Content -LiteralPath $mpvPath -Raw) -match '--enable-cplayer') {
            $backupName = (Get-Date -Format 'yyyy-MM-dd--HH-mm-ss') + '-mpv_options.txt'
            $renamed = Join-Path $script:BuildRoot $backupName
            Move-Item -LiteralPath $mpvPath -Destination $renamed -Force
            Write-Host ('Old mpv_options.txt was renamed to {0}' -f $renamed)
        }
    }
    if (-not (Test-Path -LiteralPath $mpvPath)) {
        Write-Utf8File $mpvPath ($mpv + "`n")
        Write-Section ('File with default mpv options was created in {0}' -f $mpvPath)
        Pause-Suite
    }
}

function ConvertTo-NativeArgument([AllowEmptyString()][string]$Value) {
    # ProcessStartInfo.Arguments uses Windows command-line quoting on both hosts.
    $quoted = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    return '"' + [regex]::Replace($quoted, '(\\+)$', '$1$1') + '"'
}

function Invoke-SuiteProcess {
    param([string]$FilePath, [string[]]$Arguments = @(), [switch]$Detach)
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $FilePath
    $info.Arguments = ($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
    $info.WorkingDirectory = $script:SuiteRoot
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        try { $process.PriorityClass = [Diagnostics.ProcessPriorityClass]::Idle } catch { }
        if ($Detach) { return 0 }
        $process.WaitForExit()
        return $process.ExitCode
    } finally { $process.Dispose() }
}

function ConvertTo-BashArgument([AllowEmptyString()][string]$Value) {
    # Single quotes prevent expansion of repository fragments and shell metacharacters.
    $replacement = "'" + '"' + "'" + '"' + "'"
    return "'" + $Value.Replace("'", $replacement) + "'"
}

function Invoke-Bash {
    param(
        [string]$LogName,
        [string]$Command,
        [string[]]$Arguments = @(),
        [switch]$Compile
    )
    $bash = Join-Path $script:SuiteRoot 'msys64\usr\bin\bash.exe'
    $logPath = Join-Path $script:BuildRoot $LogName
    $quotedArgs = (@($Command) + $Arguments) | ForEach-Object { ConvertTo-BashArgument $_ }
    $commandLine = $quotedArgs -join ' '
    if ($script:NoMintty) {
        # The drive-mounted path also works before /build has been initialized.
        $temporaryName = 'mabs-run-' + [guid]::NewGuid().ToString('N') + '.sh'
        $temporary = Join-Path $script:BuildRoot $temporaryName
        Write-Utf8File $temporary ("#!/bin/bash`n" + $commandLine + "`n")
        try {
            $unixPath = Resolve-SuitePath $temporary
            $bashArgs = @(
                (Join-Path $script:BuildRoot 'bash.sh'), $logPath, '/usr/bin/bash', $unixPath
            )
            $previousErrorAction = $ErrorActionPreference
            $previousOutputEncoding = [Console]::OutputEncoding
            Push-Location -LiteralPath $script:SuiteRoot -ErrorAction Stop
            try {
                # Decode MSYS2 output as UTF-8, regardless of the Windows console code page.
                [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
                # Keep native output visible without mixing it into the exit-code result.
                $ErrorActionPreference = 'Continue'
                $global:LASTEXITCODE = $null
                & $bash @bashArgs 2>&1 |
                    ForEach-Object { $_.ToString() } |
                    Out-Host
                if ($null -eq $global:LASTEXITCODE) {
                    throw ('Could not start MSYS2 Bash: ' + $bash)
                }
                return $global:LASTEXITCODE
            } finally {
                $ErrorActionPreference = $previousErrorAction
                [Console]::OutputEncoding = $previousOutputEncoding
                Pop-Location
            }
        } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
    $mintty = Join-Path $script:SuiteRoot 'msys64\usr\bin\mintty.exe'
    $minttyArgs = @(
        '-i', '/msys2.ico', '-t', 'media-autobuild_suite', '--log', $logPath
        '/usr/bin/bash', '-lc', $commandLine
    )
    if ($Compile) { return Invoke-SuiteProcess $mintty $minttyArgs -Detach }
    return Invoke-SuiteProcess $mintty (@('-d') + $minttyArgs)
}

function Invoke-SuiteDownload([string]$Uri, [string]$Destination) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $parent = Split-Path -Parent $Destination
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $client = New-Object Net.WebClient
    try { $client.DownloadFile($Uri, $Destination) }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw
    } finally { $client.Dispose() }
}

function Invoke-Pacman([string[]]$Arguments) {
    $pacman = Get-Command pacman -CommandType Application -ErrorAction SilentlyContinue
    if (-not $pacman) { throw 'pacman was not found in the MSYS2 PATH.' }
    & $pacman.Source @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw ('pacman failed with exit code {0}.' -f $LASTEXITCODE) }
}

function Initialize-BaseFolders {
    $local = Join-Path $script:SuiteRoot 'local64'
    if (Test-Path -LiteralPath (Join-Path $local 'share')) { return }
    Write-Section 'creating 64-bit install folders'
    $folders = @(
        '', 'bin', 'bin-audio', 'bin-global', 'bin-video'
        'etc', 'include', 'lib', 'lib\pkgconfig', 'share'
    )
    foreach ($folder in $folders) {
        New-Item -ItemType Directory -Path (Join-Path $local $folder) -Force | Out-Null
    }
}

function Write-Profile([string]$Compiler) {
    $msystem = if ($Compiler -eq 'clang') { 'CLANG64' } else { 'UCRT64' }
    $cc = if ($Compiler -eq 'clang') {
        'export CC="ccache clang"'
        'export CXX="ccache clang++"'
        'export AR="llvm-ar"'
    } else {
        'export CC="ccache gcc"'
        'export CXX="ccache g++"'
        'export AR="gcc-ar"'
    }
    $lines = @(
        '#!/usr/bin/bash'
        ('MSYSTEM={0}' -f $msystem)
        'source /etc/msystem'
        ''
        "export LOCALBUILDDIR='/build'"
        "export LOCALDESTDIR='/local64'"
        "bits='64bit'"
        'export CONFIG_SITE=/etc/config.site'
        "alias dir='ls -la --color=auto'"
        "alias ls='ls --color=auto'"
    ) + $cc + @(
        ''
        'CARCH="${MINGW_CHOST%%-*}"'
        'C_INCLUDE_PATH="$(cygpath -pm $LOCALDESTDIR/include:$MINGW_PREFIX/include)"'
        'CPLUS_INCLUDE_PATH="$(cygpath -pm $LOCALDESTDIR/include)"'
        'export C_INCLUDE_PATH CPLUS_INCLUDE_PATH'
        'MANPATH="${LOCALDESTDIR}/share/man:${MINGW_PREFIX}/share/man:/usr/share/man"'
        'INFOPATH="${LOCALDESTDIR}/share/info:${MINGW_PREFIX}/share/info:/usr/share/info"'
        'DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"'
        ('ACLOCAL_PATH="${LOCALDESTDIR}/share/aclocal:' +
            '${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"')
        'PKG_CONFIG="${MINGW_PREFIX}/bin/pkgconf --keep-system-cflags --static"'
        'PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"'
        ('CFLAGS="-D_FORTIFY_SOURCE=2 -fstack-protector-strong' +
            ' -mtune=generic -O3 -pipe -march=x86-64-v3 -D__USE_MINGW_ANSI_STDIO=1"')
        'CXXFLAGS="${CFLAGS}"'
        'LDFLAGS="${CFLAGS} -static-libgcc"'
        'case "$CC" in'
        '*clang)'
        '    LDFLAGS+=" --start-no-unused-arguments -static-libstdc++ --end-no-unused-arguments"'
        '    CFLAGS+=" --start-no-unused-arguments -mthreads --end-no-unused-arguments"'
        '    CFLAGS+=" -Qunused-arguments"'
        '    ;;'
        '*gcc)'
        '    LDFLAGS+=" -static-libstdc++"'
        '    CFLAGS+=" -mthreads"'
        '    ;;'
        'esac'
        'export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CFLAGS CXXFLAGS LDFLAGS'
        'export CARGO_HOME="/opt/cargo"'
        ('if [[ -z "${MABS_ORIGINAL_RUSTFLAGS+x}" ]]; then ' +
            'MABS_ORIGINAL_RUSTFLAGS="$RUSTFLAGS"; fi')
        ('export RUSTFLAGS="${MABS_ORIGINAL_RUSTFLAGS:+$MABS_ORIGINAL_RUSTFLAGS }' +
            '-C target-cpu=x86-64-v3"')
        'if [[ -z "$CCACHE_DIR" ]]; then CCACHE_DIR="${LOCALBUILDDIR}/cache"; fi'
        'export CCACHE_DIR'
        'export PYTHONPATH='
        'LANG=en_US.UTF-8'
        'PATH="${MINGW_PREFIX}/bin:${INFOPATH}:${MSYS2_PATH}:${ORIGINAL_PATH}"'
        ('PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:' +
            '${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${PATH}"')
        'PATH="/opt/bin:${PATH}"'
        "source '/etc/profile.d/perlbin.sh'"
        "PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '"
        'HOME="/home/${USERNAME}"'
        'export LANG PATH PS1 HOME'
        'stty susp undef'
        'test -f "$LOCALDESTDIR/etc/custom_profile" && source "$LOCALDESTDIR/etc/custom_profile"'
    )
    $path = Join-Path $script:SuiteRoot 'local64\etc\profile2.local'
    Write-Utf8File $path ($lines -join "`n")
    $dos2unix = Join-Path $script:SuiteRoot 'msys64\usr\bin\dos2unix.exe'
    if (Test-Path -LiteralPath $dos2unix) { & $dos2unix -q $path }
}

function Initialize-Msys2 {
    $root = Join-Path $script:SuiteRoot 'msys64'
    $msysShell = Join-Path $root 'msys2_shell.cmd'
    if (-not (Test-Path -LiteralPath $msysShell)) {
        Write-Section 'Download and install msys2 basic system'
        $sfx = Join-Path $script:BuildRoot 'msys2-base.sfx.exe'
        try {
            $release = 'https://github.com/msys2/msys2-installer/releases/download/'
            $uri = $release + 'nightly-x86_64/msys2-base-x86_64-latest.sfx.exe'
            Invoke-SuiteDownload $uri $sfx
        } catch { Write-Warning ('MSYS2 download failed: {0}' -f $_.Exception.Message) }
        while (-not (Test-Path -LiteralPath (Join-Path $root 'usr\bin\msys-2.0.dll'))) {
            if (Test-Path -LiteralPath $sfx) {
                $extractCode = Invoke-SuiteProcess $sfx @('x','-y',('-o{0}' -f $script:SuiteRoot))
                if ($extractCode -ne 0) {
                    Write-Warning ('MSYS2 extraction failed: ' + $extractCode)
                }
                Remove-Item -LiteralPath $sfx -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath (Join-Path $root 'usr\bin\msys-2.0.dll')) { break }
            Write-Host ('MSYS2 installation is incomplete. ' +
                'Install it manually, then press Enter to retry.')
            Pause-Suite
            if ($NonInteractive) { throw 'MSYS2 installation is incomplete.' }
        }
    }
    $paths = @((Join-Path $root 'opt\bin'), (Join-Path $root 'usr\bin'), $env:PATH)
    $env:PATH = $paths -join ';'
    $shortcut = Join-Path $script:SuiteRoot 'mintty.lnk'
    if (-not (Test-Path -LiteralPath $shortcut)) {
        Write-Section 'make a first run'
        $code = Invoke-Bash 'firstrun.log' 'exit'
        if ($code -ne 0) { throw 'MSYS2 first run failed; see build/firstrun.log.' }
        $sed = Join-Path $root 'usr\bin\sed.exe'
        if (Test-Path -LiteralPath $sed) {
            & $sed -i 's/#Color/Color/;s/^IgnorePkg.*/#&/' (Join-Path $root 'etc\pacman.conf')
            if ($env:CI) {
                & $sed -i 's/#NoProgressBar/NoProgressBar/' (Join-Path $root 'etc\pacman.conf')
            }
        }
        Write-Section 'first update'
        $firstUpdate = @('--noconfirm', '-Sy', '--asdeps', 'pacman-mirrors')
        $code = Invoke-Bash 'firstUpdate.log' 'pacman' $firstUpdate
        if ($code -ne 0) { throw 'MSYS2 first update failed; see build/firstUpdate.log.' }
        Invoke-Pacman @(
            '-S', '--needed', '--ask=20', '--noconfirm', '--asdeps'
            'bash', 'pacman', 'msys2-runtime'
        )
        Write-Section 'second update'
        $code = Invoke-Bash 'secondUpdate.log' 'pacman' @('--noconfirm','-Syu','--asdeps')
        if ($code -ne 0) { throw 'MSYS2 second update failed; see build/secondUpdate.log.' }
        try {
            $link = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
            $variant = if ($script:Config.CC -eq 'clang') { 'clang64' } else { 'ucrt64' }
            $link.Arguments = '-full-path -{0} -where ..' -f $variant
            $link.Description = 'msys2 shell console'
            $link.TargetPath = $msysShell
            $link.WindowStyle = 1
            $link.IconLocation = Join-Path $root 'msys2.ico'
            $link.WorkingDirectory = $root
            $link.Save()
        } catch { Write-Warning ('Unable to create mintty shortcut: {0}' -f $_.Exception.Message) }
    }
}

function Initialize-MsysFiles {
    Initialize-BaseFolders
    $msys = Join-Path $script:SuiteRoot 'msys64'
    $etc = Join-Path $msys 'etc'
    $fstab = Join-Path $etc 'fstab'
    $rewrite = -not (Test-Path -LiteralPath $fstab)
    if (-not $rewrite) {
        $content = [string](Get-Content -LiteralPath $fstab -Raw)
        $rootMount = [regex]::Escape($script:SuiteRoot.TrimEnd('\')) + '\\? /trunk\s'
        $rewrite = ($content -notmatch $rootMount) -or
            $content.Contains('local32') -or $content.Contains('clang32')
    }
    if ($rewrite) {
        $root = $script:SuiteRoot.TrimEnd('\')
        $fstabLines = @(
            'none / cygdrive binary,posix=0,noacl,user 0 0'
            ''
            ("{0}\ /trunk ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\build\ /build ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\msys64\mingw32\ /mingw32 ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\msys64\mingw64\ /mingw64 ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\msys64\ucrt64\ /ucrt64 ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\msys64\clang64\ /clang64 ntfs binary,posix=0,noacl,user 0 0" -f $root)
            ("{0}\local64\ /local64 ntfs binary,posix=0,noacl,user 0 0" -f $root)
        )
        Write-Utf8File $fstab (($fstabLines -join "`n") + "`n")
    }
    $suiteUserHome = Join-Path $msys ('home\' + $env:USERNAME)
    New-Item -ItemType Directory -Path $suiteUserHome -Force | Out-Null
    $minttyrc = Join-Path $suiteUserHome '.minttyrc'
    if (-not (Test-Path -LiteralPath $minttyrc)) { Write-Utf8File $minttyrc '' }
    $minttyText = [string](Get-Content -LiteralPath $minttyrc -Raw)
    if ($minttyText -match '(?im)^TERM=(.+)\r?$') { $env:TERM = $matches[1].Trim() }
    else {
        if ($minttyText -and -not $minttyText.EndsWith("`n")) { $minttyText += "`n" }
        $settings = @(
            'Locale=en_US', 'Charset=UTF-8', 'Font=Consolas'
            'Columns=120', 'Rows=30', 'TERM=xterm-256color'
        )
        foreach ($setting in $settings) {
            $key = $setting.Split('=')[0]
            if ($minttyText -notmatch ('(?im)^' + $key + '=')) { $minttyText += $setting + "`n" }
        }
        Write-Utf8File $minttyrc $minttyText
        $env:TERM = 'xterm-256color'
    }
    $gitconfig = Join-Path $suiteUserHome '.gitconfig'
    if (-not (Test-Path -LiteralPath $gitconfig)) {
        $gitText = @(
            '[user]'
            "name = $env:USERNAME"
            "email = $env:USERNAME@$env:COMPUTERNAME"
            ''
            '[color]'
            'ui = true'
            ''
            '[core]'
            'editor = vim'
            'autocrlf ='
            ''
            '[merge]'
            'tool = vimdiff'
            ''
            '[push]'
            'default = simple'
            ''
        ) -join "`n"
        Write-Utf8File $gitconfig $gitText
    }
    $msysPackages = @(
        'autoconf-archive', 'autogen', 'base', 'base-devel', 'filesystem'
        'msys2-runtime', 'pacutils', 'unzip', 'winpty'
    )
    $mingwPackages = @(
        '7zip', 'autotools', 'ccache', 'cmake', 'dlfcn'
        'git', 'meson', 'nasm', 'ninja', 'toolchain'
    )
    if ($script:Config.CC -eq 'clang') { $mingwPackages += 'gcc-compat' }
    Write-Utf8File (Join-Path $etc 'pac-base.pk') (($msysPackages -join "`n") + "`n")
    Write-Utf8File (Join-Path $etc 'pac-mingw.pk') (($mingwPackages -join "`n") + "`n")
}

function Install-MsysPackages {
    $make = Join-Path $script:SuiteRoot 'msys64\usr\bin\make.exe'
    if (-not (Test-Path -LiteralPath $make)) {
        $failureMarker = Join-Path $script:BuildRoot 'install_base_failed'
        Remove-Item -LiteralPath $failureMarker -Force -ErrorAction SilentlyContinue
        $scriptPath = Join-Path $script:BuildRoot 'pacman.sh'
        $text = @(
            'set -o pipefail'
            'echo -ne "\033]0;install base system\007"'
            'msysbasesystem="$(cat /etc/pac-base.pk | tr ''\n\r'' ''  '')"'
            '[[ "$(uname)" = *6.1* ]] && nargs="-n 4"'
            ('echo $msysbasesystem | xargs $nargs pacman -Sw ' +
                '--noconfirm --ask=20 --needed || exit $?')
            ('echo $msysbasesystem | xargs $nargs pacman -S ' +
                '--noconfirm --ask=20 --needed || exit $?')
            'echo $msysbasesystem | xargs pacman -D --asexplicit || exit $?'
            'sleep 3'
        )
        Write-Utf8File $scriptPath (($text -join "`n") + "`n")
        try { $code = Invoke-Bash 'pacman.log' '/build/pacman.sh' }
        finally { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
        if ($code -ne 0 -or -not (Test-Path -LiteralPath $make)) {
            throw 'MSYS2 base package installation failed; see build/pacman.log.'
        }
    }
    $cert = Join-Path $script:SuiteRoot 'msys64\usr\ssl\cert.pem'
    if ((Test-Path -LiteralPath $cert) -and (Get-Item -LiteralPath $cert).Length -eq 0) {
        $code = Invoke-Bash 'cert.log' 'update-ca-trust'
        if ($code -ne 0) { throw 'MSYS2 certificate repair failed; see build/cert.log.' }
    }

    $compiler = if ($script:Config.CC -eq 'clang') {
        Join-Path $script:SuiteRoot 'msys64\clang64\bin\clang.exe'
    } else {
        Join-Path $script:SuiteRoot 'msys64\ucrt64\bin\gcc.exe'
    }
    while (-not (Test-Path -LiteralPath $compiler)) {
        $prefix = if ($script:Config.CC -eq 'clang') {
            'mingw-w64-clang-x86_64-'
        } else {
            'mingw-w64-ucrt-x86_64-'
        }
        $scriptPath = Join-Path $script:BuildRoot 'mingw.sh'
        $packageList = "sed 's/^/{0}/' /etc/pac-mingw.pk" -f $prefix
        $text = @(
            'set -o pipefail'
            "printf '\033]0;install 64-bit compiler\007'"
            '[[ "$(uname)" = *6.1* ]] && nargs="-n 4"'
            ($packageList + ' | xargs $nargs pacman -Sw --noconfirm --ask=20 --needed || exit $?')
            ($packageList + ' | xargs $nargs pacman -S --noconfirm --ask=20 --needed || exit $?')
            'sleep 3'
        )
        Write-Utf8File $scriptPath (($text -join "`n") + "`n")
        try { $code = Invoke-Bash 'mingw64.log' '/build/mingw.sh' }
        finally { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
        if ($code -eq 0 -and (Test-Path -LiteralPath $compiler)) { break }
        if ($NonInteractive) {
            throw "MinGW compiler was not installed; see build/mingw64.log: $compiler"
        }
        Write-Warning 'MinGW compiler installation failed; see build/mingw64.log.'
        if ((Read-Host 'Try again [y/n]') -ne 'y') {
            throw 'MinGW compiler installation cancelled.'
        }
    }
}

function Write-UpdateScript {
    if ($script:Config.updateSuite -ne 'y') { return }
    $target = Join-Path $script:SuiteRoot 'update_suite.sh'
    $sourceLines = @(Get-Content -LiteralPath (Join-Path $script:BuildRoot 'media-suite_update.sh'))
    $begin = -1
    $end = -1
    for ($i = 0; $i -lt $sourceLines.Count; $i++) {
        if ($sourceLines[$i] -match '# start suite update') { $begin = $i }
        if ($sourceLines[$i] -match '# end suite update') { $end = $i; break }
    }
    if ($begin -lt 0 -or $end -lt $begin) {
        throw 'Could not find the suite update block in media-suite_update.sh.'
    }
    $updateLines = @(
        '#!/bin/bash'
        ''
        '# Run by dragging this file to mintty while the suite is not running.'
        ''
        'update=yes'
    ) + $sourceLines[$begin..$end]
    Write-Utf8File $target (($updateLines -join "`n") + "`n")
}

function Get-OptionDefinitions {
    $path = Join-Path $PSScriptRoot 'media-autobuild_suite.options.psd1'
    $data = Import-PowerShellDataFile -LiteralPath $path
    foreach ($option in $data.Options) {
        $map = @{}
        $question = [regex]::Replace(
            [string]$option.Question, '\r?\n', [Environment]::NewLine
        )
        $lines = @($question)
        for ($i = 0; $i -lt $option.Choices.Count; $i++) {
            $choice = $option.Choices[$i]
            $map[[string]($i + 1)] = $choice.Value
            $label = [regex]::Replace(
                [string]$choice.Label, '\r?\n', [Environment]::NewLine
            )
            $lines += '{0} = {1}' -f ($i + 1), $label
        }
        if ($option.Help) {
            $help = [regex]::Replace(
                [string]$option.Help, '\r?\n', [Environment]::NewLine
            )
            $lines += '', $help
        }
        $name = if ($option.ConfigKey) { $option.ConfigKey } else { $option.Key }
        @{
            Key = $option.Key
            Name = $name
            Max = $option.Choices.Count
            Prompt = $option.Prompt
            Question = $lines -join [Environment]::NewLine
            Map = $map
        }
    }
}

function Get-CompileArguments {
    return @(
        '--suite=yes'
        ('--cpuCount={0}' -f $script:Config.cpuCount)
        ('--deleteSource={0}' -f $script:Config.deleteSource)
        ('--mp4box={0}' -f $script:Config.mp4box)
        ('--vpx={0}' -f $script:Config.vpx2)
        ('--x264={0}' -f $script:Config.x264)
        ('--x265={0}' -f $script:Config.x265)
        ('--other265={0}' -f $script:Config.other265)
        ('--flac={0}' -f $script:Config.flac)
        ('--fdkaac={0}' -f $script:Config.fdkaac)
        ('--mediainfo={0}' -f $script:Config.mediainfo)
        ('--sox={0}' -f $script:Config.sox)
        ('--ffmpeg={0}' -f $script:Config.ffmpeg)
        ('--ffmpegUpdate={0}' -f $script:Config.ffmpegUpdate)
        ('--ffmpegChoice={0}' -f $script:Config.ffmpegChoice)
        ('--ffmpegKeepLegacyOpts={0}' -f $script:Config.ffmpegKeepLegacyOpts)
        ('--mpv={0}' -f $script:Config.mpv)
        ('--license={0}' -f $script:Config.license2)
        ('--stripping={0}' -f $script:Config.stripFile)
        ('--packing={0}' -f $script:Config.packFile)
        ('--rtmpdump={0}' -f $script:Config.rtmpdump)
        ('--logging={0}' -f $script:Config.logging)
        ('--bmx={0}' -f $script:Config.bmx)
        ('--standalone={0}' -f $script:Config.standalone)
        ('--aom={0}' -f $script:Config.aom)
        ('--faac={0}' -f $script:Config.faac)
        ('--exhale={0}' -f $script:Config.exhale)
        ('--curl={0}' -f $script:Config.curl)
        ('--cyanrip={0}' -f $script:Config.cyanrip)
        ('--rav1e={0}' -f $script:Config.rav1e)
        ('--ripgrep={0}' -f $script:Config.ripgrep)
        ('--dav1d={0}' -f $script:Config.dav1d)
        ('--uvg266={0}' -f $script:Config.uvg266)
        ('--vvenc={0}' -f $script:Config.vvenc)
        ('--vvdec={0}' -f $script:Config.vvdec)
        ('--jq={0}' -f $script:Config.jq)
        ('--jo={0}' -f $script:Config.jo)
        ('--dssim={0}' -f $script:Config.dssim)
        ('--gifski={0}' -f $script:Config.gifski)
        ('--avs2={0}' -f $script:Config.avs2)
        ('--dovitool={0}' -f $script:Config.dovitool)
        ('--hdr10plustool={0}' -f $script:Config.hdr10plustool)
        ('--timeStamp={0}' -f $script:Config.timeStamp)
        ('--noMintty={0}' -f $script:Config.noMintty)
        ('--ccache={0}' -f $script:Config.ccache)
        ('--svthevc={0}' -f $script:Config.svthevc)
        ('--svtav1={0}' -f $script:Config.svtav1)
        ('--svtvp9={0}' -f $script:Config.svtvp9)
        ('--xvc={0}' -f $script:Config.xvc)
        ('--vlc={0}' -f $script:Config.vlc)
        ('--libavif={0}' -f $script:Config.libavif)
        ('--libheif={0}' -f $script:Config.libheif)
        ('--jpegxl={0}' -f $script:Config.jpegxl)
        ('--jpegli={0}' -f $script:Config.jpegli)
        ('--av1an={0}' -f $script:Config.av1an)
        ('--zlib={0}' -f $script:Config.zlib)
        ('--ffmpegPath={0}' -f $script:Config.ffmpegPath)
        ('--exitearly={0}' -f $env:MABS_EXIT_EARLY)
    )
}

function Invoke-SuiteBuild {
    $nl = [string][char]10
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw '32-bit operating systems are no longer supported.'
    }
    if ($env:OS -ne 'Windows_NT') { throw 'This suite requires Windows.' }
    if ($script:SuiteRoot -match '\s') {
        throw 'The suite path must not contain spaces. Use C:\media-autobuild_suite.'
    }
    if ($script:SuiteRoot.Length -gt 32) {
        Write-Section ('The suite path exceeds 32 characters; ' +
            'packages may fail building: ' + $script:SuiteRoot)
        if (-not $ValidateOnly) { Pause-Suite }
    }
    $msvc = @(Get-Command lib.exe,cl.exe -CommandType Application -ErrorAction SilentlyContinue)
    if ($env:VSINSTALLDIR -or $msvc.Count) {
        $detected = (@($env:VSINSTALLDIR) + @($msvc | ForEach-Object { $_.Source })) -join ', '
        throw ('A MSVC environment was detected. ' +
            'Use a normal PowerShell session. Detected: ' + $detected)
    }
    Read-IniFile
    $definitions = Get-OptionDefinitions
    foreach ($definition in $definitions) { Read-Choice $definition }
    $rawPath = [string]$script:IniValues['ffmpegPath']
    if (-not $rawPath -or $rawPath -eq '0') {
        $rawPath = 'https://code.ffmpeg.org/FFmpeg/FFmpeg.git'
        Write-Host ('Using default FFmpeg source: ' + $rawPath)
        Write-Host ('Set ffmpegPath in build/media-autobuild_suite.ini ' +
            'to use a custom repository or local path.')
    }
    Set-IniValue 'ffmpegPath' $rawPath
    $script:Config.ffmpegPath = Resolve-SuitePath $rawPath
    $pkgUpdateTime = 86400L
    $rawInterval = [string]$script:IniValues['pkgUpdateTime']
    if ($rawInterval -and $rawInterval -ne '0') {
        if (-not [long]::TryParse($rawInterval, [ref]$pkgUpdateTime) -or $pkgUpdateTime -lt 0) {
            throw 'Invalid pkgUpdateTime; expected a non-negative number of seconds.'
        }
    }
    Set-IniValue 'pkgUpdateTime' ([string]$pkgUpdateTime)
    $legacy = [string]$script:IniValues['ffmpegKeepLegacyOpts']
    if (-not $legacy) { $legacy = '0' }
    if ($legacy -notin @('0','1')) { throw 'Invalid ffmpegKeepLegacyOpts; expected 0 or 1.' }
    Set-IniValue 'ffmpegKeepLegacyOpts' $legacy
    $script:Config.ffmpegKeepLegacyOpts = if ($legacy -eq '1') { 'y' } else { 'n' }
    $coreRaw = [string]$script:IniValues['cores']
    $cpuCount = 0
    $recommended = [Math]::Max(1, [Math]::Floor([Environment]::ProcessorCount / 2))
    while (-not [int]::TryParse($coreRaw, [ref]$cpuCount) -or $cpuCount -lt 1) {
        if ($NonInteractive -or $ValidateOnly) {
            throw 'Missing or invalid configuration value: cores'
        }
        $coreRaw = Read-Host ('Core/Thread Count (recommended {0})' -f $recommended)
    }
    Set-IniValue 'cores' ([string]$cpuCount)
    $script:Config.cpuCount = $cpuCount
    $compileArgs = Get-CompileArguments
    if ($ValidateOnly) {
        [void](Get-DefaultOptions)
        Write-Host 'Configuration and default options are valid; no files changed.'
        foreach ($argument in $compileArgs) { Write-Host $argument }
        return 0
    }
    New-Item -ItemType Directory -Path $script:BuildRoot -Force | Out-Null
    if ($script:DeleteIni) {
        $iniLines = @('[compiler list]')
        foreach ($definition in $definitions) {
            $iniLines += $definition.Key + '=' + $script:IniValues[$definition.Key]
        }
        $extraKeys = @('ffmpegPath', 'pkgUpdateTime', 'ffmpegKeepLegacyOpts', 'cores')
        foreach ($key in $extraKeys) {
            $iniLines += $key + '=' + $script:IniValues[$key]
        }
        $knownKeys = @($definitions | ForEach-Object { $_.Key }) + $extraKeys
        foreach ($key in @($script:IniValues.Keys | Sort-Object)) {
            if ($key -notin $knownKeys) { $iniLines += $key + '=' + $script:IniValues[$key] }
        }
        Write-Utf8File $script:IniPath (($iniLines -join $nl) + $nl)
    }
    if ($script:Config.ffmpegChoice -eq 'y') { New-OptionFiles }
    $helpers = @(
        'bash.sh', 'media-suite_compile.sh', 'media-suite_deps.sh'
        'media-suite_helper.sh', 'media-suite_update.sh'
    )
    foreach ($name in $helpers) {
        $target = Join-Path $script:BuildRoot $name
        if (-not (Test-Path -LiteralPath $target)) {
            $buildUrl = 'https://github.com/m-ab-s/media-autobuild_suite/raw/master/build/'
            Invoke-SuiteDownload ($buildUrl + $name) $target
        }
    }
    $script:NoMintty = $script:Config.noMintty -eq 'y'
    $env:TERM = 'xterm-256color'
    $env:instdir = $script:SuiteRoot
    $env:build = $script:BuildRoot
    Initialize-Msys2
    Initialize-MsysFiles
    Install-MsysPackages
    Write-UpdateScript
    Write-Profile $script:Config.CC
    $updatedLog = Join-Path $script:BuildRoot 'updated.log'
    $lastUpdate = 0L
    $needsUpdate = $true
    if (Test-Path -LiteralPath $updatedLog) {
        $text = [string](Get-Content -LiteralPath $updatedLog -Raw)
        if ([long]::TryParse($text.Trim(), [ref]$lastUpdate)) {
            $elapsed = [DateTimeOffset]::Now.ToUnixTimeSeconds() - $lastUpdate
            $needsUpdate = $elapsed -gt $pkgUpdateTime
        }
    }
    if ($needsUpdate) {
        $updateArgs = @('--CC=' + $script:Config.CC)
        $code = Invoke-Bash 'update.log' '/build/media-suite_update.sh' $updateArgs
        if ($code -ne 0) {
            throw ('MSYS2 update failed; see build/update.log. Exit code: ' + $code)
        }
        Write-Utf8File $updatedLog ([string][DateTimeOffset]::Now.ToUnixTimeSeconds() + $nl)
    }
    $coreMarker = Join-Path $script:BuildRoot 'update_core'
    if (Test-Path -LiteralPath $coreMarker) {
        Invoke-Pacman @(
            '-S', '--needed', '--noconfirm', '--ask=20', '--asdeps'
            'bash', 'pacman', 'msys2-runtime'
        )
        Remove-Item -LiteralPath $coreMarker -Force
    }
    $gnupg = Join-Path $script:SuiteRoot ('msys64\home\{0}\.gnupg' -f $env:USERNAME)
    New-Item -ItemType Directory -Path $gnupg -Force | Out-Null
    $gpg = Join-Path $gnupg 'gpg.conf'
    $gpgText = if (Test-Path -LiteralPath $gpg) {
        [string](Get-Content -LiteralPath $gpg -Raw)
    } else { '' }
    if ($gpgText -notmatch 'hkps://keys\.openpgp\.org') {
        Write-Utf8File $gpg ($gpgText.TrimEnd() + $nl + 'keyserver hkps://keys.openpgp.org' + $nl)
    }
    $profilePacnew = Join-Path $script:SuiteRoot 'msys64\etc\profile.pacnew'
    if (Test-Path -LiteralPath $profilePacnew) {
        $profile = Join-Path $script:SuiteRoot 'msys64\etc\profile'
        Move-Item -LiteralPath $profilePacnew -Destination $profile -Force
    }
    $profileLines = @(
        'source /local64/etc/profile2.local'
        'case $- in'
        '*i*) ;;'
        '*) export LANG=en_US.UTF-8 ;;'
        'esac'
    )
    $profileScript = Join-Path $script:SuiteRoot 'msys64\etc\profile.d\Zab-suite.sh'
    Write-Utf8File $profileScript (($profileLines -join $nl) + $nl)
    foreach ($name in @('compilation_failed','fail_comp')) {
        $file = Join-Path $script:BuildRoot $name
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    $env:MSYSTEM = if ($script:Config.CC -eq 'clang') { 'CLANG64' } else { 'UCRT64' }
    $env:MSYS2_PATH_TYPE = 'inherit'
    return Invoke-Bash 'compile.log' '/build/media-suite_compile.sh' $compileArgs -Compile
}

function Invoke-Suite {
    param([string]$InstallDirectory = $PSScriptRoot, [switch]$NonInteractive, [switch]$ValidateOnly)
    $ErrorActionPreference = 'Stop'
    $script:SuiteRoot = [IO.Path]::GetFullPath($InstallDirectory).TrimEnd('\')
    $script:BuildRoot = Join-Path $script:SuiteRoot 'build'
    $script:IniPath = Join-Path $script:BuildRoot 'media-autobuild_suite.ini'
    $script:IniValues = @{}
    $script:Config = @{}
    $script:DeleteIni = $false
    $script:NoMintty = $false
    $savedEnvironment = @{}
    foreach ($name in @('PATH','TERM','instdir','build','MSYSTEM','MSYS2_PATH_TYPE')) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    Push-Location -LiteralPath $script:SuiteRoot
    try { return Invoke-SuiteBuild }
    finally {
        Pop-Location
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
        }
    }
}

# Dot-sourcing loads the functions without starting an installation or a build.
if ($MyInvocation.InvocationName -ne '.') {
    try { exit (Invoke-Suite -NonInteractive:$NonInteractive -ValidateOnly:$ValidateOnly) }
    catch {
        Write-Error $_ -ErrorAction Continue
        exit 1
    }
}
