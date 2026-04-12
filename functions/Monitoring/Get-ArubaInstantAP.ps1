function Get-ArubaInstantAP {
    <#
    .SYNOPSIS
        Retrieves the list of Aruba Instant access points

    .DESCRIPTION
        Executes the "show aps" command via the API and parses the output into
        a structured format. Returns information about all access points managed
        by the Instant controller, including status, model, and serial numbers.
        Adds controller information to each AP object.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .PARAMETER iap_ip_addr
        The IP address of the target IAP. Defaults to the controller IP if not specified.

    .OUTPUTS
        [array]. Array of hashtables, each representing an access point.

    .EXAMPLE
        Get-ArubaInstantAP

    .EXAMPLE
        Get-ArubaInstantAP -ArubaInstantAPI $conn -iap_ip_addr "192.168.1.10"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaInstantAPI }
        $oIAPIPAddr = if ($iap_ip_addr) { $iap_ip_addr } else { $oArubaInstantAPI.IPAddress }
        $hParam = @{
            cmd = "show aps"
            iap_ip_addr = $oIAPIPAddr
        }
        $oWifiController = $oArubaInstantAPI.MoreInfo
    }
    Process {
        $oResult = $oArubaInstantAPI.CallAPIGet("show-cmd", $hParam)
        $oResult = $oResult.'Command output' | Remove-EmptyString
        $oResult = $oResult.Split("`n")
        $oResult = $oResult[4..($oResult.Count)]
        $aResult = Convert-TSVWithDashLine $oResult
        foreach ($oAP in $aResult) {
            $oAP.Controller = $oWifiController
        }
        return $aResult
    }
}