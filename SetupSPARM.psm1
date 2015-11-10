<# .synopsis
        Workshop

#>


function SingleUpload()
{
    param
    (
        $fileName,
        $storageAccountName =$global:StorageAccountName, 
        $containerName = $global:StorageContainerName
    )


    $storageAccountKey = (Get-AzureStorageKey -StorageAccountName $storageAccountName).Primary
    $blobContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    write-debug "copying $fileName to $blobName"
    Set-AzureStorageBlobContent -File $filename -Container $containerName -Blob $blobName -Context $blobContext -Force
    write-debug "$fileName uploaded to $containerName!"

}

function UploadArmFilesToBlobContainer()
{
    param($subfolder="armfiles")

    Get-ChildItem $subfolder | % { SingleUpload -fileName $_.FullName }

}


function SetupARM(){
param 
(
    [Parameter(Mandatory=$true)]
    $storageAccountName,
    [Parameter(Mandatory=$false)]
    $location = "west europe",
    [Parameter(Mandatory=$false)]
    $containerName = "armsp",
    [Parameter(Mandatory=$false)]
    [switch]$DryRun

)

# validate InputParameter 
#Storage account needs to be lower Case
$storageAccountName = $storageAccountName.ToLower();

# Login in Azure Resource Manager
Login-AzureRM -SubscriptionId (Get-AzureSubscription).SubscriptionId

#Create StorageAcount
New-AzureStorageAccount -StorageAccountName $storageAccountName -Location $location

Set-AzureSubscription -CurrentStorageAccountName $storageAccountName -SubscriptionName (Get-AzureSubscription).SubscriptionName

$container = New-AzureStorageContainer -Name $containerName -Permission Container
$baseUrl = "{0}{1}" -f $container.Context.BlobEndPoint, $container.Name

$urlToSetupFile = "{0}{1}/{2}" -f $container.Context.BlobEndPoint, $container.Name, "3SRVSP.json"
UploadArmFilesToBlobContainer 


$ht = @{};
$ht.Add("baseUrl",$baseUrl);
$ht
}


function DeployArmSP()
{
    param 
    (
        [Parameter(Mandatory=$false)]
        $deployName="POCDeployment",
        [Parameter(Mandatory=$false)]
        $RGName="POCRG",
        [Parameter(Mandatory=$false)]
        $locname="westeurope", 
        [Parameter(Mandatory=$true)]
        $templateURI,
        [Parameter(Mandatory=$false)]
        $parameterObject

    )

Write-Output "You will be prompted to enter Credentials for the FarmPoint farm.... press any key to continue"
$devnull = Read-Host
New-AzureRMResourceGroup -Name $RGName -Location $locName
if ($parameterObject -eq $null)
    New-AzureRMResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateUri $templateURI
else
    New-AzureRMResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateUri $templateURI -TemplateParameterObject $parameterObject


}


Export-ModuleMember SetupARM
Export-ModuleMember DeployArmSP
