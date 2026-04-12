function Get-ArubaInstantNetwork {
    <#
    .SYNOPSIS
        Retrieves the list of Wi-Fi networks (SSIDs) broadcast by an Aruba Instant controller.

    .DESCRIPTION
        Queries an Aruba Instant Access Point via its API to retrieve wireless network
        configurations. When called without the -Network parameter, returns a summary
        list of all configured networks. When a specific network name is provided,
        returns its full configuration including properties, role/VLAN derivation rules,
        RADIUS/LDAP/accounting servers, access rules, and captive portal settings.
        The -All switch enriches the summary list by fetching detailed configuration
        for each network.

    .PARAMETER ArubaInstantAPI
        The Aruba Instant API connection object. If not specified, uses the global
        $Global:ArubaInstantAPI variable.

    .PARAMETER iap_ip_addr
        The IP address of the Instant Access Point to query.

    .PARAMETER network
        The name (profile name) of a specific network to retrieve detailed configuration for.
        When omitted, returns the summary list of all networks.

    .PARAMETER IncludeDetails
        Switch parameter. When specified without -Network, retrieves the full detailed
        configuration for each network and adds it as a "Details" property on each
        summary entry. Without this switch, only the summary list is returned.

    .OUTPUTS
        Without -Network: an array of objects with network summary information (profile name, etc.).
        With -Network: an ordered hashtable containing:
        - Properties: general network settings (key-value pairs)
        - Role Derivation Rules: role assignment rules table
        - Vlan Derivation Rules: VLAN assignment rules table
        - RADIUS Servers: configured RADIUS servers table
        - LDAP Servers: configured LDAP servers table
        - Accounting Servers: configured accounting servers table
        - Access Rules: firewall/ACL rules table
        - Captive Portal Configuration: captive portal settings (key-value pairs)
        - External Captive Portal Configuration: external portal settings (key-value pairs)

    .EXAMPLE
        $networks = Get-ArubaInstantNetwork -iap_ip_addr "10.0.0.1"
        # Returns summary list of all Wi-Fi networks

    .EXAMPLE
        $details = Get-ArubaInstantNetwork -iap_ip_addr "10.0.0.1" -network "Corporate-WiFi"
        # Returns full configuration of the "Corporate-WiFi" network

    .EXAMPLE
        $allDetails = Get-ArubaInstantNetwork -iap_ip_addr "10.0.0.1" -IncludeDetails
        # Returns summary list with detailed configuration embedded in each entry

    .NOTES
        Author: Loïc Ade
        Version: 1.0.0
        Dependencies: Select-LineRange (PSSomeDataThings),
                      Convert-StringArrayToHashtable (PSSomeDataThings),
                      Convert-TSVWithDashLine (PSSomeDataThings)

        CHANGELOG:

        Version 1.0.0 - 2026-04-12 - Loïc Ade
            - Initial release
            - Summary and detailed network query modes
            - Parsing of role/VLAN derivation rules, server lists, access rules,
              and captive portal configuration
            - Recursive detail fetching with -All switch
    #>
   Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr,
        [string]$network,
        [switch]$IncludeDetails
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaInstantAPI }
    }
    Process {
        if ($network) {
            $aLines = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $oArubaInstantAPI -cmd "show network $network" -iap_ip_addr $iap_ip_addr -ReturnResult
            $aLines = $aLines[2..($aLines.Count)]
            $hProperties = @{}
            $hProperties += Select-LineRange -InputArray $aLines -EndRegex "^Role Derivation Rules$" -IncludeEndLine $false | Convert-StringArrayToHashtable
            $hProperties += Select-LineRange -InputArray $aLines -StartRegex "^ACL Vlan.*" -IncludeStartLine $true -EndRegex "^Access Rules$" -IncludeEndLine $false | Convert-StringArrayToHashtable
            return [ordered]@{
#                Lines = $aLines
                Properties = $hProperties
                "Role Derivation Rules" = Select-LineRange -InputArray $aLines -StartRegex "^Role Derivation Rules$" -IncludeStartLine $false -EndRegex "^Vlan Derivation Rules$" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "Vlan Derivation Rules" = Select-LineRange -InputArray $aLines -StartRegex "^Vlan Derivation Rules$" -IncludeStartLine $false -EndRegex "^RADIUS Servers$" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "RADIUS Servers" = Select-LineRange -InputArray $aLines -StartRegex "^RADIUS Servers$" -IncludeStartLine $false -EndRegex "^LDAP Servers$" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "LDAP Servers" = Select-LineRange -InputArray $aLines -StartRegex "^LDAP Servers$" -IncludeStartLine $false -EndRegex "^Accounting Servers$" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "Accounting Servers" = Select-LineRange -InputArray $aLines -StartRegex "^Accounting Servers$" -IncludeStartLine $false -EndRegex "^ACL Vlan.*" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "Access Rules" = Select-LineRange -InputArray $aLines -StartRegex "^Access Rules$" -IncludeStartLine $false -EndRegex "^:Captive Portal Configuration$" -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "Captive Portal Configuration" = Select-LineRange -InputArray $aLines -StartRegex "^:Captive Portal Configuration$" -IncludeStartLine $false -EndRegex "^:External Captive Portal Configuration$" -IncludeEndLine $false | Convert-StringArrayToHashtable
                "External Captive Portal Configuration" = Select-LineRange -InputArray $aLines -StartRegex "^:External Captive Portal Configuration$" -IncludeStartLine $false | Convert-StringArrayToHashtable
            } 
        } else {
            $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $oArubaInstantAPI -cmd "show network" -iap_ip_addr $iap_ip_addr -ReturnResult
            $oResult = $oResult[4..($oResult.Count)]
            $aResult = Convert-TSVWithDashLine $oResult
            if ($IncludeDetails) {
                foreach ($oNetwork in $aResult) {
                    $oNetwork.Details = Get-ArubaInstantNetwork -ArubaInstantAPI $oArubaInstantAPI -iap_ip_addr $iap_ip_addr -network $oNetwork."Profile Name"
                }
            }
            return $aResult
        }
    }
}