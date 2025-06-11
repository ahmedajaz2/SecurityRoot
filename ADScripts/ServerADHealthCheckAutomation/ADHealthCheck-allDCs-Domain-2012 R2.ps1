############################################################################
#       Author: Ajaz Ahmed
#       Reviewer:    
#       Date: 12/12/2017
#       Status: Ping,Netlogon,NTDS,DNS,DCdiag Test(Replication,Services)
#       Description: Active Directory Health Status
#############################################################################
###########################Define Variables##################################

$Shellpath=(Get-Item -Path ".\" -Verbose).FullName
$reportpath = $Shellpath + "\ADReport.htm" 

if((test-path $reportpath) -like $false)
{
new-item $reportpath -type file
}

$timeout = "60"
###############################HTMl Report Content############################
$report = $reportpath

Clear-Content $report 
Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>AD Status Report</title>' 
add-content $report '<STYLE TYPE="text/css">' 
add-content $report  "<!--" 
add-content $report  "td {" 
add-content $report  "font-family: Tahoma;" 
add-content $report  "font-size: 11px;" 
add-content $report  "border-top: 1px solid #999999;" 
add-content $report  "border-right: 1px solid #999999;" 
add-content $report  "border-bottom: 1px solid #999999;" 
add-content $report  "border-left: 1px solid #999999;" 
add-content $report  "padding-top: 0px;" 
add-content $report  "padding-right: 0px;" 
add-content $report  "padding-bottom: 0px;" 
add-content $report  "padding-left: 0px;" 
add-content $report  "}" 
add-content $report  "body {" 
add-content $report  "margin-left: 5px;" 
add-content $report  "margin-top: 5px;" 
add-content $report  "margin-right: 0px;" 
add-content $report  "margin-bottom: 10px;" 
add-content $report  "" 
add-content $report  "table {"
add-content $report  "table-layout:fixed;" 
add-content $report  "border: thin solid #000000;" 
add-content $report  "}" 
add-content $report  "-->" 
add-content $report  "</style>" 
Add-Content $report "</head>" 
Add-Content $report "<body>" 


add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='8' height='25' align='center'>" 
add-content $report  "<font face='Century Gothic' color='#003399' size='4'><strong>Active Directory Health Check</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width= '100%'>" 
Add-Content $report  "<tr bgcolor='CornflowerBlue'>" 
Add-Content $report  "<td width= '20%' align='center'><B>Identity</B></td>" 
Add-Content $report  "<td width= '10%' align='center'><B>GlobalCatalog</B></td>" 
Add-Content $report  "<td width= '10%' align='center'><B>PingStatus</B></td>" 
Add-Content $report  "<td width= '10%' align='center'><B>NetlogonService</B></td>"
Add-Content $report  "<td width= '10%' align='center'><B>DNSServiceStatus</B></td>" 
Add-Content $report  "<td width= '10%' align='center'><B>ReplicationTest</B></td>"
Add-Content $report  "<td width= '10%' align='center'><B>ServicesTest</B></td>"
Add-Content $report  "<td width= '20%' align='center'><B>TimeSource</B></td>"

Add-Content $report "</tr>" 

#####################################Get ALL DC Servers#################################
#$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()

#$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}  
#$localdomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
#$DCServers = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() |ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name} 

$Domain = (get-addomain | select DNSroot).DNSroot
$DCServers =((Get-ADForest).Domains | %{ if ($_ -like $Domain) {Get-ADDomainController -Filter * -Server $_ | select Hostname }}).Hostname
$GCatalogs = ((Get-ADDomainController -Filter {IsGlobalCatalog -eq $true})| select Hostname).Hostname
$GClength=$GCatalogs.count

foreach ($DC in $DCServers){
$Identity = $DC
                Add-Content $report "<tr>"
if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) {
Write-Host $DC `t $DC `t Ping Success -ForegroundColor Green

                                Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Identity</B></td>" 
                                ################GC Test#################
                                                                
                                $length = 0
                                foreach ($GC in $GCatalogs){
                                                if ($DC -eq $GC)
                                                {
                                                                Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>YES</B></td>"
                                                                Write-Host `t Calculating Global Catalog on $DC passed : YES -ForegroundColor Green
                break
                                                } 
                                                else { $length++ }
                                }
                                if ( $length -eq $GClength)           
                                {
                                                Add-Content $report "<td bgcolor= 'Yellow' align=center><B>NO</B></td>"
            Write-Host `t Calculating Global Catalog on $DC passed : NO -ForegroundColor Green
                                }
                                
                                ################Ping Test#################
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>Success</B></td>" 

                ##############Netlogon Service Status################
                                        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "Netlogon" -ErrorAction SilentlyContinue} -ArgumentList $DC
                wait-job $serviceStatus -timeout $timeout
                if($serviceStatus.state -like "Running")
                {
                 Write-Host $DC `t Netlogon Service TimeOut -ForegroundColor Yellow
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>NetlogonTimeout</B></td>"
                 stop-job $serviceStatus
                }
                else
                {
                $serviceStatus1 = Receive-job $serviceStatus
                 if ($serviceStatus1.status -eq "Running") {
                                  Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green 
                  $svcName = $serviceStatus1.name 
                  $svcState = $serviceStatus1.status          
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>" 
                  }
                 else 
                  { 
                                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red 
                 $svcName = $serviceStatus1.name 
                 $svcState = $serviceStatus1.status          
                 Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
                  } 
                }
               
                #####################################################
                ##############DNS Service Status#####################
                                        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "DNS" -ErrorAction SilentlyContinue} -ArgumentList $DC
                wait-job $serviceStatus -timeout $timeout
                if($serviceStatus.state -like "Running")
                {
                 Write-Host $DC `t DNS Server Service TimeOut -ForegroundColor Yellow
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>DNSTimeout</B></td>"
                 stop-job $serviceStatus
                }
                else
                {
                $serviceStatus1 = Receive-job $serviceStatus
                 if ($serviceStatus1.status -eq "Running") {
                                       Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green 
                  $svcName = $serviceStatus1.name 
                  $svcState = $serviceStatus1.status          
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>" 
                  }
                 else 
                  { 
                                 Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red 
                 $svcName = $serviceStatus1.name 
                 $svcState = $serviceStatus1.status          
                 Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
                  } 
                }
               
               #########################################################
               ####################Replications status##################
               add-type -AssemblyName microsoft.visualbasic 
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:Replications /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Replications Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>ReplicationsTimeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test Replications"))
                  {
                  Write-Host $DC `t Replications Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>ReplicationsPassed</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Replications Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>ReplicationsFail</B></td>"
                  }
                }
               ########################################################
                           ####################Services status#####################
               add-type -AssemblyName microsoft.visualbasic 
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:Services /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Services Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>ServicesTimeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test Services"))
                  {
                  Write-Host $DC `t Services Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>ServicesPassed</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Services Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>ServicesFail</B></td>"
                  }
                }

                   ####################Time Source status##################

                      $TimeServer = w32tm /query /computer:$DC /source 
 
               $time = start-job -scriptblock {w32tm /query /computer:$($args[0]) /source } -ArgumentList $DC
               wait-job $time -timeout $timeout
               if($time.state -like "Running")
               {
               Write-Host $DC `t Timesource Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Red' align=center><B>TimeSourceFailing</B></td>"
               stop-job $time
               }
               else
               {
                                         Write-Host $DC `t Timesource Test passed -ForegroundColor Green
                 Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$TimeServer</B></td>"
               }
               
               ########################################################
                
} 
else
              {
Write-Host $DC `t $DC `t Ping Fail -ForegroundColor Red
                                Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Identity</B></td>" 
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
} 
Add-Content $report "</tr>"        
       
} 


