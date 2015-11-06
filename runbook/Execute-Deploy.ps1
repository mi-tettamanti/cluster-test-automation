workflow Execute-Deploy
{
    $AzureSubscriptionName = """
    $AzureOrgIdCredentialName = ""
    $ServiceName = ""
    $VMName = ""
    $VMCredentialName = ""
    $StorageAccountName = ""
    $PackageName = ""
    
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
        -BlobName $PackageName
    
    Copy-ItemToAzureVM `
        -AzureSubscriptionName $AzureSubscriptionName `
        -AzureOrgIdCredential $cred `
        -ServiceName $ServiceName `
        -VMName $VMName `
        -VMCredentialName $VMCredentialName `
        -LocalPath "C:\$PackageName" `
        -RemotePath "C:\Reply\Deployer\$PackageName" `
        -BufferSize 10240  

    $vmUri = Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -AzureOrgIdCredential $cred -ServiceName $ServiceName -VMName $VMName

    InlineScript
    {
        Invoke-command -ConnectionUri $Using:vmUri -credential $Using:vmCred -ScriptBlock { 
            add-type -assemblyName 'System.IO.Compression.FileSystem'
            [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\Reply\Deployer\$PackageName", "C:\Reply\Deployer\$PackageName")
            
            C:\Reply\Deployer\booi.exe "C:\Reply\Deployer\$PackageName\Deploy.boo"
            
			rm "C:\Reply\Deployer\$PackageName"
        }
    }          
}