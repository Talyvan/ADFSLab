#Login if necessary
$AzureSub = "My Azure Subscription"try { $ctx=Get-AzureRmContext -ErrorAction Stop }
catch { Login-AzureRmAccount }
if ($ctx.SubscriptionName -ne $AzureSub) { Set-AzureRmContext -SubscriptionName $AzureSub }

#DEPLOYMENT OPTIONS
    $Branch                  = "master"

    $VNetAddrSpace2ndOctet   = "1"
    $RGName                  = "DirectFederationTest$VNetAddrSpace2ndOctet"
    $DeployRegion            = "southcentralus"
    $userName                = "DFadmin"
    $secpasswd               = “F3deratedAdm!n”
    $adDomainName            = "directfederationtest.com"
    #$clientsToDeploy         = @("10-1511","10-1607","10-1703","7","8")
    $clientsToDeploy         = @("10-1703")
    $clientImageBaseResource = "/subscriptions/e718f38a-756c-438d-9b83-14fe8dcb2e62/resourceGroups/ImageRG/providers/Microsoft.Compute/images/"
    $AdfsFarmCount           = "1";
    $AssetLocation           = "https://raw.githubusercontent.com/Azure-Samples/active-directory-lab-hybrid-adfs/$Branch/lab-hybrid-adfs/"

    $usersArray              = @(
                                @{ "FName"= "Test User 01"; "LName"= "DF"; "SAM"= "DFTestUser01" },
                                @{ "FName"= "Test User 02"; "LName"= "DF"; "SAM"= "DFTestUser02" },
                                @{ "FName"= "Test User 03"; "LName"= "DF"; "SAM"= "DFTestUser03" },
                                @{ "FName"= "Test User 04"; "LName"= "DF"; "SAM"= "DFTestUser05" }
                               )
    $defaultUserPassword     = "Deloitte@1"
    $RDPWidth                = 1680
    $RDPHeight               = 1050

#END DEPLOYMENT OPTIONS