Add-content $report  "</table> <br> <br>"


############################################ FSMO Role Check###########################
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='Century Gothic' color='#003399' size='4'><strong>FSMO Role Check</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"
add-content $report  "</table>" 
 
add-content $report  "<table width= '100%'>"
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='15' align='center'>" 
add-content $report  "<font face='Calibri' color='#003399' size='3'><strong>Forest-wide Roles</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"
add-content $report  "</table>"
add-content $report  "<table width= '100%'>" 
Add-Content $report  "<tr bgcolor='CornflowerBlue'>" 
Add-Content $report  "<td width= '20%' align='center'><B>Forest Name</B></td>" 
Add-Content $report  "<td width= '40%' align='center'><B>Domain Naming Master</B></td>" 
Add-Content $report  "<td width= '40%' align='center'><B>Schema Master</B></td>"
Add-Content $report "</tr>" 

$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name} 

Add-content $report  "<tr>"
$Forestname = $getForest.name
Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$Forestname</B></td>"

$Forest = Get-ADForest
$DNMaster = $Forest.DomainNamingMaster
if ( Test-Connection -ComputerName $DNMaster -Count 1 -ErrorAction SilentlyContinue ) {
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$DNMaster</B></td>" 
    Write-Host `t Calculating FSMO role - DomainNamingMaster passed -ForegroundColor Green
} else     { Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$DNMaster</B></td>" 
        Write-Host `t Calculating FSMO role - DomainNamingMaster failed -ForegroundColor Red
        }

