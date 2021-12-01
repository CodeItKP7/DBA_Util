
param( 
        [Parameter(Mandatory=$true)]
        [int] 
        ${Please Provide Location (1)Piedmont or (2)Franklin}
     )
$global:DC = ${Please Provide Location (1)Piedmont or (2)Franklin}
write-host $global:DC
Import-Module -Name 'dbatools'
cls

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

IF($global:DC -eq 1)
{
write-host $global:DC


$srcserver = 'RWSQLMGMTH202'
$srcDB = 'master'
$SQL= "select Server from ServersBeingBackedUp where LOC = 'P' and [connect?] = 1"
$ServerList = Invoke-dbaquery -SqlInstance "rwsqlmgmth202" -Database 'DBA' -Query $SQL
#write-host $ServerList.server

    foreach($server in $serverlist.server)
    {
    write-host $server

    #/* SQL command to delete the backups - mark all backups for deletion for instance on this server earlier than 15 days. */
    $SQL = "
    USE [master]
    GO
    DECLARE @t table (msg nvarchar(MAX))
    DECLARE @returnCode int
    INSERT INTO @t (msg) EXEC @returnCode = dbo.emc_run_delete ' -k -e `"15 days ago`" -n mssql -a DDBOOST_USER=sqlprodddboost -a DEVICE_PATH=/rscsqlprod -a `"LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox`" -a DEVICE_HOST=dd-di-rsc-01.rollins.local -a CLIENT=$server '
    IF @returnCode = 1
    BEGIN
      print 'Code 1: Error or Notice - Backup result set not found!!'
    END
    IF @returnCode = 2
    BEGIN
        print 'Code 2: Warning - Backup result set not found!!'
    END
    IF @returnCode > 2
    BEGIN
      RAISERROR ('Fail!', 16, 1)
    END"
    
    #write-host $SQL

    
   Invoke-dbaquery -SqlInstance $server -Database 'master' -Query $SQL -MessagesToOutput
   
   # write-host $results
    #$results | Out-File 'C:\PowerSh\Rollins\DBA_Admin\Output_Files\BU_Marked_4_Delete.txt' -Append
    }
}
ELSE

{
$srcserver = 'RWSQLMGMTH202'
$srcDB = 'master'
$SQL= "select Server from ServersBeingBackedUp where LOC = 'F' and [connect?] = 1"
$ServerList = Invoke-Sqlcmd -ServerInstance "rwsqlmgmth202" -Database 'DBA' -Query $SQL
cls
write-host $global:DC

    foreach($server in $serverlist.server)
    {
    write-host $server
    #write-host $DC
    
    $SQL = "
    USE [master]
    GO
    DECLARE @t table (msg nvarchar(MAX))
    DECLARE @returnCode int
    INSERT INTO @t (msg) EXEC @returnCode = dbo.emc_run_delete ' -k -e `"2 days ago`" -n mssql -a DDBOOST_USER=sqldevddboost -a DEVICE_PATH=/occcsqldev -a `"LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox`" -a DEVICE_HOST=dd-di-occc-01.rollins.local -a CLIENT=$server '

    IF @returnCode = 1
    BEGIN
      print 'Code 1: Error or Notice - Backup result set not found!!'
    END
    IF @returnCode = 2
    BEGIN
        print 'Code 2: Warning - Backup result set not found!!'
    END
    IF @returnCode > 2
    BEGIN
      RAISERROR ('Fail!', 16, 1)
    END"
    #write-host $sql
    
    Invoke-dbaquery -SqlInstance $server -Database 'master' -Query $SQL -MessagesToOutput  
    
   }
 }
 $stopwatch
 $stopwatch.Stop()