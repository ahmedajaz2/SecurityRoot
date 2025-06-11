############################################################################################
# Name: QueryActPendingTasks.ps1
# Purpose: This Script uses PowerShell and Kusto query to lookup a data storage for Service 360 and performs below functions:
# 1. Lookup Open Migration PBIs based on User selected or from the list provided.
# 2. If Open PBIs found, Check for associated S360 KPI.
# 3. If no Action pending in S360 KPI, Open Children tasks.
# 4. Close Child Tasks, if found open
# 5. Close the PBI
# Created by: Ajaz Ahmed Siddiqui
# Date: 6/24/2021
############################################################################################
#Authentication in Azure DevOps
$AzureDevOpsPAT = <<Your Visual Studio PAT>>
$DevOpsOrg = <<DevOpsOrg>>
$Project  = <<Project>>
$dir=Get-Location
$file = <<Excel Filename>>

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

function GetWorkItemPBI($item){
    $KPIFound = $null
    $WorkItemNo = $item
    $global:PBIcount+=1
    #GetUri to get optional parameters
    $GetUri=$OrgUri + $Project + "/_apis/wit/workitems/" + $WorkItemNo + "?`$expand=all&api-version=5.1"
    #Write-Host $GetUri
    $Get= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
    $Title=$Get.fields.'System.Title'
    
    
    If ($Get.fields.'System.AssignedTo'.displayName -match $global:user){
        $global:yourPBI+=1
        Write-Host "Open PBI found - $($WorkItemNo) , Checking if it's Migration PBI..."

        if ($Title -match "Migration Support"){
        Write-Host "PBI is of Migration, Checking if Identity Isolation KPI exists..."
        $Service=$Title.substring(20).Trim()
	# Use your data store/cluster tables for querying, I am using two tables from two clusters and merging them
        $kustoquery = "cluster(`"Cluster1`").database(`"Database1`").Table1
                        | where ServiceName  =~ `"$($Service)`"
                        | project ServiceName,ServiceId
                        | join (cluster(`"Cluster2`").database(`"Database2`").Table2 | project TargetId,ActionItemId, Title)
                        on `$left.ServiceId == `$right.TargetId
                        | where ActionItemId has `"73996a69-a374-5f04-1b03-a4037b589e48`"
                        | project ServiceName, TargetId , ActionItemId, Title
         
                        "


        }
  
    
        try{

        #Check if Identity Isolation KPI exists for the service through Kusto, Use the path to the downloaded Kusto Tools
        $packagesRoot = "C:\Microsoft.Azure.Kusto.Tools\Tools"  //
        dir $packagesRoot\* | Unblock-File
        $init=[System.Reflection.Assembly]::LoadFrom("$packagesRoot\Kusto.Data.dll")
        $clusterUrl = "<<Datacluster URL>>;Fed=True"  //Enter Data cluster URL here
        $databaseName = "Shared"
        $kcsb = New-Object Kusto.Data.KustoConnectionStringBuilder ($clusterUrl, $databaseName)
        $queryProvider = [Kusto.Data.Net.Client.KustoClientFactory]::CreateCslQueryProvider($kcsb)
    
        #Write-Host "Executing query: '$query' with connection string: '$($kcsb.ToString())'"
        #Execute the query
        $reader = $queryProvider.ExecuteQuery($kustoquery)
        # Do something with the result datatable, for example: print it formatted as a table, sorted by the 
        # "StartTime" column, in descending order
        if ($reader){
            $dataTable = [Kusto.Cloud.Platform.Data.ExtendedDataReader]::ToDataSet($reader).Tables[0]
            $dataView1 = New-Object System.Data.DataView($dataTable)
            $dataView =$dataview1| select-object -first 1
            $service=$dataView.ServiceName
            $Action=$dataView.ActionItemId
            $ActionTitle=$dataView1.Title
            if ($Action){
            $KPIFound = "Yes"
            Write-Host "S360 KPI found for $($service) with Action pending as - `n" 
             $ActionTitle | % { Write-Host $_ }  
            }
            else {
            $KPIFound = "No"
            Write-Host "S360 KPI Not found, proceeding with PBI Closure..."
            }
          }

        }
        catch {
        Write-Log "Exception while Searching S360 KPI for $($Service)"
        } 

    
        if ($KPIFound -eq "No")   {
        #Check if Open Child workitem exists
        Write-Host "Checking if PBI has Open Children..."
        Foreach($Child in $get.relations) {
            if ($Child.attributes.name -eq "Child"){
                
                $ChildItemNo = $Child.url.split('/')[7]
                $GetUri= $OrgUri + $Project + "/_apis/wit/workitems/" + $ChildItemNo + "?api-version=5.1"
                
                #Write-Host $GetUri
                $GetCI= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
               
                if ($GetCI.fields.'System.State' -ne 'Done')
                {
                  #Close the ticket
                  Write-Host "Found Open Child Ticket - $($ChildItemNo) with State - $($GetCI.fields.'System.State')"
                  Write-Host "Closing the Child - $($ChildItemNo)"
                  CloseWorkItem($ChildItemNo)
                 }
            }

            
        }
    Write-Host "Closing the PBI - $($WorkItemNo)"  
    CloseWorkItem($WorkItemNo)
    
    }
    }
    else{
    return;
    }
  Sleep 1
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
          {
            `"op`": `"add`",
            `"path`": `"/fields/Agile_DevEx.Duration`",
            `"value`": `"3`"
          },
          {
            `"op`": `"add`",
            `"path`": `"/fields/Microsoft.VSTS.Scheduling.CompletedWork`",
            `"value`": `"3`"
          }
          ]"
       
    $UpdateTask = Invoke-RestMethod -Uri $Updateuri -Method PATCH -Headers $AuthHeader -ContentType "application/json-patch+json" -Body $body -ErrorAction Stop
    Write-Host "Closing ticket - $($Item) SUCCESS"
    Write-Log "Closing ticket - $($Item) SUCCESS"
    }
    catch {
        Write-Host "Closing ticket - $($Item) FAILED with below Error"
        Write-Log "Closing ticket - $($Item) FAILED with below Error"
        Write-Log "Write-Host $_"
    }
    
}


