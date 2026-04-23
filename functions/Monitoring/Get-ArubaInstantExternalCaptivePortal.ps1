function Get-ArubaInstantExternalCaptivePortal {
    <#
    .SYNOPSIS
        Retrieves the list of external captive portals configured on an Aruba Instant controller.

    .DESCRIPTION
        Queries an Aruba Instant Access Point via its API to retrieve external captive
        portal configurations. Without -Name, returns a summary list of all configured
        portals. With -Name, returns the full configuration of that specific portal as
        a hashtable.

    .PARAMETER ArubaInstantAPI
        The Aruba Instant API connection object. If not specified, uses the global
        $Global:ArubaInstantAPI variable.

    .PARAMETER iap_ip_addr
        The IP address of the Instant Access Point to query.

    .PARAMETER Name
        The name of a specific external captive portal to retrieve detailed configuration for.
        When omitted, returns the summary list of all portals.

    .OUTPUTS
        Without -Name: an array of objects with portal summary information.
        With -Name: a hashtable with portal properties (Name, Server, Port, Url, etc.).

    .EXAMPLE
        Get-ArubaInstantExternalCaptivePortal -ArubaInstantAPI $conn
        # Returns the list of configured external captive portals

    .EXAMPLE
        Get-ArubaInstantExternalCaptivePortal -ArubaInstantAPI $conn -Name "ClearPass"
        # Returns the detailed configuration of the ClearPass external captive portal

    .NOTES
        Author: Loic Ade
        Version: 1.0.0
        Dependencies: Convert-StringArrayToHashtable (PSSomeDataThings),
                      Convert-TSVWithDashLine (PSSomeDataThings)

        1.0.0 (2026-04-17) - Initial version
    #>
    Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr,
        [string]$Name
    )
    Process {
        if ($Name) {
            $aLines = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -cmd "show external-captive-portal $Name" -iap_ip_addr $iap_ip_addr -ReturnResult 
            return $aLines | Convert-StringArrayToHashtable
        } else {
            $aLines = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -cmd "show external-captive-portal" -iap_ip_addr $iap_ip_addr -ReturnResult
            # Skip header: "External Captive Portal" + "-----------------------"
            $aLines = $aLines[2..($aLines.Count)]
            return Convert-TSVWithDashLine $aLines
        }
    }
}
