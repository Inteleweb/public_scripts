# Toggle Display Scale Script
# Cycles between 100%, 125%, and 150% display scaling
# Uses Windows API for immediate effect (no logoff required)

# Add required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Add Windows API functions for immediate DPI changes
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, IntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(
        uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
    
    public const IntPtr HWND_BROADCAST = (IntPtr)0xFFFF;
    public const uint WM_SETTINGCHANGE = 0x1A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;
    public const uint SPI_SETNONCLIENTMETRICS = 0x002A;
    public const uint SPIF_UPDATEINIFILE = 0x01;
    public const uint SPIF_SENDCHANGE = 0x02;
}
"@

# Scale values (DPI values: 96=100%, 120=125%, 144=150%)
$scales = @{
    96 = @{ percent = "100%"; next = 120 }
    120 = @{ percent = "125%"; next = 144 }
    144 = @{ percent = "150%"; next = 96 }
}

# Function to get current DPI setting
function Get-CurrentDPI {
    try {
        # Check multiple registry locations
        $locations = @(
            @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "AppliedDPI" },
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "LogPixels" }
        )
        
        foreach ($location in $locations) {
            $value = Get-ItemProperty -Path $location.Path -Name $location.Name -ErrorAction SilentlyContinue
            if ($value -and $value.($location.Name)) {
                return $value.($location.Name)
            }
        }
        
        # Default to 96 DPI (100%) if not found
        return 96
    } catch {
        return 96
    }
}

# Function to set DPI with immediate effect
function Set-DPIScale($newDPI) {
    try {
        # Set in multiple registry locations for compatibility
        $registryPaths = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "LogPixels" },
            @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "AppliedDPI" }
        )
        
        foreach ($regPath in $registryPaths) {
            # Ensure the registry path exists
            if (!(Test-Path $regPath.Path)) {
                New-Item -Path $regPath.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath.Path -Name $regPath.Name -Value $newDPI -Type DWord
        }
        
        # Notify system of changes for immediate effect
        $result = [IntPtr]::Zero
        [User32]::SendMessageTimeout(
            [User32]::HWND_BROADCAST,
            [User32]::WM_SETTINGCHANGE,
            [IntPtr]::Zero,
            "Environment",
            [User32]::SMTO_ABORTIFHUNG,
            5000,
            [ref]$result
        ) | Out-Null
        
        # Additional system parameter update
        [User32]::SystemParametersInfo(
            [User32]::SPI_SETNONCLIENTMETRICS,
            0,
            [IntPtr]::Zero,
            [User32]::SPIF_UPDATEINIFILE -bor [User32]::SPIF_SENDCHANGE
        ) | Out-Null
        
        return $true
    } catch {
        Write-Error "Failed to set DPI: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    # Get current DPI
    $currentDPI = Get-CurrentDPI
    
    # Determine next DPI
    if ($scales.ContainsKey($currentDPI)) {
        $nextDPI = $scales[$currentDPI].next
        $currentPercent = $scales[$currentDPI].percent
    } else {
        # Default progression if current DPI is not standard
        $nextDPI = 120
        $currentPercent = "Unknown ($currentDPI DPI)"
    }
    
    $nextPercent = $scales[$nextDPI].percent
    
    # Apply new DPI setting
    if (Set-DPIScale $nextDPI) {
        # Show success notification
        [System.Windows.Forms.MessageBox]::Show(
            "Display scale changed from $currentPercent to $nextPercent`n`nThe change has been applied immediately!`nSome applications may need to be restarted to fully reflect the new scaling.",
            "Display Scale Toggle - Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        Write-Host "Display scale changed from $currentPercent to $nextPercent"
        Write-Host "Change applied immediately. Some apps may need restart for full effect."
    } else {
        throw "Failed to apply DPI changes"
    }
    
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Failed to change display scale: $($_.Exception.Message)`n`nYou may need to run this script as Administrator for immediate changes.",
        "Display Scale Toggle - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    Write-Error "Failed to change display scale: $($_.Exception.Message)"
}

