############################################################################################
# Name: QueryActPendingTasks.ps1
# Purpose: This Script performs below functions:
# 1. Lookup Migration Product Backlog Items (PBIs) based on User selected or from the list provided.
# 2. Update the Closure date as provided.
# Created by: v-asiddiqui (Ajaz Ahmed Siddiqui)
# Date: 9/13/2021
############################################################################################

#Authentication in Azure DevOps
$AzureDevOpsPAT = <<Your Visual Studio PAT>>
$DevOpsOrg = <<DevOpsOrg>>
$Project  = <<Project>>
$AuthHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }

$OrgUri = "https://"+$DevOpsOrg+".visualstudio.com/"
#OR Use
#$OrgUri = "https://dev.azure.com/"+$DevOpsOrg+/"

$global:PBIcount= 0
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

function GetWorkItemPBI($item, $closuredate)
{
    $WorkItemNo = $item #$item
    $global:PBIcount+=1
    #GetUri to get optional parameters
    $GetUri=$OrgUri + $Project + "/_apis/wit/workitems/" + $WorkItemNo + "?`$expand=all&api-version=5.1"
    #Write-Host $GetUri
    $Get= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
    $Title=$Get.fields.'System.Title'
    $Finishdate=$get.fields.'Microsoft.VSTS.Scheduling.FinishDate'
    Write-Log "Provided PBI is - $($WorkItemNo) with closure date - $($closuredate)"
    Write-Log "Finish date was - $finishdate "
    Write-Host "Updating the PBI - $($WorkItemNo)"
    Write-Log "Title is - $($Title)" 
    UpdateWorkItem $item $closuredate
    $Get= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
    $Finishdate=$get.fields.'Microsoft.VSTS.Scheduling.FinishDate'
    Write-Log "Finish date updated is - $finishdate "
    Write-Log "`n"
}


function UpdateWorkItem($Item, $finishdate)
{ 
    try{
    $Updateuri = $OrgUri + $Project + "/_apis/wit/workitems/" + $Item + "?api-version=5.1"
        
        $body= "[
            {
            `"op`": `"add`",
            `"path`": `"/fields/Microsoft.VSTS.Scheduling.FinishDate`",
            `"value`": `"$($finishdate)`"
          }
          ]"
       
    $UpdateTask = Invoke-RestMethod -Uri $Updateuri -Method PATCH -Headers $AuthHeader -ContentType "application/json-patch+json" -Body $body -ErrorAction Stop
    
    Write-Host "Updating ticket - $($Item) SUCCESS"
    Write-Log "Updating ticket - $($Item) SUCCESS"
    }
    catch {
        Write-Host "Updating ticket - $($Item) FAILED with Error (check logs)"
        Write-Log "Updating ticket - $($Item) FAILED with below Error"
        Write-Log "Write-Host $_"
    }
    
}



    $Choice=Read-Host "Do you want to use your own set of PBIs (Y/N)?"
    If ($Choice -eq 'Y' -OR $Choice -eq 'Yes'){
        Write-Host "Ensure you have a text file with all ticket numbers as PBIs.txt"
        try{
        $AllPBIs = Import-csv "PBIs.csv"
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
        GetWorkItemPBI $witem.TaskId $witem.ClosedDateGMT
        $itemindex+= 1
        If ($itemindex -eq $AllPBIs.Length) {
            Write-Host "All PBIs are handled"    
        }
        else{
            Write-Host "`n Moving to next PBI `n"
        }
        
     } 
     
        



