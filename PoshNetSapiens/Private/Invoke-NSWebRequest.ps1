function Invoke-NSWebRequest {
    [CmdletBinding()]
    param(
        $Arguments,
        [int]$MaxRetry = 5
    )

    # Check that we have cached connection info
    if(!$script:NSServerConnection){
        $ErrorMessage = @()
        $ErrorMessage += "Not connected to a NetSapiens server."
        $ErrorMessage += '--> $NSServerConnection variable not found.'
        $ErrorMessage += "----> Run 'Connect-NS' to initialize the connection before issuing other NS cmdlets."
        return Write-Error ($ErrorMessage | Out-String)
    }

    # Add default set of arguments
    foreach($Key in $script:NSServerConnection.Headers.Keys){
        if($Arguments.Headers.Keys -notcontains $Key){            
            $Arguments.Headers += @{$Key = $script:NSServerConnection.Headers.$Key}            
        }
    }

    # Issue request
    try {
        Write-Debug "Arguments: $($Arguments | ConvertTo-Json)"
        $Result = Invoke-RestMethod @Arguments -UseBasicParsing
    }
    catch {
        # Start error message
        $ErrorMessage = @()

        if($_.Exception.Response){
            try {
                # Read exception response
                #this can fail with some type of exceptions
                $ErrorStream = $_.Exception.Response.GetResponseStream()
                $Reader = New-Object System.IO.StreamReader($ErrorStream)
                $script:ErrBody = $Reader.ReadToEnd() | ConvertFrom-Json
            }
            catch {
                $script:ErrBody = $_.Exception.Response.Content
            }
            $ErrBody = $script:ErrBody
            if($ErrBody.code){
                $ErrorMessage += "An exception has been thrown."
                $ErrorMessage += "--> $($ErrBody.code)"
                if($ErrBody.code -eq 'Unauthorized'){
                    $ErrorMessage += "-----> $($ErrBody.message)"
                    $ErrorMessage += "-----> Use 'Disconnect-CWM' or 'Connect-CWM -Force' to set new authentication."
                }
                else {
                    $ErrorMessage += "-----> $($ErrBody.code): $($ErrBody.message)"
                    $ErrorMessage += "-----> ^ Error has not been documented please report. ^"
                }
            } elseif ($_.Exception.message) {
                $ErrorMessage += "An exception has been thrown."
                $ErrorMessage += "--> $($_.Exception.message)"
            }
        }

        if ($_.ErrorDetails) {
            $ErrorMessage += "An error has been thrown."
            $script:ErrDetails = $_.ErrorDetails
            $ErrorMessage += "--> $($ErrDetails.code)"
            $ErrorMessage += "--> $($ErrDetails.message)"
            if($ErrDetails.errors.message){
                $ErrorMessage += "-----> $($ErrDetails.errors.message)"
            }
        }

        if ($ErrorMessage.Length -lt 1){ $ErrorMessage = $_ }
        else { $ErrorMessage += $_.ScriptStackTrace }

        return Write-Error ($ErrorMessage | out-string)
    }

    return $Result
}