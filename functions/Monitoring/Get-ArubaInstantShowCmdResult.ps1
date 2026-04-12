function Get-ArubaInstantShowCmdResult {
    <#
    .SYNOPSIS
        Executes a show command on an Aruba Instant access point.

    .DESCRIPTION
        Runs a CLI show command via the Aruba Instant REST API and returns the result.
        If no IAP IP address is specified, uses the controller's IP address from the
        connection object. By default returns the full API response object. With
        -ReturnResult, returns only the command output as a cleaned string array
        (empty lines removed, split by newline).

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .PARAMETER cmd
        The show command to execute (e.g., "show clients", "show network").

    .PARAMETER iap_ip_addr
        The IP address of the target IAP. Defaults to the controller IP if not specified.

    .PARAMETER ReturnResult
        Switch parameter. When specified, returns only the command output as a string
        array (empty lines removed) instead of the full API response object.

    .OUTPUTS
        [hashtable] when called without -ReturnResult — the full API response.
        [string[]] when called with -ReturnResult — the command output lines.

    .EXAMPLE
        $response = Get-ArubaInstantShowCmdResult -cmd "show clients"
        # Returns full API response object

    .EXAMPLE
        $lines = Get-ArubaInstantShowCmdResult -cmd "show network" -ReturnResult
        # Returns command output as string array

    .EXAMPLE
        Get-ArubaInstantShowCmdResult -ArubaInstantAPI $conn -cmd "show ap database" -iap_ip_addr "192.168.1.10"
        # Targets a specific IAP

    .NOTES
        Author: Loïc Ade
        Version: 1.1.0
        Dependencies: Remove-EmptyString (PSSomeDataThings)

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Added ReturnResult parameter to return cleaned command output as string array
            - Added throw on command failure (non-Success status)

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - CLI show command execution via Aruba Instant REST API
            - Automatic IAP IP fallback to controller IP
    #>
    Param(
        [object]$ArubaInstantAPI,
        [Parameter(Mandatory, Position = 0)]
        [string]$cmd,
        [AllowNull()]
        [string]$iap_ip_addr,
        [switch]$ReturnResult
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaMobilityControllerAPI }
        $hParam = @{
            cmd = $cmd
        }
        if ([string]::IsNullOrEmpty($iap_ip_addr)) {
            $hParam.iap_ip_addr = $oArubaInstantAPI.IPAddress
        } else {
            $hParam.iap_ip_addr = $iap_ip_addr
        }
    }
    Process {
        $oResult = $oArubaInstantAPI.CallAPIGet("show-cmd", $hParam)
        if ($oResult.Status -eq "Success") {
            if ($ReturnResult) { 
                $oResult = $oResult.'Command output' | Remove-EmptyString
                $oResult = $oResult.Split("`n")
                return $oResult
            } else {
                return $oResult                
            }
        } else {
            throw $oResult.message
        }
    }
}