param (
	[parameter(Mandatory=$false)]
    [string] 
	$Uri = 'https://apimanagement.azure-api.net/AgathAPI/UpsertDocument',
	[parameter(Mandatory=$false)]
    [string] 
	$ApiSubscriptionName = 'Agatha-Api-Subscription-Key',
	[parameter(Mandatory=$true)]
    [string] 
	$ProjectCollection,
	[parameter(Mandatory=$true)]
    [string] 
	$DocumentType,
	[parameter(Mandatory=$true)]
    [object] 
	$Document
)

$subscriptionKey = Get-AutomationVariable -Name $ApiSubscriptionName
$body = ConvertTo-Json @{ projectCollection = $ProjectCollection; documentType = $DocumentType; jsonStr = ( ConvertTo-Json $Document ) }

echo $body

Invoke-RestMethod -Uri $Uri -Method Post -Headers @{ "Ocp-Apim-Subscription-Key" = $subscriptionKey } -ContentType 'application/json' -Body $body