#To Test Run - GetWorkItemPBI <<WorkItem number>>


#Check if Query exists
$Query= "<<QueryID>>"  //Use QueryID of the Search query used to search the work items"
$QueryUri= $OrgUri + $Project + "/_apis/wit/queries/"  + $Query + "?api-version=5.1"
#search/workitemsearchresults?api-version=6.0-preview.1
$QueryExists = Invoke-RestMethod -Uri $QueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
If ($QueryExists){
    

    $Choice=Read-Host "Do you want to use your own set of PBIs (Y/N)?"
    If ($Choice -eq 'Y' -OR $Choice -eq 'Yes'){
        Write-Host "Ensure you have a text file with all ticket numbers as InputFile.txt"
        try{
        $AllPBIs = Get-Content InputFile.txt
        }
        catch {
        Write-Host "File not found, please retry"
        Exit
        }
    }
    Else{
        #Run the Query
        $RunQueryUri= $OrgUri + $Project + "/_apis/wit/wiql/"  + $Query + "?api-version=5.1"
        #search/workitemsearchresults?api-version=6.0-preview.1
        $QueryResult=Invoke-RestMethod -Uri $RunQueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
        $AllPBIs = $QueryResult.workItems.id
    }
    $global:User=Read-Host "Enter your name (OR Anyone who is part of Migration Team)"
    #Write-Host "The Query returned below items: `n"
    $itemindex=0
    Foreach($witem in $AllPBIs){
        #Write-Host "`nFetching details of $($item)"
        GetWorkItemPBI($witem)
        $itemindex+=1
        If ($itemindex -eq $AllPBIs.Length) {
            Write-Host "All PBIs are handled"    
        }
        else{
            Write-Host "`n Moving to next PBI `n"
        }
        
     } 
     if($global:yourPBI -eq 0)
        {
            Write-Host "There were no OpenPBIs found for $($global:User)"
        }  
        

}

