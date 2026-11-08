$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolchain = Join-Path $projectRoot '.godot/toolchain'
$version = '4.7.2'
$engine = Join-Path $toolchain "Godot_v$version-stable_win64_console.exe"
New-Item -ItemType Directory -Force $toolchain | Out-Null

function Get-OfficialDownload($slug, $destination) {
    $url = "https://downloads.godotengine.org/?version=$version&flavor=stable&slug=$slug"
    Invoke-WebRequest -Uri $url -OutFile $destination
}

if (-not (Test-Path $engine)) {
    $archive = Join-Path $toolchain 'godot.zip'
    Get-OfficialDownload 'win64.exe.zip' $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $toolchain -Force
}
if (-not (Test-Path (Join-Path $toolchain 'web_nothreads_release.zip')) -or
    -not (Test-Path (Join-Path $toolchain 'web_nothreads_debug.zip'))) {
    $templates = Join-Path $toolchain 'templates.tpz'
    if (-not (Test-Path $templates)) { Get-OfficialDownload 'export_templates.tpz' $templates }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($templates)
    try {
        foreach ($name in @('web_nothreads_release.zip', 'web_nothreads_debug.zip')) {
            $entry = $zip.GetEntry("templates/$name")
            if ($null -eq $entry) { throw "Missing template: $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $toolchain $name), $true)
        }
    } finally { $zip.Dispose() }
}

& $engine --headless --editor --path $projectRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Asset import failed.' }
& $engine --headless --audio-driver WASAPI --path $projectRoot --script tools/check_game.gd
if ($LASTEXITCODE -ne 0) { throw 'Gameplay validation failed.' }
& $engine --headless --audio-driver WASAPI --path $projectRoot --script tools/check_obstacles.gd
if ($LASTEXITCODE -ne 0) { throw 'Obstacle validation failed.' }
New-Item -ItemType Directory -Force (Join-Path $projectRoot 'build/web') | Out-Null
& $engine --headless --path $projectRoot --export-release Web (Join-Path $projectRoot 'build/web/index.html')
if ($LASTEXITCODE -ne 0) { throw 'Web export failed.' }
$htmlPath = Join-Path $projectRoot 'build/web/index.html'
$html = [IO.File]::ReadAllText($htmlPath)
$html = $html.Replace('<html lang="en">', '<html lang="ca">')
$html = $html.Replace('const GODOT_CONFIG =', 'document.getElementById("canvas").addEventListener("contextmenu", (event) => event.preventDefault());' + "`n" + 'const GODOT_CONFIG =')
$html = $html.Replace('Your browser does not support the canvas tag.', 'El navegador no admet el llenç del joc.')
$html = $html.Replace('Your browser does not support JavaScript.', 'El navegador no admet JavaScript.')
$html = $html.Replace('An unknown error occurred.', 'Error desconegut. Torna a carregar el joc.')
$html = $html.Replace('Error\nThe following features required to run Godot projects on the Web are missing:\n', 'Error\nEl navegador no disposa de les funcions necessàries per executar el joc:\n')
[IO.File]::WriteAllText($htmlPath, $html, [Text.UTF8Encoding]::new($false))
Compress-Archive -Path (Join-Path $projectRoot 'build/web/*') -DestinationPath (Join-Path $projectRoot 'build/Reset-Run-Web.zip') -Force
Write-Output 'Export complete. Open Jugar.cmd to play.'
