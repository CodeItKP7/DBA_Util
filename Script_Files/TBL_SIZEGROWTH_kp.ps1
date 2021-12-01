?cls;
import-module SQLServer;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Table size collection for "prodServSuiteData" database on BOSS Live instance.

$vSvrSrc = "RWBDBAGH211"; $vDBnameSrc = "prodServSuiteData";
$vSvrDest = "RWSQLMGMTH202"; $vDBnameDest = "DBA";

$Results = invoke-sqlcmd -ServerInstance $vSvrSrc -Database $vDBnameSrc -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\TBL_SizeGrowth_kp.sql" -As DataTables;

Write-SqlTableData -ServerInstance $vSvrDest -DatabaseName $vDBnameDest -SchemaName dbo -TableName TableSizeGrowth -InputData $Results;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Table size collection for "prodServSuiteLog" database on BOSS Live instance.

#$vSvrSrc = "RWBDBAGH211"; $vDBnameSrc = "prodServSuiteLog";

#$Results = invoke-sqlcmd -ServerInstance $vSvrSrc -Database $vDBnameSrc -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\TBL_SizeGrowth.sql" -As DataTables;

#Write-SqlTableData -ServerInstance $vSvrDest -DatabaseName $vDBnameDest -SchemaName dbo -TableName TableSizeGrowth -InputData $Results;
#------------------------------------------------------------------------------------------------------------------------------------------------------------------#