#=======================================================================
# Instructions
# ------------
# 1- Modify the values of: 
#		$AzureSub   (Azure Subscription)
#		$userName   (Default Admin user name for each VM)
#		$secpasswd  (Default Admin password for each VM)
#		$adDomainName	(This is the the On-Prem/Local domain to be used, in this case, it is matching the Azure AD domain for ease of sync using AD Connect, otherwise, you need to create an additional suffix, change the test accounts and then syncronize)
#		$usersArray (These are all the test user accounts to be created at once, be aware that they will be created on a special OU)
#		$defaultUserPassword (self explanatory)
#		$AdfsFarmCount	(this controls the number of ADFS farms to be deplyed, on a Lab environment, this value is OK being 1)

# 2- Run the Disconnect-AzAccount to ensure you're logged into any Azure Tenant prior to run this.
#    i.e. Disconnect-AzAccount -Username 'yvhernandez@deloitte.com'

# 3- Log into the proper tenant where you want to create the VM's when prompted

# 4- AFTER the whole script finishes, it will take about 1hr, go into each VM and set the IP address as static by clicking on DNS, select Static and Save
#=======================================================================

#=======================================================================
# Run this section 1st using F8 (just these lines)

#=======================================================================

$startTime=Get-Date
Write-Host "Beginning deployment at $starttime"

#Install-Module -Name AZ -Repository PSGallery -RequiredVersion 2.2.0 -AllowClobber
Import-Module Az -ErrorAction SilentlyContinue

#Disconnect-AzAccount -Username 'yvhernandez@deloitte.com'
#Disconnect-AzAccount -Username 'yvanh@msn.com'
$version = 0

#===============================
#Login if necessary
$AzureSub = "Visual Studio Enterprise with MSDN"   #Subscrption Name

try { $ctx = Get-AzContext -ErrorAction Stop }
catch { Connect-AzAccount }
if ($ctx.SubscriptionName -ne $AzureSub) { Set-AzContext -SubscriptionName $AzureSub }
#===============================

#DEPLOYMENT OPTIONS
#    $templateToDeploy        = "FullDeploy.json"
    $templateToDeploy        = "NoClientDeploy.json"	
    # MUST be unique for all your simultaneous/co-existing deployments of this ADName in the same region
    $VNetAddrSpace2ndOctet   = "1"

    # Must be unique for simultaneous/co-existing deployments
    #"master" or "dev"
    $RGName                  = "DirectFederationTest$VNetAddrSpace2ndOctet"
    #List of available regions is 'centralus,eastasia,southeastasia,eastus,eastus2,westus,westus2,northcentralus,southcentralus,westcentralus,northeurope,westeurope,japaneast,japanwest,brazilsouth,australiasoutheast,australiaeast,westindia,southindia,centralindia,canadacentral,canadaeast,uksouth,ukwest,koreacentral,koreasouth,francecentral,southafricawest,southafricanorth'
    $DeployRegion            = "southcentralus"

    $Branch                  = "master"
    $AssetLocation           = "https://raw.githubusercontent.com/Azure-Samples/active-directory-lab-hybrid-adfs/$Branch/lab-hybrid-adfs/"
    $localAssetLocation      = ".\OneDrive - Deloitte (O365D)\LABS\active-directory-lab-hybrid-adfs-master\lab-hybrid-adfs\"

    $userName                = "ADadmin"
    $secpasswd               = “F3deratedAdm!n”
    $adDomainName            = "dfedtest.onmicrosoft.com"   #Local OnPrem AD Domain Name

    $usersArray              = @(
                                @{ "FName"= "Test User 01"; "LName"= "DF"; "SAM"= "DFTestUser01" },
                                @{ "FName"= "Test User 02"; "LName"= "DF"; "SAM"= "DFTestUser02" },
                                @{ "FName"= "Test User 03"; "LName"= "DF"; "SAM"= "DFTestUser03" },
                                @{ "FName"= "Test User 04"; "LName"= "DF"; "SAM"= "DFTestUser05" }
                               )
    $defaultUserPassword     = "Deloitte@1"

    # ClientsToDeploy, array, possible values: "7","8","10-1607","10-1511","10-1703"
    # Examples: Single Win7 VM = @("7")
    #           Two Win7, one Win10 Creators = "7","7","10-1703"
    #$clientsToDeploy         = @("10-1703")
    $RDPWidth                = 1920
    $RDPHeight               = 1080

    #Enter the full Azure ARM resource string to the location where you store your client images.
    #Your images MUST be named: OSImage_Win<version>
    #Path will be like: "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/<RG holding your images>/providers/Microsoft.Compute/images/"
    $clientImageBaseResource = "<ARM resource path to your VM Client image base>"

    # This will deploy X number of distinct ADFS farms, each with a single WAP proxy deployed in the DMZ.
    $AdfsFarmCount           = "1";