$SchemaMaster = $Forest.SchemaMaster
if ( Test-Connection -ComputerName $SchemaMaster -Count 1 -ErrorAction SilentlyContinue ) {
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$SchemaMaster</B></td>"
    Write-Host `t Calculating FSMO role - SchemaMaster passed -ForegroundColor Green 
} else     { 
        Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$SchemaMaster</B></td>"
        Write-Host `t Calculating FSMO role - SchemaMaster failed -ForegroundColor Red
        }


add-content $report  "</tr>" 
Add-content $report  "</table>"

add-content $report  "<table width= '100%'>"
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='15' align='center'>" 
add-content $report  "<font face='Calibri' color='#003399' size='3'><strong>Domain-wide Roles</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"
Add-content $report  "</table>"
add-content $report  "<table width= '100%'>" 
Add-Content $report  "<tr bgcolor='CornflowerBlue'>" 
Add-Content $report  "<td width= '20%' align='center'><B>Domain Name</B></td>" 
Add-Content $report  "<td width= '26.66%' align='center'><B>Infrastructure Master</B></td>" 
Add-Content $report  "<td width= '26.66%' align='center'><B>RID Master</B></td>"
Add-Content $report  "<td width= '26.66%' align='center'><B>PDC Emulator</B></td>"
Add-content $report  "</tr>" 

                
                $ADDomain=Get-ADDomain
                $IMaster=$ADDomain.InfrastructureMaster
                $RIDMaster=$ADDomain.RIDMaster
                $PDCMaster=$ADDomain.PDCEmulator
                
                Add-Content $report "<tr>"
                Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$Domain</B></td>"
                if ( Test-Connection -ComputerName $IMaster -Count 1 -ErrorAction SilentlyContinue ) {
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$IMaster</B></td>" 
    Write-Host `t Calculating FSMO role - InfrastructureMaster passed -ForegroundColor Green
                } else     { 
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$IMaster</B></td>"
            Write-Host `t Calculating FSMO role - InfrastructureMaster failed -ForegroundColor Red
            }

                if ( Test-Connection -ComputerName $RIDMaster -Count 1 -ErrorAction SilentlyContinue ) {
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$RIDMaster</B></td>" 
    Write-Host `t Calculating FSMO role - RIDMaster passed -ForegroundColor Green
                } else     { 
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$RIDMaster</B></td>"
            Write-Host `t Calculating FSMO role - RIDMaster failed -ForegroundColor Red
            }

                if ( Test-Connection -ComputerName $PDCMaster -Count 1 -ErrorAction SilentlyContinue ) {
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$PDCMaster</B></td>" 
    Write-Host `t Calculating FSMO role - PDCMaster passed -ForegroundColor Green
                } else     { 
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$PDCMaster</B></td>" 
            Write-Host `t Calculating FSMO role - PDCMaster failed -ForegroundColor Red
            }

                Add-Content $report "</tr>"
                



