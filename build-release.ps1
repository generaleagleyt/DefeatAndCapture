# Build the installable FOMOD archive from this repo.
#
# WHY THIS EXISTS: GitHub's "Download ZIP" button does NOT produce a working
# installer. It wraps everything in a folder named after the repo and branch
# (DefeatAndCapture-main/), and a mod manager looks for fomod/ModuleConfig.xml at
# the ARCHIVE ROOT. The wrapped copy either fails to be detected as a FOMOD or
# installs the whole tree into Data as one lump.
#
# So: the repo is the source, and the download is a Release asset built here.
# This script zips the repo contents with the folders AT THE ROOT, which is the
# one property that makes it installable.
#
#   .\build-release.ps1 -Version 1.0
#
param(
    [string]$Version = "",
    [string]$OutDir  = ""
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $OutDir) { $OutDir = Join-Path (Split-Path $root) 'Release' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# Dots, not spaces. Release assets get linked, quoted in shell commands and
# pasted into mod-manager download fields, and a space in the filename breaks or
# %20-mangles all three. This matches the convention GitHub suggests on the
# release page: Defeat.And.Capture.v0.1.0-alpha.zip
$name = if ($Version) { "Defeat.And.Capture.v$Version.zip" } else { "Defeat.And.Capture.zip" }
$out  = Join-Path $OutDir $name

# Everything except repo plumbing. LICENSE and README.md are harmless in the
# archive - a FOMOD installs only what ModuleConfig.xml names, so stray root
# files are ignored by the mod manager - and shipping the licence is polite.
$exclude = @('.git', '.github', '.gitignore', 'build-release.ps1')

$staging = Join-Path ([IO.Path]::GetTempPath()) ("dac_build_" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Get-ChildItem -LiteralPath $root -Force | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $staging $_.Name) -Recurse -Force
    }

    # Refuse to ship something a mod manager cannot read. Both of these have been
    # broken by a hand edit before; neither fails loudly at install time.
    $mc = Join-Path $staging 'fomod\ModuleConfig.xml'
    if (-not (Test-Path -LiteralPath $mc)) { throw "fomod\ModuleConfig.xml is missing - the archive would not be a FOMOD" }
    [xml]$xml = Get-Content -LiteralPath $mc -Raw

    Get-ChildItem -LiteralPath $staging -Recurse -File -Filter '*.json' | ForEach-Object {
        try { $null = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json }
        catch { throw ("invalid JSON: " + $_.FullName.Replace($staging + '\', '')) }
    }

    # Every folder ModuleConfig references must actually be present, or the
    # option silently installs nothing.
    $refs = @($xml.config.requiredInstallFiles.folder.source)
    $xml.config.installSteps.installStep.optionalFileGroups.group.plugins.plugin |
        ForEach-Object { $refs += $_.files.folder.source }
    foreach ($r in ($refs | Where-Object { $_ })) {
        if (-not (Test-Path -LiteralPath (Join-Path $staging $r))) { throw "ModuleConfig references missing folder: $r" }
    }

    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $out -CompressionLevel Optimal

    $i = Get-Item -LiteralPath $out
    Write-Host ("built: {0}  ({1:N0} bytes)" -f $i.FullName, $i.Length)
    Write-Host ("folders at archive root: " + (($refs | Where-Object { $_ }) -join ', ') + ", fomod")
}
finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
