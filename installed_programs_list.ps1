$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputPath = "$env:USERPROFILE\installed_programs_$timestamp.csv"

# Define registry locations for 64-bit and 32-bit apps
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedApps = foreach ($path in $registryPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -and $_.DisplayName.Trim() -ne ""
    } | Select-Object `
        DisplayName,
        DisplayVersion,
        Publisher,
        InstallDate,
        InstallLocation,
        UninstallString,
        PSPath
}

$installedApps |
    Sort-Object DisplayName |
    Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "`nExport complete: $outputPath"
Write-Host "Total programs exported: $($installedApps.Count)"
