function Connect-ArubaInstantAPI {
    <#
    .SYNOPSIS
        Establishes a connection to the Aruba Instant API

    .DESCRIPTION
        Creates a connection object for interacting with the Aruba Instant API.
        Returns an object with methods for authentication, session management, and
        API calls (GET, POST, PUT). Automatically handles session expiration and
        reconnection. Optionally stores the connection in a global variable.

    .PARAMETER Address
        The hostname or IP address of the Aruba Instant controller.

    .PARAMETER Port
        The port number for the API (typically 4343 for HTTPS).

    .PARAMETER Username
        The username for authentication.

    .PARAMETER Password
        The password as a SecureString.

    .PARAMETER ignoreSSLError
        If specified, disables SSL certificate validation.

    .PARAMETER MoreInfo
        Optional additional information to store in the connection object.

    .PARAMETER GlobalVar
        If specified, stores the connection in $Global:ArubaInstantAPI instead of returning it.

    .OUTPUTS
        [hashtable]. A connection object with methods: IgnoreSSL(), Reconnect(), InvokeWebRequest(),
        CallAPIGet(), and CallAPI(). Returns $null if connection fails.

    .EXAMPLE
        $conn = Connect-ArubaInstantAPI -Address "192.168.1.1" -Port 4343 -Username "admin" -Password $securePass

    .EXAMPLE
        Connect-ArubaInstantAPI -Address "controller.local" -Port 4343 -Username "admin" -Password $securePass -GlobalVar

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Position = 0)]
        [Alias("Server")]
        [string]$Address,
        [Parameter(Position = 1)]
        [int]$Port,
        [Parameter(Position = 2)]
        [string]$Username,
        [Parameter(Position = 3)]
        [securestring]$Password,
        [switch]$ignoreSSLError,
        [object]$MoreInfo,
        [switch]$GlobalVar
    )

    $bIsIP = Test-StringIsIP -string $Address -MaskForbidden
    $IPAddress = if ($bIsIP) {
        $Address
    } else {
        (Resolve-DnsName -Name $Address -Type A).IPAddress
    }

    $oResult = [ordered]@{
        Address = $Address
        Port = $Port
        Username = $Username
        Password = $Password
        Credential = New-Object System.Management.Automation.PSCredential($Username,$Password)
        BaseURL = "https://$Address`:$Port/rest/"
        IgnoreSSLError = $ignoreSSLError.IsPresent
        Session = $null
        IPAddress = $IPAddress
        MoreInfo = $MoreInfo
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "IgnoreSSL" -Value {
        if ($this.IgnoreSSLError) {
            Invoke-IgnoreSSL
        }
    }
    
    $oResult | Add-Member -MemberType ScriptMethod -Name "Reconnect" -Value {
        $this.IgnoreSSL()
        $ping = (Test-NetConnection -ComputerName $this.Address -Port $this.Port)
        if ($ping.TcpTestSucceeded) {
            $headers = @{
                "Content-Type" = "application/json"
            }
            $sUrl = $this.BaseURL + "login"
            $sData = @{
                user = $this.Username
                passwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password))
            } | ConvertTo-Json
            Set-UseUnsafeHeaderParsing -Enable
            $oAPICall = Invoke-WebRequest -Uri $sUrl -Method Post -Body $sData -Headers $headers -UseBasicParsing
            Set-UseUnsafeHeaderParsing -Disable
            $oResult = $oAPICall.Content | ConvertFrom-Json | ConvertTo-Hashtable
            $this.Session = $oResult
            if ($this.Session."Error Message" -eq "Login failed") {
                throw "Login failed"
            }
            return $true
        } else {
            return $false
        }        
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "InvokeWebRequest" -Value {
        Param([hashtable]$arguments)
        $oAPICall = try {
            Set-UseUnsafeHeaderParsing -Enable
            $oResult = Invoke-WebRequest @arguments
            Set-UseUnsafeHeaderParsing -Disable
            if ($oResult.message -eq "Invalid session id or session id has expired") {
                throw [System.Net.WebException] "Invalid session id or session id has expired"
            } else {
                $oResult
            }
        } catch [System.Net.WebException] {
            try {
                $this.Reconnect() | Out-Null
                Set-UseUnsafeHeaderParsing -Enable
                Invoke-WebRequest @arguments
                Set-UseUnsafeHeaderParsing -Disable
            } catch {
                $_.Exception.Response
            }
        }
        return $oAPICall
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPIGet" -Value {
        Param([string]$url,[hashtable]$arguments,[bool]$Verbose = $false)
        $this.IgnoreSSL()
        $headers = @{
            #"Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        
        $sUrl = if ($url -like "*://*") {
            $url
        } else {
            $this.BaseURL + $url
        }

        $hNewArgs = @{}
        foreach ($key in $arguments.Keys) {
            if ($url -like "*{$key}*") {
                $sUrl = $sUrl -replace "{$key}", $arguments[$key]
            } else {
                $hNewArgs.$key = $arguments[$key]
            }
        }

        if ($hNewArgs.Keys.Count -gt 0) {
            $sURL = $sUrl + "?" + (Convert-HashtableToURLArguments -Arguments $hNewArgs) + "&sid=" + $this.Session.sid
        } else {
            $sURL = $sUrl + "?sid=" + $this.Session.sid
        }

        $iwrArgs = @{
            Headers = $headers
            Uri = $sUrl
            Method = "Get"
            Credential = $this.Credential
            UseBasicParsing = $true
        }

        $oAPICall = $this.InvokeWebRequest($iwrArgs)
        $oResult = $oAPICall.Content | ConvertFrom-Json | ConvertTo-Hashtable
        if ($oResult."Status-code" -gt 0) {
            $this.Reconnect() | Out-Null
            $oAPICall = $this.InvokeWebRequest($iwrArgs)
        }
        $sStatus = if (($oAPICall.StatusCode -ge 200) -and ($oAPICall.StatusCode -le 299)) { "OK" } else { "Error" }
        $oResult = $oAPICall.Content | ConvertFrom-Json | ConvertTo-Hashtable
        if ($Verbose -or ($sStatus -eq "Error")) {
            $hResult = [ordered]@{
                http = $oAPICall
                json = $oResult
                status = $sStatus
                url = $sUrl
                body = $sbody
            }
            return $hResult    
        } else {
            $oResult
        }
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPI" -Value {
        Param([string]$url,[Microsoft.PowerShell.Commands.WebRequestMethod]$method = "Get",[hashtable]$arguments,[bool]$Verbose = $false)
        $this.IgnoreSSL()
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        $sBody = if ($body) {
            if ($Body -is [string]) {
                $Body
            } else{
                $Body | ConvertTo-Hashtable | ConvertTo-Json
            }
        } else {
            "{}"
        }
        $sUrl = if ($url -like "*://*") {
            $url
        } else {
            $this.BaseURL + $url
        }

        $iwrArgs = @{
            Headers = $headers
            Uri = $sUrl
            Method = $method
            UseBasicParsing = $true
        }
        if ($method -in @("Post", "Put")) {
            $iwrArgs.Body = $sBody
        }

        $oAPICall = try {
            $o = Invoke-RestMethod @iwrArgs
            if ($o."Status-code" -gt 0) {
                throw [System.Net.WebException] "Error while running query"
            } else {
                $o
            }
        } catch [System.Net.WebException] {
            try {
                $this.Reconnect()
                Invoke-RestMethod @iwrArgs
            } catch {
                $_.Exception.Response
            }
        }
        $sStatus = if (($oAPICall.StatusCode -ge 200) -and ($oAPICall.StatusCode -le 299)) { "OK" } else { "Error" }
        $oResult = $oAPICall.Content | ConvertFrom-Json
        if ($Verbose -or ($sStatus -eq "Error")) {
            $hResult = [ordered]@{
                http = $oAPICall
                json = $oResult
                status = $sStatus
                url = $sUrl
                body = $sbody
            }
            return $hResult    
        } else {
            $oResult
        }
    }

    if ($oResult.Reconnect()) {
        if ($GlobalVar.IsPresent) {
            $Global:ArubaInstantAPI = $oResult
        } else {
            return $oResult
        }    
    } else {
        return $null
    }
}