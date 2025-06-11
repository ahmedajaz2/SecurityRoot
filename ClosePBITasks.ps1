############################################################################################
# Name: ClosePBITasks.ps1
# Purpose: This Script performs below functions:
# 1. Lookup Migration PBIs based on the list provided.
# 2. Close the PBI
# Created by: Ajaz Ahmed Siddiqui
# Date: 9/13/2021
############################################################################################

#Authentication in Azure DevOps
$AzureDevOpsPAT = <<Your Visual Studio PAT>>
$DevOpsOrg = <<DevOpsOrg>>
$Project  = <<Project>>
$dir=Get-Location

$AuthHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }

$OrgUri = "https://"+$DevOpsOrg+".visualstudio.com/"
#OR Use
#$OrgUri = "https://dev.azure.com/"+$DevOpsOrg+/"

$global:PBIcount= 0
$global:yourPBI = 0
$global:User = $null
$Logs = "Logs.txt"
if (Test-Path -Path $Logs -PathType Leaf) {
     Remove-Item $Logs
     New-Item -ItemType File -Path $Logs -Force -ErrorAction Stop
    }
    else{
        New-Item -ItemType File -Path $Logs -Force -ErrorAction Stop
    }
Function Write-Log
{
   Param ([string]$logstring)
   Add-content $Logs -value $logstring
}

function CloseWorkItem($Item)
{ 
    try{
    $Updateuri = $OrgUri + $Project + "/_apis/wit/workitems/" + $Item + "?api-version=5.1"
        
        $body= "[
            {
            `"op`": `"add`",
            `"path`": `"/fields/System.State`",
            `"value`": `"Done`"
          },
          ]"
       
    $UpdateTask = Invoke-RestMethod -Uri $Updateuri -Method PATCH -Headers $AuthHeader -ContentType "application/json-patch+json" -Body $body -ErrorAction Stop
    
   
    Write-Host "Closing ticket - $($Item) SUCCESS"
    Write-Log "Closing ticket - $($Item) SUCCESS"
    }
    catch {
        Write-Host "Closing ticket - $($Item) FAILED with Error (check logs)"
        Write-Log "Closing ticket - $($Item) FAILED with below Error"
        Write-Log "Write-Host $_"
    }
    
}

    $Choice=Read-Host "Do you want to use your own set of PBIs (Y/N)?"
    If ($Choice -eq 'Y' -OR $Choice -eq 'Yes'){
        Write-Host "Ensure you have a text file with all ticket numbers as PBIs.txt"
        try{
        $AllPBIs = get-content "PBIs.txt"
        }
        catch {
        Write-Host "File not found, please retry"
        Exit
        }
    }
    Else{
        Write-Host "File not found, please retry"
        Exit
    }
    $itemindex= 0
    Foreach($witem in $AllPBIs){
        #Write-Host "`nFetching details of $($item)"
        CloseWorkitem $witem
        $itemindex+= 1
        If ($itemindex -eq $AllPBIs.Length) {
            Write-Host "All PBIs are handled"    
        }
        else{
            Write-Host "`n Moving to next PBI `n"
        }
        
     }  
        



