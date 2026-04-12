function Get-ArubaInstantClient {
    <#
    .SYNOPSIS
        Retrieves the list of connected clients from an Aruba Instant access point

    .DESCRIPTION
        Executes the "show clients" command via the API and parses the output
        into a structured format. Returns client connection information including
        MAC addresses, IP addresses, usernames, and connection details.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .PARAMETER iap_ip_addr
        The IP address of the target IAP. Defaults to the controller IP if not specified.

    .OUTPUTS
        [array]. Array of hashtables, each representing a connected client.

    .EXAMPLE
        Get-ArubaInstantClient

    .EXAMPLE
        Get-ArubaInstantClient -ArubaInstantAPI $conn -iap_ip_addr "192.168.1.10"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr
    )
    Begin {
        function Get-ArubaInstantShowClientsResult {
            Param(
                [object]$ArubaInstantAPI,
                [string]$iap_ip_addr
            )
            Begin {
                $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaInstantAPI }
                $oIAPIPAddr = if ($iap_ip_addr) { $iap_ip_addr } else { $oArubaInstantAPI.IPAddress }
            }
            Process {
                return Get-ArubaInstantShowCmdResult -ArubaInstantAPI $oArubaInstantAPI -cmd "show clients" -iap_ip_addr $oIAPIPAddr
            }
        }
        
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaInstantAPI }
        $oIAPIPAddr = if ($iap_ip_addr) { $iap_ip_addr } else { $oArubaInstantAPI.IPAddress }
    }
    Process {
        $oResult = Get-ArubaInstantShowClientsResult -ArubaInstantAPI $oArubaInstantAPI -iap_ip_addr $oIAPIPAddr
        $oResult = $oResult.'Command output' | Remove-EmptyString
        $oResult = $oResult.Split("`n")
        $oResult = $oResult[4..($oResult.Count - 3)]
        return Convert-TSVWithDashLine $oResult
    }
}