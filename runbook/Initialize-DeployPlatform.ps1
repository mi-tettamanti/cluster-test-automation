workflow Initialize-DeployPlatform
{
	param
    (
        [parameter(Mandatory=$true)]
        [String]
        $AzureSubscriptionName,

		[parameter(Mandatory=$true)]
        [String]
        $AzureOrgIdCredentialName,
        
        [parameter(Mandatory=$true)]
        [String]
        $ServiceName,
        
        [parameter(Mandatory=$true)]
        [String]
        $VMName,  
        
        [parameter(Mandatory=$true)]
        [String]
        $VMCredentialName,
		
		[parameter(Mandatory=$true)]
        [String]
        $StorageAccountName
	)
	
	$VerbosePreference = "Continue"
	
    $cred = Get-AutomationPSCredential -Name $AzureOrgIdCredentialName
    $vmCred = Get-AutomationPSCredential -Name $VMCredentialName
    
	Write-Verbose ("Checking deployer path...")
    
	$vmUri = Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -AzureOrgIdCredential $cred -ServiceName $ServiceName -VMName $VMName  
    $deployerPath = InlineScript
    {
        Invoke-command -ConnectionUri $Using:vmUri -credential $Using:vmCred -ScriptBlock { 
            $env:DeployerPath
        }
    }
    
    if (-not $deployerPath)
    {
        Write-Verbose ("Path not found, installing...")
        
        InlineScript
        {
            Invoke-command -ConnectionUri $Using:vmUri -credential $Using:vmCred -ScriptBlock { 
                mkdir 'C:\Reply\Deployer' -force
            }
        }
        
		Write-Verbose ("Retrieve deployer package...")
		
        Copy-BlobFromAzureStorage `
            -AzureSubscriptionName $AzureSubscriptionName `
            -AzureOrgIdCredential $cred `
            -StorageAccountName $StorageAccountName `
            -ContainerName "resources" `
            -BlobName "Reply-Deployer.zip"
        
		Write-Verbose ("Copy deployer package...")

        Copy-ItemToAzureVM `
            -AzureSubscriptionName $AzureSubscriptionName `
            -AzureOrgIdCredential $cred `
            -ServiceName $ServiceName `
            -VMName $VMName `
            -VMCredentialName $VMCredentialName `
            -LocalPath "C:\Reply-Deployer.zip" `
            -RemotePath "C:\Reply\Deployer\Reply-Deployer.zip" `
            -BufferSize 10240
        
		Write-Verbose ("Deployer package copied...")
        
        InlineScript
        {
            Invoke-command -ConnectionUri $Using:vmUri -credential $Using:vmCred -ScriptBlock { 
                add-type -assemblyName 'System.IO.Compression.FileSystem'
                [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\Reply\Deployer\Reply-Deployer.zip', 'C:\Reply\Deployer')
                
				[Environment]::SetEnvironmentVariable('DeployerPath', 'C:\Reply\Deployer', 'Machine')
				[Environment]::SetEnvironmentVariable('DEPLOYER_CONNECTIONSTRING', 'Data Source=C:\Reply\Deployer\deployerTable.db', 'Machine')
				
				rm 'C:\Reply\Deployer\Reply-Deployer.zip'
            }
        }
    }
    
    Write-Verbose ("Deployer initialized.")
}