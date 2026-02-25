function Get-ArubaInstantShowCmdResult {
    <#
    .SYNOPSIS
        Executes a show command on an Aruba Instant access point

    .DESCRIPTION
        Runs a CLI show command via the Aruba Instant REST API and returns the result.
        If no IAP IP address is specified, uses the controller's IP address from the
        connection object.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .PARAMETER cmd
        The show command to execute (e.g., "show clients", "show ap database").

    .PARAMETER iap_ip_addr
        The IP address of the target IAP. Defaults to the controller IP if not specified.

    .OUTPUTS
        [hashtable]. The API response with command output.

    .EXAMPLE
        Get-ArubaInstantShowCmdResult -cmd "show clients"

    .EXAMPLE
        Get-ArubaInstantShowCmdResult -ArubaInstantAPI $conn -cmd "show ap database" -iap_ip_addr "192.168.1.10"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ArubaInstantAPI,
        [Parameter(Mandatory, Position = 0)]
        [string]$cmd,
        [string]$iap_ip_addr
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaMobilityControllerAPI }
        $hParam = Get-FunctionParameters -RemoveParam "ArubaInstantAPI"
        if (-not $iap_ip_addr) { $hParam.iap_ip_addr = $oArubaInstantAPI.IPAddress }
    }
    Process {
        $oResult = $oArubaInstantAPI.CallAPIGet("show-cmd", $hParam)
        return $oResult
    }
}