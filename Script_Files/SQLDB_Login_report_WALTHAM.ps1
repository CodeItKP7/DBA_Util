#**********************************************************************************
# Script Name:  SQLDB_Login_report_WALTHAM.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  Last SQL DB Login report script for WALTHAM production sql server only [WWSQLDBH201.wsinet.local].
# Date created: 12/17/2014
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH201 management server
#               calls this powershell script on a daily basis and
#               emails the excel file as an attachment to the DBA group.
# SQL Job:      Generate_SQLDB_Login_Report
# Server List:  CMS - production from RWSQLMGMTH201.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\SQLDB_Login_report_WALTHAM.xlsx
#**********************************************************************************

$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vFullPath = join-path $vPath "Output_Files\SQLDB_Login_report_WALTHAM.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
$Excel = New-Object -ComObject Excel.Application 
$Excel.DisplayAlerts = $false
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1) 
$intRow = 1
$vRetDataTable = new-object "System.Data.DataTable" "DS1"
[string]$cmd = "";

function Get-DataTable([string]$vSQL)
{
	$dataSet= new-object "System.Data.DataSet" "DS";
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($vSQL, $SQLcon);
	[void] $da.Fill($dataSet);
	return $dataSet.Tables[0];
}

#foreach ($vSvr in gc "Prod_Servers_WALTHAM.txt")
#{
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null;
     [System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”) | out-null;
     #$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr;

     ## Impersonate sa user for Waltham SQL server.
     #$s.ConnectionContext.LoginSecure = $false
     #$s.ConnectionContext.set_Login('sa')
     #$s.ConnectionContext.set_Password('fQJJFlMnM?xX-Cw')

     $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME"
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $intRow++
     $Sheet.Cells.Item($intRow,1) = "WWSQLDBH202.WSINET.LOCAL"
     $intRow++
     $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
     $Sheet.Cells.Item($intRow,2) = "USER NAME"
     $Sheet.Cells.Item($intRow,3) = "LOGIN TYPE"
     $Sheet.Cells.Item($intRow,4) = "CREATE DATE"
     $Sheet.Cells.Item($intRow,5) = "MODIFY DATE"
     $Sheet.Cells.Item($intRow,6) = "USER PERMISSIONS"
     for ($col = 1; $col –le 6; $col++)
     {    $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }
     $intRow++

     $vuid = 'sa'; $vpw = 'fQJJFlMnM?xX-Cw';
     $SQLcon = "server=WWSQLDBH202.WSINET.LOCAL;database=master;Persist Security Info=True;Integrated Security=false;uid=$vuid;password=$vpw;" ;

     $cmd = "DECLARE @DB_USers TABLE (DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime) "
     $cmd = $cmd + " INSERT @DB_USers EXEC sp_MSforeachdb ' "
     $cmd = $cmd + " use [?] "
     $cmd = $cmd + " SELECT ''?'' AS DB_Name, "
     $cmd = $cmd + " case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName, "
     $cmd = $cmd + " prin.type_desc AS LoginType, "
     $cmd = $cmd + " isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date "
     $cmd = $cmd + " FROM sys.database_principals prin "
     $cmd = $cmd + " LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id "
     $cmd = $cmd + " WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and "
     $cmd = $cmd + " prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%''' "
     $cmd = $cmd + " SELECT dbname, username, logintype, create_date, modify_date, "
     $cmd = $cmd + " STUFF( ( SELECT ',' + CONVERT(VARCHAR(500),associatedrole) "
     $cmd = $cmd + " FROM @DB_USers user2 "
     $cmd = $cmd + " WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName "
     $cmd = $cmd + " FOR XML PATH('') ) ,1,1,'') AS user_permissions "
     $cmd = $cmd + " FROM @DB_USers user1 "
     $cmd = $cmd + " GROUP BY dbname, username, logintype, create_date, modify_date "
     $cmd = $cmd + " ORDER BY dbname, username ; "

     #$cmd = "SELECT 'dba1' as dbname, 'servsuite1' as username, 'SQL Authentication' as logintype, getdate() as create_date, null as  modify_date, 'db_owner, db_reader' as user_permissions "

     $vRetDataTable = $null;
     $vRetDataTable = Get-DataTable ($cmd)
     $vRetDataTable | foreach-object {
          $Sheet.Cells.Item($intRow, 1) = $_.dbname
          $Sheet.Cells.Item($intRow, 2) = $_.username
          $Sheet.Cells.Item($intRow, 3) = $_.logintype
          $Sheet.Cells.Item($intRow, 4) = $_.create_date
          $Sheet.Cells.Item($intRow, 5) = $_.modify_date
	  $Sheet.Cells.Item($intRow, 6) = $_.user_permissions
          $intRow ++
     }
$intRow ++
#}
$Sheet.UsedRange.EntireColumn.AutoFit();
$Excel.Worksheets.Item(3).Delete();
$Excel.Worksheets.Item(2).Delete();
$Excel.Worksheets.Item(1).Name = "Login Details";
$Excel.SaveAs($vFullPath);
$Excel.Close();

Start-Sleep 1
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel)|out-null
$Excel=$null
Remove-Variable Excel;
#spps -n excel;
[gc]::Collect();
[gc]::WaitForPendingFinalizers();

cls;
