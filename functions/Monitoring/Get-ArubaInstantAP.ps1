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
        Author: Loïc Ade
        Version: 1.1.0
        Dependencies: Convert-TSVWithDashLine (PSSomeDataThings)

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Refactored to use Get-ArubaInstantShowCmdResult -ReturnResult
              instead of direct API call and manual parsing

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - Retrieves and parses access point list from "show aps" command
            - Adds controller information to each AP object
    #>
    Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaInstantAPI }
        $oWifiController = $oArubaInstantAPI.MoreInfo
    }
    Process {
        $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $oArubaInstantAPI -cmd "show aps" -iap_ip_addr $iap_ip_addr -ReturnResult
        $oResult = $oResult[4..($oResult.Count)]
        $aResult = Convert-TSVWithDashLine $oResult
        foreach ($oAP in $aResult) {
            $oAP.Controller = $oWifiController
        }
        return $aResult
    }
}