#END DEPLOYMENT OPTIONS

#Dot-sourced variable override (optional, comment out if not using)
#. "C:\Users\yvhernandez\OneDrive - Deloitte (O365D)\LABS\active-directory-lab-hybrid-adfs-master\lab-hybrid-adfs.ps1"

#ensure we're logged in
Get-AzContext -ErrorAction Stop


#deploy
$parms=@{
    "adminPassword"               = $secpasswd;
    "adminUsername"               = $userName;
    "adDomainName"                = $ADDomainName;
    "assetLocation"               = $assetLocation;
    "localAssetLocation"          = $localAssetLocation;
    "virtualNetworkAddressRange"  = "10.$VNetAddrSpace2ndOctet.0.0/16";
    #The first IP deployed in the AD subnet, for the DC
    "adIP"                        = "10.$VNetAddrSpace2ndOctet.1.4";
    #The first ADFS server deployed in the AD subnet - multiple farms will increment beyond this
    "adfsIP"                      = "10.$VNetAddrSpace2ndOctet.1.5";
    "adSubnetAddressRange"        = "10.$VNetAddrSpace2ndOctet.1.0/24";
    "dmzSubnetAddressRange"       = "10.$VNetAddrSpace2ndOctet.2.0/24";
    "cliSubnetAddressRange"       = "10.$VNetAddrSpace2ndOctet.3.0/24";
    #if multiple deployments will need to route between vNets, be sure to make this distinct between them
    "deploymentNumber"            = $VNetAddrSpace2ndOctet;
#    "clientsToDeploy"             = $clientsToDeploy;
#    "clientImageBaseResource"     = $clientImageBaseResource;
    "AdfsFarmCount"               = $AdfsFarmCount;
    "usersArray"                  = $usersArray;
    "defaultUserPassword"         = "Deloitte@1";
}

$TemplateFile = "$($localAssetLocation)$templateToDeploy"
#$TemplateFile = "$($AssetLocation)$templateToDeploy" + "?x=5"

try {
    Get-AzResourceGroup -Name $RGName -ErrorAction Stop
    Write-Host "Resource group $RGName exists, updating deployment"
}
catch {
    $RG = New-AzResourceGroup -Name $RGName -Location $DeployRegion -Tag @{ Shutdown = "true"; Startup = "false"}
    Write-Host "Created new resource group $RGName."
}
$version ++
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $parms -TemplateFile $TemplateFile -Name "adfsDeploy$version"  -Force -Verbose
#$deployment = New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $parms -TemplateUri $TemplateFile -Name "adfsDeploy$version"  -Force -Verbose

if ($deployment) {
    if (-not (Get-Command Get-FQDNForVM -ErrorAction SilentlyContinue)) {
        #load add-on functions to facilitate the RDP connectoid creation below
        $url="$($assetLocation)Scripts/Addons.ps1"
        $tempfile = "$env:TEMP\Addons.ps1"
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($url, $tempfile)
        . $tempfile
    }

    $RDPFolder = "$env:USERPROFILE\desktop\$RGName\"
    if (!(Test-Path -Path $RDPFolder)) {
        md $RDPFolder
    }
    $ADName = $ADDomainName.Split('.')[0]
    $vms = Get-AzResource -ResourceGroupName $RGName | where {($_.ResourceType -like "Microsoft.Compute/virtualMachines")}
    $pxcount=0
    if ($vms) {
        foreach ($vm in $vms) {
            $fqdn=Get-FQDNForVM -ResourceGroupName $RGName -VMName $vm.Name
            New-RDPConnectoid -ServerName $fqdn -LoginName "$($ADName)\$($userName)" -RDPName $vm.Name -OutputDirectory $RDPFolder -Width $RDPWidth -Height $RDPHeight
            if ($vm.Name.IndexOf("PX") -gt -1) {
                $pxcount++
                $WshShell = New-Object -comObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut("$($RDPFolder)ADFSTest$pxcount.lnk")
                $Shortcut.TargetPath = "https://$fqdn/adfs/ls/idpinitiatedsignon.aspx"
                $Shortcut.IconLocation = "%ProgramFiles%\Internet Explorer\iexplore.exe, 0"
                $Shortcut.Save()
            }
        }
    }

    start $RDPFolder
}

$endTime=Get-Date

Write-Host ""
Write-Host "Total Deployment time:"
New-TimeSpan -Start $startTime -End $endTime | Select Hours, Minutes, Seconds
