function Get-NSDomain {
    [CmdletBinding()]
    param(
        [string]$domain
    )

    $WebRequestArguments = @{
        Method = 'Post'
        Uri = "https://$($NSServerConnection.Server)/ns-api/?object=domain&action=read"        
    }
    if ($domain)
    {
        $Body = @{ 
            domain = $domain
        }
        
        $WebRequestArguments.Add('Body',$Body)
    }
    $result = Invoke-NSWebRequest -Arguments $WebRequestArguments
    return $result
    
}