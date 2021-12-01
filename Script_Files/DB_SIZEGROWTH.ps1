cls;
import-module SQLServer;
$vDBnameSrc = "master";
$vSvrDest = "RWSQLMGMTH202"; $vDBnameDest = "DBA";

foreach ($vSvr in get-content "C:\PowerSh\Rollins\DBA_Admin\Prod_Servers_DBGrowth.txt")
{
$Results = invoke-sqlcmd -ServerInstance $vSvr -Database $vDBnameSrc -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\DB_SizeGrowth.sql" -As DataTables;
Write-SqlTableData -ServerInstance $vSvrDest -DatabaseName $vDBnameDest -SchemaName dbo -TableName DBSizeGrowth -InputData $Results;
};