Add-content $report  "</table> <br> <br>"


############################################Server Health Check###########################
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='Century Gothic' color='#003399' size='4'><strong>ADServers Health Check</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width= '100%'>" 
Add-Content $report  "<tr bgcolor='CornflowerBlue'>" 
Add-Content $report  "<td width= '20%' align='center'><B>Identity</B></td>" 
Add-Content $report  "<td width= '20%' align='center'><B>Total Disk Space (GB)</B></td>" 
Add-Content $report  "<td width= '20%' align='center'><B>Disk Space Available (GB)</B></td>"
Add-Content $report  "<td width= '10%' align='center'><B>RAM usage (%)</B></td>"
Add-Content $report  "<td width= '10%' align='center'><B>Processor usage (%)</B></td>"
Add-Content $report  "<td width= '20%' align='center'><B>Last Boot Time</B></td>"

Add-Content $report "</tr>" 

$ServerList = $DCServers =((Get-ADForest).Domains | %{ if ($_ -like "SMF.com") {Get-ADDomainController -Filter * -Server $_ | select Hostname }}).Hostname
foreach ($Server in $ServerList)
{
                
        Add-Content $report "<tr>"
                Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Server</B></td>"

                ########################Diskspace Status################
                
                

                $diskC = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace
                
                $freeC = [math]::round($diskC.freespace / 1gb -as [float],2)
                
                $totalC= [math]::round($diskC.size / 1gb -as [float],2)
                

                
                $diskD = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='D:'" | Select-Object Size,FreeSpace
                
                $freeD = [math]::round($diskD.freespace / 1gb -as [float],2)
                
                $totalD= [math]::round($diskD.size / 1gb -as [float],2)
                


                $diskE = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='E:'" | Select-Object Size,FreeSpace
                
                $freeE = [math]::round($diskE.freespace / 1gb -as [float],2)
                
                $totalE= [math]::round($diskE.size / 1gb -as [float],2)
                


                $diskF = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='F:'" | Select-Object Size,FreeSpace
                
                $freeF = [math]::round($diskF.freespace / 1gb -as [float],2)
                
                $totalF= [math]::round($diskF.size / 1gb -as [float],2)
                


                if ($totalD -eq 0 -and $totalE -eq 0 -and $totalF -eq 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC</B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC</B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC </B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC</B></td>"
                                }
                }
    }

                if ($totalD -eq 0 -and $totalE -ne 0 -and $totalF -ne 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; E:$totalE &nbsp;&nbsp;&nbsp;&nbsp; F:$totalF</B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp&nbsp;&nbsp;&nbsp; E:$freeE &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                }
    }
                if ($totalE -eq 0 -and $totalD -ne 0 -and $totalF -ne 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; D:$totalD &nbsp;&nbsp;&nbsp;&nbsp; F:$totalF</B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left><B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                }}

                if ($totalE -eq 0 -and $totalD -ne 0 -and $totalF -eq 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; D:$totalD </B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD </B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD </B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD </B></td>"
                                }
                }}
                
                if ($totalF -eq 0 -and $totalE -ne 0 -and $totalD -ne 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalD &nbsp;&nbsp;&nbsp;&nbsp; E:$totalE </B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                                }
                }}

    if ($totalF -ne 0 -and $totalE -eq 0 -and $totalD -eq 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; E:$totalF </B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeF </B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeF </B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeF </B></td>"
                                }
                }}

    if ($totalE -ne 0 -and $totalF -eq 0 -and $totalD -eq 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; E:$totalE </B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Yellow' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Red' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE </B></td>"
                                }
                }}
    
    if ($totalE -ne 0 -and $totalF -ne 0 -and $totalD -ne 0){
                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$totalC &nbsp;&nbsp;&nbsp;&nbsp; E:$totalD &nbsp;&nbsp;&nbsp;&nbsp; E:$totalE &nbsp;&nbsp;&nbsp;&nbsp; E:$totalF </B></td>"
        if ($freeC -ge 5)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC  &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE  &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                }
                else
                {
                                if ($freeC -gt 1)
                                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC  &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE  &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                                else
                                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=left>  <B>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C:$freeC  &nbsp;&nbsp;&nbsp;&nbsp; D:$freeD &nbsp;&nbsp;&nbsp;&nbsp; E:$freeE  &nbsp;&nbsp;&nbsp;&nbsp; F:$freeF</B></td>"
                                }
                }}

    $freeC = 0
    $freeD = 0
    $freeE = 0
    $freeF = 0

                Write-Host `t Calculating Diskspace on $Server passed -ForegroundColor Green
                ######################## RAM and Processor usage Status################

                                
                $OperatingSystem = Get-WmiObject win32_OperatingSystem -computername $server
                # Lets grab the free memory
                $FreeMemory = $OperatingSystem.FreePhysicalMemory
                # Lets grab the total memory
                $TotalMemory = $OperatingSystem.TotalVisibleMemorySize
                # Lets do some math for percent
                $MemoryUsed = 100 - ($FreeMemory/ $TotalMemory) * 100
                $PercentMemoryUsed = "{0:N2}" -f $MemoryUsed
                $RAMpercent = "$PercentMemoryUsed" + " %"

                if ( $MemoryUsed -lt 80 )
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$RAMpercent</B></td>"
                }
                else
                {
                                if ( $PercentMemoryUsed -ge 80 -and $PercentMemoryUsed -lt 95 )
                                {
                                                Add-Content $report "<td bgcolor= 'Yellow' align=center>  <B>$RAMpercent</B></td>"
                                }
                                else
                                {
                                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$RAMpercent</B></td>"
                                }
                }

                $PercentMemoryUsed = 0

                Write-Host `t Calculating RAM usage on $Server passed -ForegroundColor Green

                $ComputerCpuAvg = Get-WmiObject -ComputerName $server win32_processor | Measure-Object -property LoadPercentage -Average | Select -expand Average
                $ComputerCpu = "{0:N2}" -f $ComputerCpuAvg
                $Percpu = "$ComputerCpu" + " %"

                if ($ComputerCpuAvg -lt 80)
                {
                                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$Percpu</B></td>"
                }
                else
                {
                                if ($ComputerCpuAvg -ge 95)
                                {
                                                Add-Content $report "<td bgcolor= 'Red' align=center>  <B>$Percpu</B></td>"
                                }
                                else
                                {
                                                Add-Content $report "<td bgcolor= 'Yellow' align=center>  <B>$Percpu</B></td>"
                                }
                }

                $ComputerCpu = 0
                Write-Host `t Calculating CPU usage on $Server passed -ForegroundColor Green

                ######################## Last Boot Time####################
                $LastBoot = [System.Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem -Computername $server | Select -Exp LastBootUpTime))
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>$LastBoot</B></td>"

                Add-Content $report "</tr>"
}

Add-content $report  "</table>" 

Add-Content $report "</body>" 
Add-Content $report "</html>" 


$HealthCheckfile = $Shellpath + "\HealthCheck-dcdiag+repadmin.zip" 

if((test-path $HealthCheckfile) -like $false)
{
new-item $HealthCheckfile -type file
}
del $HealthCheckfile

##########################################END###########################################

########################################################################################
