workflow Execute-Deploy
{
	param (
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
        $StorageAccountName,
	    [parameter(Mandatory=$true)]
        [String]
        $PackageName
	)
	
    $cred = Get-AutomationPSCredential -Name $AzureOrgIdCredentialName
    
    Initialize-DeployPlatform `
        -AzureSubscriptionName $AzureSubscriptionName `
        -AzureOrgIdCredentialName $AzureOrgIdCredentialName `
        -StorageAccountName $StorageAccountName `
        -ServiceName $ServiceName `
        -VMName $VMName `
        -VMCredentialName $VMCredentialName
        
    Copy-BlobFromAzureStorage `
        -AzureSubscriptionName $AzureSubscriptionName `
        -AzureOrgIdCredential $cred `
        -StorageAccountName $StorageAccountName `
        -ContainerName "resources" `
        -BlobName "$PackageName.zip"
    
    Copy-ItemToAzureVM `
        -AzureSubscriptionName $AzureSubscriptionName `
        -AzureOrgIdCredential $cred `
        -ServiceName $ServiceName `
        -VMName $VMName `
        -VMCredentialName $VMCredentialName `
        -LocalPath "C:\$PackageName.zip" `
        -RemotePath "C:\Reply\Deployer\$PackageName.zip" `
        -BufferSize 10240  

    $vmUri = Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -AzureOrgIdCredential $cred -ServiceName $ServiceName -VMName $VMName
	$vmCred = Get-AutomationPSCredential -Name $VMCredentialName

	InlineScript
    {
        Invoke-command -ConnectionUri $Using:vmUri -credential $Using:vmCred -ScriptBlock { 
			param($PackageName)
			
            add-type -assemblyName 'System.IO.Compression.FileSystem'
            [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\Reply\Deployer\$PackageName.zip", "C:\Reply\Deployer\$PackageName")
            
            C:\Reply\Deployer\booi.exe "C:\Reply\Deployer\$PackageName\Deploy.boo"
            
			rm "C:\Reply\Deployer\$PackageName" -Recurse
			rm "C:\Reply\Deployer\$PackageName.zip"
        } -ArgumentList $Using:PackageName
    }          
}