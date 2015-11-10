<# .synopsis
        Workshop

    .license
	Copyright (c) 2015 octonion.de
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:


The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.



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
