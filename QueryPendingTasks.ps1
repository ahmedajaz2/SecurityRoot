############################################################################################
# Name: QueryActPendingTasks.ps1
# Purpose: This Script performs below functions:
# 1. Lookup Open Migration PBIs based on User selected or from the list provided, file should be an excel document .
# 2. If Open PBIs found, Check for associated S360 KPI.
# 3. If no Action pending in S360 KPI
# 4. Extract the report
# Created by: Ajaz Ahmed Siddiqui
# Date: 6/25/2021
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


if (Test-Path -Path $file -PathType Leaf) {
     Remove-Item $file -Force
    }

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
    $ActionItems = $null
    $ChildTickets = $null
    $WorkItemNo = $item
    #GetUri to get optional parameters
    $GetUri=$OrgUri + $Project + "/_apis/wit/workitems/" + $WorkItemNo + "?`$expand=all&api-version=5.1"
    #Write-Host $GetUri
    $Get= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
    $Title=$Get.fields.'System.Title'
    $AssignedTo=$Get.fields.'System.AssignedTo'.displayName
       
    #Write-Host "Open PBI found - $($WorkItemNo) , Checking if it's Migration PBI..."
    # Search using the keyword from the Work item title, I am using 'Migration Support'
    if ($Title -match "Migration Support"){
        Write-Host "$($WorkItemNo) - is of Migration, Checking if Identity Isolation KPI exists..."
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

        #Check if Identity Isolation KPI exists for the service through Kusto
        $packagesRoot = "C:\Microsoft.Azure.Kusto.Tools\Tools"
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
                $ActionTitle | % { $ActionItems += $_ + "`n" }  
                Write-Host "KPI Found, No action"
            }
            else {

            $KPIFound = "No"
            #Check if Open Child workitem exists
            Write-Host "IdIso KPI not found for $($WorkItemNo) , Checking if PBI has Open Children..."
            $found = 'N'
            
            Foreach($Child in $get.relations) {
                if ($Child.attributes.name -eq "Child"){
                
                    $ChildItemNo = $Child.url.split('/')[7]
                    $GetUri= $OrgUri + $Project + "/_apis/wit/workitems/" + $ChildItemNo + "?api-version=5.1"
                    
                    #Write-Host $GetUri
                    $GetCI= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
               
                    if ($GetCI.fields.'System.State' -ne 'Done' -AND $GetCI.fields.'System.State' -ne 'Removed')
                    {
                      #delimit the Child items
                      $I=$ChildItemNo + " , "
                      $ChildTickets += $I
                      Write-Host "Found Open Child Ticket - $($ChildItemNo) with State - $($GetCI.fields.'System.State')"
                      $found = 'Y'
                     }
                     
                }
                            
              }
            if ($found -eq 'N')
            {
            Write-Host "No Open Child found"
            }
            }
          }
          
          

        }
        catch {
        Write-Log "Exception while Searching S360 KPI for $($Service) : $_"
        return;
        } 

   $obj = @{
        'PBI'=$WorkItemNo.ToString();
        'KPI Found'=$KPIFound;
        'ActionItems'=$ActionItems;
        'Open Child tickets (if no KPI)'=$ChildTickets;
        'AssignedTo'=$AssignedTo;
        'Title'= $Title
        }
        New-Object psobject -Property $Obj 
  
}


#To Test - Run- GetWorkItemPBI <<WorkItem number>>



#Check if Query exists
$Query= "<<QueryID>>"  //Use QueryID of the Search query used to search the work items"
$QueryUri= $OrgUri + $Project + "/_apis/wit/queries/"  + $Query + "?api-version=5.1"
#search/workitemsearchresults?api-version=6.0-preview.1
$QueryExists = Invoke-RestMethod -Uri $QueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
If ($QueryExists){
    
    $Choice = 'N'
    #$Choice=Read-Host "Do you want to use your own set of PBIs (Y/N)? Ensure you have a text file with all ticket numbers as InputFile.txt"
    
    If ($Choice -eq 'Y' -OR $Choice -eq 'Yes'){
        try {
        $AllPBIs = Get-Content InputFile.txt 

        }
        catch {
        Write-Host "InputFile.txt File not found, please retry"
        Exit;
        }
    }
    Else{
        #Run the Query
        $RunQueryUri= $OrgUri + $Project + "/_apis/wit/wiql/"  + $Query + "?api-version=5.1"
        #search/workitemsearchresults?api-version=6.0-preview.1
        $QueryResult=Invoke-RestMethod -Uri $RunQueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
        $AllPBIs = $QueryResult.workItems.id
    }
    #Write-Host "The Query returned below items: `n"
    $report = New-Object psobject
    $report = Foreach($witem in $AllPBIs){
        #Write-Host "`nFetching details of $($item)"
        GetWorkItemPBI($witem)
        $itemindex= $QueryResult.workItems.id.indexof($witem) + 1
        If ($itemindex -eq $AllPBIs.Length) {
            Write-Host "All PBIs are handled"    
        }
                
     } 
     if ($report) {
     
     $dir=Get-Location
     $file = "$dir\AllOpenPBIs.xlsx"
     if (Test-Path -Path $file -PathType Leaf) {
        Remove-Item $file -Force
     }
     $report | Select-Object -Property PBI,AssignedTo,'KPI Found','ActionItems','Open Child tickets (if no KPI)', Title | Sort-Object -Property PBI | Export-csv "$dir\AllOpenPBIs.csv" -NoTypeInformation
     #$report | Select-Object -Property PBI,AssignedTo,'KPI Found','ActionItems','Open Child tickets (if no KPI)', Title | Sort-Object -Property PBI | Out-GridView -Title "All Open PBIs" -OutputMode Single 
     
     $xl = new-object -comobject excel.application
     $xl.visible = $true
     $Workbook = $xl.workbooks.open(“$dir\AllOpenPBIs.csv”)
     $Workbook.SaveAs(“$dir\AllOpenPBIs.xlsx”,51)
     $Workbook.Saved = $True
     $xl.Quit()
     }
     else {
        "No PBIs found" | Out-GridView -Title "All Open PBIs" -OutputMode Single 
        
        }
       

}

