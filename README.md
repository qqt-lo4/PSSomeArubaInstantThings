# PSSomeArubaInstantThings

A PowerShell module for managing Aruba Instant wireless access points via the REST API: connection management, client monitoring, AP statistics, and show command execution.

## Features

### Connect (1 function)

| Function | Description |
|----------|-------------|
| `Connect-ArubaInstantAPI` | Establishes a connection to the Aruba Instant API with automatic session management and reconnection |

### Monitoring (6 functions)

| Function | Description |
|----------|-------------|
| `Get-ArubaInstantShowCmdResult` | Executes a show command on an Aruba Instant access point |
| `Get-ArubaInstantClient` | Retrieves the list of connected clients from an Aruba Instant access point |
| `Get-ArubaInstantAP` | Retrieves the list of Aruba Instant access points with controller information |
| `Get-AurbaInstantAPImageVersion` | Retrieves the primary partition firmware version of an Aruba Instant AP |
| `Get-AurbaInstantShowSummary` | Retrieves and parses comprehensive system summary (clients, networks, APs, servers) |
| `Get-AurbaInstantShowStatsAP` | Retrieves statistics for a specific access point (usage, RF trends, client heatmap) |

**Note:** Three functions have a typo in their names (Aurba instead of Aruba): `Get-AurbaInstantAPImageVersion`, `Get-AurbaInstantShowSummary`, and `Get-AurbaInstantShowStatsAP`.

## Requirements

- **PowerShell** 5.1 or later
- **Network access** to Aruba Instant controller API (typically HTTPS on port 4343)
- **Credentials** with appropriate permissions on the Aruba Instant controller
- **Helper modules** (for parsing utilities):
  - Functions like `Test-StringIsIP`, `Invoke-IgnoreSSL`, `Set-UseUnsafeHeaderParsing`, `Convert-HashtableToURLArguments`
  - Parsing functions like `Convert-TSVWithDashLine`, `Select-LineRange`, `Convert-StringArrayToHashtable`, `Remove-EmptyString`
  - These utilities are typically provided by related modules (e.g., PSSomeDataThings, PSSomeAPIThings)

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeArubaInstantThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeArubaInstantThings" -Recurse

# Or import directly
Import-Module ".\PSSomeArubaInstantThings\PSSomeArubaInstantThings.psd1"
```

## Quick Start

### Connect to the Aruba Instant API
```powershell
# Create a connection object
$securePass = ConvertTo-SecureString "your_password" -AsPlainText -Force
$conn = Connect-ArubaInstantAPI -Address "192.168.1.1" -Port 4343 -Username "admin" -Password $securePass

# Or store in a global variable
Connect-ArubaInstantAPI -Address "192.168.1.1" -Port 4343 -Username "admin" -Password $securePass -GlobalVar
```

### Get access points and clients
```powershell
# List all access points
$aps = Get-ArubaInstantAP -ArubaInstantAPI $conn
$aps | Format-Table

# Get connected clients
$clients = Get-ArubaInstantClient -ArubaInstantAPI $conn
$clients | Format-Table

# Get firmware version
$version = Get-AurbaInstantAPImageVersion -ArubaInstantAPI $conn
Write-Host "AP Firmware Version: $version"
```

### Execute show commands
```powershell
# Execute any show command
$result = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $conn -cmd "show clients"

# Get comprehensive system summary
$summary = Get-AurbaInstantShowSummary -ArubaInstantAPI $conn
$summary.Clients
$summary."Access Points"
$summary.Networks

# Get AP statistics
$stats = Get-AurbaInstantShowStatsAP -ArubaInstantAPI $conn -IP "192.168.1.10"
$stats.Usage
$stats."RF Trends"
```

### Working with the global connection
```powershell
# If you used -GlobalVar during connection, you can omit the -ArubaInstantAPI parameter
Get-ArubaInstantClient
Get-ArubaInstantAP
```

## Connection Object Methods

The connection object returned by `Connect-ArubaInstantAPI` includes several useful methods:

| Method | Description |
|--------|-------------|
| `IgnoreSSL()` | Disables SSL certificate validation (if -ignoreSSLError was specified) |
| `Reconnect()` | Re-authenticates and obtains a new session ID |
| `InvokeWebRequest($args)` | Executes a web request with automatic reconnection on session expiration |
| `CallAPIGet($url, $args, $verbose)` | Performs a GET request to the API endpoint |
| `CallAPI($url, $method, $args, $verbose)` | Performs any HTTP method request to the API endpoint |

## Module Structure

```
PSSomeArubaInstantThings/
├── PSSomeArubaInstantThings.psd1    # Module manifest
├── PSSomeArubaInstantThings.psm1    # Module loader (dot-sources all .ps1 files)
├── README.md                         # This file
├── LICENSE                           # PolyForm Noncommercial License
├── Connect/                          # API connection management
│   └── Connect-ArubaInstantAPI.ps1
└── Monitoring/                       # Monitoring and show commands
    ├── Get-ArubaInstantShowCmdResult.ps1
    ├── Get-ArubaInstantClients.ps1
    ├── Get-ArubaInstantAP.ps1
    ├── Get-AurbaInstantAPImageVersion.ps1
    ├── Get-AurbaInstantShowSummary.ps1
    └── Get-AurbaInstantShowStatsAP.ps1
```

## Common Use Cases

### Monitor client connections
```powershell
# Get all clients and filter by SSID
$clients = Get-ArubaInstantClient
$guestClients = $clients | Where-Object { $_.SSID -eq "Guest-WiFi" }
```

### Check AP health
```powershell
# Get all APs and check their status
$aps = Get-ArubaInstantAP
$downAps = $aps | Where-Object { $_.Status -ne "Up" }
if ($downAps) {
    Write-Warning "The following APs are down: $($downAps.Name -join ', ')"
}
```

### Audit firmware versions
```powershell
# Check firmware version across all APs
$version = Get-AurbaInstantAPImageVersion
Write-Host "Current firmware: $version"
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
