invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -Query "Truncate Table DBA.DBO.Staging_tWebCommerceBasket_test;" -AbortOnError;

# Connect to BOSS production Replica2, execute SQL query for tWebCommerceBasket and store results in MGMT server DBA database into table DBA.DBO.Staging_tWebCommerceBasket.
write-host "Loading table Staging_tWebCommerceBasket_test table from Replica2 data into management server..." -ForegroundColor Green;
#$Results = invoke-sqlcmd -ServerInstance RWBDBAGH203\MOBILE01 -Database prodServSuiteData -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Select_tWebCommerceBasket.sql" -As DataTables;
$Results = invoke-sqlcmd -ServerInstance RWBDBAGH203\MOBILE01 -Database prodServSuiteData -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Select_tWebCommerceBasket_test.sql" -As DataTables;
Write-SqlTableData -ServerInstance RWSQLMGMTH202 -DatabaseName DBA -SchemaName dbo -TableName Staging_tWebCommerceBasket_test -InputData $Results;
