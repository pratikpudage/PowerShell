# Function to check if Zoom is installed in the registry or the specified folder for each user profile
function Test-ZoomInstallation {
    param(
        [switch]$ReportOnly,
        [switch]$Remove
    )

    $installed = $false

    # Check the registry for Zoom installation
    $zoomRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $zoomUninstallString = (Get-ItemProperty -Path $zoomRegistryPath | Where-Object {$_.DisplayName -eq "Zoom"}).UninstallString

    if ($zoomUninstallString -ne $null) {
        $installed = $true
        if ($ReportOnly) {
            Write-Host "Zoom is installed according to registry information."
        }

        if ($Remove) {
            Write-Host "Removing Zoom according to registry information."
            Start-Process -FilePath $zoomUninstallString -ArgumentList "/S" -Wait
        }
    }

    # Get a list of user profiles on the system
    $userProfiles = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue

    # Loop through each user profile
    foreach ($profile in $userProfiles) {
        $zoomPath = Join-Path -Path $profile.FullName -ChildPath "AppData\Roaming\Zoom"

        # Check if Zoom executable exists in the specified path for the user profile
        if (Test-Path -Path $zoomPath) {
            $installed = $true
            if ($ReportOnly) {
                Write-Host "Zoom is installed for user $($profile.Name) at $($zoomPath)"
            }

            if ($Remove) {
                Write-Host "Removing Zoom for user $($profile.Name) at $($zoomPath)"
                Remove-Item -Path $zoomPath -Force -Recurse
            }
        }
    }

    if (-not $installed) {
        Write-Host "Zoom is not installed on this system."
    }
}

# Call the function with parameters to test if Zoom is installed and/or remove it
# Test-ZoomInstallation -ReportOnly
# Test-ZoomInstallation -Remove