function Connect-NS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$server,
        [Parameter(Mandatory=$true)]
        [string]$username,
        [Parameter(Mandatory=$true)]
        [string]$password,
        [Parameter(Mandatory=$true)]
        [string]$clientID,
        [Parameter(Mandatory=$true)]
        [string]$clientSecret
        
    )

    if ((($script:NSServerConnection -and !$script:NSServerConnection.expiration) `
    -or $script:NSServerConnection.expiration -gt $(Get-Date)) -and !$Force) {
        Write-Verbose "Using cached Authentication information."
        return
    }

    $script:NSServerConnection = @{
        Server = $server

    }
    # Obtain Bearer Token
    Write-Verbose "Obtaining Bearer Token"
    
    $WebRequestArguments = @{
        Method = 'Post'
        Uri = "https://$($server)/ns-api/oauth2/token/"
        Body = @{ 
            grant_type = 'password'
            client_id = $clientID
            client_secret = $clientSecret
            username = $username
            password = $password
         }
        #ContentType = 'application/json'
        #Headers = $Headers
    }
    $Result = Invoke-NSWebRequest -Arguments $WebRequestArguments
    if($Result){
        #$Result = $Result.content | ConvertFrom-Json
    }
    else {
        Write-Error "Issue getting Auth Token for Impersonated user, $MemberID"
        Write-Error $Result
        return
    }

    # Create auth header for bearer token
    $expiration = (Get-Date).AddSeconds($Result.expires_in)
    $accessToken  = $Result.access_token
    $Headers = @{
        Authorization = "Bearer $accessToken"
        'Accept' = 'application/json'
        'Cache-Control'= 'no-cache'
    }
    

    # not enough info
    #else {
    #    Write-Error "Valid authentication parameters not passed"
    #    return
    #}

    # Create the Server Connection object
    $script:NSServerConnection = @{
        Server = $Server
        Headers = $Headers
        Session = $script:NSSession
        Expiration = $expiration
        ConnectionMethod = $ConnectionMethod
        Version = $Version
        Codebase = $CompanyInfo.Codebase
        BasePath = $BasePath
    }

    # Validate connection info
    Write-Verbose 'Validating authentication'
    #TODO
    #$Info = Get-CWMSystemInfo
    #if(!$Info) {
    #    Write-Warning 'Authentication failed. Clearing connection settings.'
    #    Disconnect-CWM
    #    return
    #}

    Write-Verbose 'Connection successful.'
    Write-Verbose '$NSServerConnection, variable initialized.'
}