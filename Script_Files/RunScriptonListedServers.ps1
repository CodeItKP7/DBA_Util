$srvList = Get-content 'C:\PowerSh\Rollins\DBA_Admin\Test.txt'

FOREACH($instance in $srvList)
{
write-host $instance
$db = 'ServSuiteWBUser'
$SQL = "update tlogin set adusername = 'rollins\'+right(adusername, len(adusername)-charindex('\',adusername))  where adusername like 'cbs\%'"
write-host $sql
invoke-sqlcmd -ServerInstance $instance -Database $db -Query $SQL
}