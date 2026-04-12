function Get-AurbaInstantShowStatsAP {
    <#
    .SYNOPSIS
        Retrieves statistics for a specific Aruba Instant access point

    .DESCRIPTION
        Executes the "show stats ap <IP>" command via the API and parses the output
        into structured data. Returns usage statistics, RF trends, client heatmap, and
        AP list. Can optionally return only the AP list.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, Get-ArubaInstantShowCmdResult
        will use $Global:ArubaInstantAPI.

    .PARAMETER IP
        The IP address of the access point to query.

    .PARAMETER OnlyAPList
        If specified, returns only the AP list section instead of full statistics.

    .OUTPUTS
        [hashtable]. Contains Lines and either full stats (Properties, Usage, "RF Trends",
        "Client Heatmap", "AP List") or just "AP List" if -OnlyAPList is used.

    .EXAMPLE
        Get-AurbaInstantShowStatsAP -IP "192.168.1.10"

    .EXAMPLE
        Get-AurbaInstantShowStatsAP -ArubaInstantAPI $conn -IP "192.168.1.10" -OnlyAPList

    .NOTES
        Author: Loïc Ade
        Version: 1.1.0
        Dependencies: Select-LineRange, Convert-StringArrayToHashtable,
                      Convert-TSVWithDashLine (PSSomeDataThings)

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Removed local global variable resolution (delegated to
              Get-ArubaInstantShowCmdResult)

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - Parses "show stats ap" output into structured data
            - OnlyAPList option for lightweight queries
    #>
    Param(
        [object]$ArubaInstantAPI,
        [Parameter(Mandatory)]
        [string]$IP,
        [switch]$OnlyAPList
    )
    Begin {
        $sCommand = "show stats ap $IP"
    }
    Process {
        $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -cmd $sCommand
        $aLines = $oResult.'Command output'.Split("`n")
        if ($OnlyAPList) {
            $hResult = @{
                Lines = $aLines
                "AP List" = Select-LineRange -InputArray $aLines -StartRegex "^AP List$" -IncludeStartLine $false -FromEnd | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
            }
        } else {
            $hResult = @{
                Lines = $aLines
                Properties = Select-LineRange -InputArray $aLines -EndRegex "^Usage$" -IncludeEndLine $false | Select-Object -Skip 4 | Convert-StringArrayToHashtable
                Usage = Select-LineRange -InputArray $aLines -StartRegex "^Usage$"  -IncludeStartLine $false -EndRegex "^RF Trends$"  -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "RF Trends" = Select-LineRange -InputArray $aLines -StartRegex "^RF Trends$" -IncludeStartLine $false -EndRegex "^Client Heatmap$"  -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "Client Heatmap" = Select-LineRange -InputArray $aLines -StartRegex "^Client Heatmap$" -IncludeStartLine $false -EndRegex "^AP List$"  -IncludeEndLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
                "AP List" = Select-LineRange -InputArray $aLines -StartRegex "^AP List$" -IncludeStartLine $false | Select-Object -Skip 1 | Convert-TSVWithDashLine -ToPSObject
            }    
        }
        return $hResult
    }
}