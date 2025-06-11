############################################################################################
# Name: QueryNewTasks.ps1
# Purpose: This Script uses PowerShell and Kusto query to performs below functions:
# 1. Lookup Migration tickets.
# 2. Validate the Subscription ID, and if it’s PROD/Non-Prod.
# 3. Lookup the Service name using validated Sub ID
# 4. Export the report in a CSV file
# Created by: Ajaz Ahmed Siddiqui
# Date: 6/21/2021
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

$global:Parent= $null
$global:Tenant= $null

function GetWorkItem($item){
    $WorkItemNo = $item
    $GetUri= $OrgUri + $Project + "/_apis/wit/workitems/" + $WorkItemNo + "?api-version=5.1"
    #echo $GetUri
    $Get= Invoke-RestMethod -Uri $GetUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
    $Body=$Get.fields.'System.Description'
    $newBody =$Body -replace '<[^>]+>',''
    $pattern= "Migration(.*?)Target"
    $Sub=[regex]::match($newBody, $pattern).Groups[1].Value
    $pattern2= "alias(.*?)Secondary"
    $ReqID=[regex]::match($newBody, $pattern2).Groups[1].Value
    $pattern3= "name(.*?)Requestor"
    $Req=[regex]::match($newBody, $pattern3).Groups[1].Value
    $pattern3= "date(.*?)Would"
    $Impl=[regex]::match($newBody, $pattern3).Groups[1].Value
    $pattern4="Target(.*?)Subscription"
    $Tenant=[regex]::match($newBody, $pattern4).Groups[1].Value
    $Global:Tenant=$Tenant
    If ($sub -match '\w{8}-\w{4}-\w{4}-\w{4}-\w{12}') {
        $vsub=$matches[0]
        $kustoquery = "cluster(`"Cluster1`").database(`"Db1`").Table1
                    | where SubscriptionId contains `"$($vsub )`"
                    | project ServiceName, ServiceId, Environment
                    | join (cluster(`"Cluster1`").database(`"Db1`").Table2
                    | project ServiceId, OrganizationName)
                    on `$left.ServiceId == `$right.ServiceId
                    | project ServiceName, Environment, OrganizationName
                    "
        }
        else {
        $vsub="Not a valid sub ID"
        }
        <#else {
        $kustoquery="cluster(`"Cluster1`").database(`"Db1`").Table2 `
                | where SubscriptionName contains `"$($vsub )`" `
                | project ServiceName, Environment
                "
        }#>
    
    try{
    #Fetch ServiceName from the Subscription through Kusto
    $packagesRoot = "C:\Microsoft.Azure.Kusto.Tools\Tools"
    dir $packagesRoot\* | Unblock-File
    $init=[System.Reflection.Assembly]::LoadFrom("$packagesRoot\Kusto.Data.dll")
    $clusterUrl = "https://lens.kusto.windows.net;Fed=True"
    $databaseName = "Shared"
    $kcsb = New-Object Kusto.Data.KustoConnectionStringBuilder ($clusterUrl, $databaseName)
    $queryProvider = [Kusto.Data.Net.Client.KustoClientFactory]::CreateCslQueryProvider($kcsb)
    
    #Write-Host "Executing query: '$query' with connection string: '$($kcsb.ToString())'"
    #Execute the query
    $reader = $queryProvider.ExecuteQuery($kustoquery)
    # Do something with the result datatable, for example: print it formatted as a table, sorted by the 
    # "StartTime" column, in descending order
    $dataTable = [Kusto.Cloud.Platform.Data.ExtendedDataReader]::ToDataSet($reader).Tables[0]
    $dataView = New-Object System.Data.DataView($dataTable)
    $dataView =$dataview | select-object -first 1
    $service=$dataView.ServiceName
    $Env=$dataView.Environment
    $Org=$dataView.OrganizationName
    If ($Org -eq 'Digital Transformation Platform'){
        $Bag = "Yes"
        }
        else{
        $Bag = "No"
        }

    if ($service) {
        write-host $service
        }
    else{
        $service="Service not available"
        $AssignTo="NA"
        $Env="NA"
        }
    }
    catch {
    $service="NA"
    }   #Do nothing
    $obj = @{
        'Task'=($Get.ID).ToString();
        'Requestor'=$Req;
        'Alias'=$ReqID;
        'Service'=$service;
        'Is BAG?'=$Bag;
        'SubscriptionProvided'=$Sub;
        'ValidSubscription'=$vsub;
        'Env'=$Env;
        'Impl.Date'=$Impl
        'Target'=$Global:Tenant
        }
    New-Object psobject -Property $Obj 
}

#Check if Query exists
$Query= "<<QueryID>>"  //Use QueryID of the Search query used to search the work items"
$QueryUri= $OrgUri + $Project + "/_apis/wit/queries/"  + $Query + "?api-version=5.1"
#search/workitemsearchresults?api-version=6.0-preview.1
$QueryExists=Invoke-RestMethod -Uri $QueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"
If ($QueryExists){
    #Run the Query
    $RunQueryUri= $OrgUri + $Project + "/_apis/wit/wiql/"  + $Query + "?api-version=5.1"
    #search/workitemsearchresults?api-version=6.0-preview.1
    $QueryResult=Invoke-RestMethod -Uri $RunQueryUri -Method GET -Headers $AuthHeader -ContentType "application/json-patch+json"

    #Echo "The Query returned below items: `n"
    $report = New-Object psobject
    $report = Foreach($item in $QueryResult.workItems.id){
        #Echo "`nFetching details of $($item)"
        GetWorkItem($item)
        }
        if($report){        
        
        $report | Select-Object -Property Task, Impl.Date, Requestor,Alias,Target, ValidSubscription, Service,'Is BAG?',  Env,SubscriptionProvided | Sort-Object -Property Task| Export-csv report.csv
        #pause
        }
        else {
        "No tickets found" | Out-GridView -Title "New Migration Requests" -OutputMode Single 
        #pause
        }
        
}

