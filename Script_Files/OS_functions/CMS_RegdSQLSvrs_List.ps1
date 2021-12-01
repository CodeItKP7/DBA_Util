﻿cls;
set-location -Path "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions";
#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
<#
$cmserver = "RWSQLMGMTH202\MAPS"
 
$collection = @(); $newcollection = @()
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $cmserver
$sqlconnection = $server.ConnectionContext.SqlConnectionObject
 
try { $cmstore = new-object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($sqlconnection)}
catch { throw "Cannot access Central Management Server" }
 
Function Parse-ServerGroup($serverGroup,$collection) {
 
 foreach ($instance in $serverGroup.RegisteredServers) {
 $urn = $serverGroup.urn
 $group = $serverGroup.name
 $fullgroupname = $null
 
 for ($i = 0; $i -lt $urn.XPathExpression.Length; $i++) {
 $groupname = $urn.XPathExpression[$i].GetAttributeFromFilter("Name")
 if ($groupname -eq "DatabaseEngineServerGroup") { $groupname = $null }
 if ($i -ne 0 -and $groupname -ne "DatabaseEngineServerGroup" -and $groupname.length -gt 0 ) {
 $fullgroupname += "$groupname\"
 }
 }
 
 if ($fullgroupname.length -gt 0) { $fullgroupname = $fullgroupname.TrimEnd("\") }
 $object = New-Object PSObject -Property @{
            InstanceName = $instance.servername
            GroupName = $groupname
            FullGroupPath = $fullgroupname
            MachineName = $instance.servername.split("\,")[0].TrimEnd("") ; #split("\")[0];$_ -eq "\" -or $_ -eq ","
        }
        $collection += $object
    }
 
    foreach($group in $serverGroup.ServerGroups)
    {
      $newobject = (Parse-ServerGroup -serverGroup $group -collection $newcollection)
      $collection += $newobject     
    }
    return $collection
}
 
foreach ($serverGroup in $cmstore.DatabaseEngineServerGroup) {  $servers = Parse-ServerGroup -serverGroup $serverGroup -collection $newcollection }
 
$servers | ft -AutoSize | out-file "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions\CMS_SQLList.txt";

# Store all CMS SQL instance details in a CMS table in RWSQLMGMTH202 DBA database.
$vSvrDest = "RWSQLMGMTH202"; $vDBnameDest = "DBA"; 
$machfile = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions\MachineNames.txt";
$instfile = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions\InstanceNames.txt";
invoke-sqlcmd -ServerInstance $vSvrDest -Database $vDBnameDest -Query "Truncate Table DBA.DBO.CMS_SQLServers;" -AbortOnError;
Write-SqlTableData -ServerInstance $vSvrDest -DatabaseName $vDBnameDest -SchemaName dbo -TableName CMS_SQLServers -InputData $servers;

invoke-sqlcmd -ServerInstance $vSvrDest -Database $vDBnameDest -Query "select distinct ltrim(rtrim(machinename)) from DBA.dbo.CMS_SQLServers;" -AbortOnError | format-table -HideTableHeaders | out-file $machfile;
(gc $machfile) | Foreach {$_.TrimEnd()} | ? {$_.trim() -ne "" } | set-content $machfile;
invoke-sqlcmd -ServerInstance $vSvrDest -Database $vDBnameDest -Query "select ltrim(rtrim(instancename)) from DBA.dbo.CMS_SQLServers order by grouppath;" -AbortOnError | format-table -HideTableHeaders | out-file $instfile;
(gc $instfile) | Foreach {$_.TrimEnd()} | ? {$_.trim() -ne "" } | set-content $instfile;
#>

#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
$machfile = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions\MachineNames.txt";
$instfile = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\OS_functions\InstanceNames.txt";
#PingTest.PS1
$servers = gc $machfile;
ForEach ($s in $servers) 
{
 if(!(Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))
    {  write-host "$s - Ping failed" -f red};
 if((Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0)) 
    { write-host "$s - Ping successful" -f yellow; 
      # Verify if the SQL server has WindRM installed. If not just select uptime from SQL command, else call PS script getServerUptime.
      $wsman = Test-WSMan -ComputerName $s -ApplicationName WSMAN -ErrorAction 0 -Authentication default;
      if ($wsman -eq $null) { write-host "WinRM is not installed.";  <#Get-Uptime -ComputerName $s; #> };
      if ($wsman -ne $null)  { .\getServerUptime.ps1 -NumberOfDays 365 -ComputerName $s | format-table -AutoSize ; };
    };
} 

#Foreach($s in $servers)
#{
#    if((Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0))
#    {
        #Write-Output "Problem connecting to $s";
        #Write-Output “Flushing DNS”;
        #ipconfig /flushdns | out-null;
        #ipconfig | out-null;
        #Write-Output “Registering DNS”;
        #ipconfig /registerdns | out-null;
        #write-output “doing a NSLookup for $s”;
        #nslookup $s ;

        #write-output “Re-pinging $s”;
        #if(!(Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))
        #    {“Problem still exists in connecting to $s"}
        #ELSE {“Resolved problem connecting to $s"};

    #}
#}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
