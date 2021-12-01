#**********************************************************************************
# Script Name:  BOSS_ProcStats_report.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  BOSS Live and replicated servers procedure stats report script.
# Date created: 08/21/2015
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH201 management server
#               calls this powershell script on a daily basis and
#               emails the excel file as an attachment to Dev, IT BOSS management and DBA group.
# SQL Job:      Generate_BOSS_ProcStats_report
# Server List:  CMS - production from RWSQLMGMTH201.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\BOSS_ProcStats_ORKIN.xlsx
#**********************************************************************************

$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vToday = (Get-date -UFormat "%m%d%Y").ToString()
#$vPathExtn = "Output_Files\BOSS_ProcStats_ORKIN_" + $vToday + ".xlsx"
$vPathExtn = "Output_Files\BOSS_ProcStats_ORKIN.xlsx"
$vFullPath = join-path $vPath $vPathExtn
if (Test-Path $vFullPath) { Remove-Item $vFullPath}

# Query to execute
$cmd_PrStat = "SELECT TOP 1000 d.object_id as 'Object ID', db_name(d.database_id) as 'DB Name', OBJECT_NAME(object_id, database_id) as 'Procedure Name', " + `
              "d.cached_time as 'Cached Time', d.last_execution_time as 'Last Execution Time' , total_worker_time as 'Total Worker Time', max_physical_reads as 'Max Physical Reads', " + `
              "d.total_elapsed_time as 'Total Elapsed Time', d.total_elapsed_time/d.execution_count AS 'Avg Elapsed Time (per execution)', " + `
              "(d.total_elapsed_time/d.execution_count) * 0.000001 AS 'Avg Elapsed Time (per execution in seconds)', d.execution_count as 'Execution Count', " + `
              "d.last_elapsed_time as 'Last Elapsed Time (Microseconds)', d.last_elapsed_time * 0.000001 as 'Last Elapsed Time (Seconds)', " + `
              "d.min_elapsed_time * 0.000001 as 'Min Elapsed Time (Seconds)', d.max_elapsed_time * 0.000001 as 'Max Elapsed Time (Seconds)' " + `
              "FROM sys.dm_exec_procedure_stats AS d " + `
              "ORDER BY [total_worker_time] DESC; " ;

# Function to populate data from SQL Server
function Get-DataTable-DS([string]$pSQL)
{
	$dataSet= new-object "System.Data.DataSet" "DS";
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($pSQL, $ProdConn);
	$da.Fill($dataSet) | Out-Null;
	return $dataSet.Tables[0];
}

#switch ($vSvr)
#{
#    "RWBDBAGH201" {$vDBName = "prodServSuiteData"};
#    "RWBDBAGH202" {$vDBName = "ServSuiteData_Replicated"};
#}
#$ProdConn = new-object "System.Data.SqlClient.SqlConnection" ("server=$vSvr;database=master;Integrated Security=sspi");

# Open Excel object
$Excel = New-Object -ComObject Excel.Application 
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1) 
$intRow = 1
$vRetDataTable = new-object "System.Data.DataTable" "DS1"

# Loop through each SQL Server
foreach ($vSvr in gc "Prod_Servers_BOSS.txt")
{
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null;
    [System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”) | out-null;

    $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr;
    $ssd = $s.Information | select Parent, NetName, Product, Edition, VersionString, BuildNumber, isclustered ;

    $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME"
    $Sheet.Cells.Item($intRow,2) = "HOSTNAME"
    $Sheet.Cells.Item($intRow,3) = "PRODUCT"
    $Sheet.Cells.Item($intRow,4) = "EDITION"
    $Sheet.Cells.Item($intRow,5) = "VERSION"
    $Sheet.Cells.Item($intRow,6) = "BUILDNUMBER"
    $Sheet.Cells.Item($intRow,7) = "ISCLUSTERED"
    $Sheet.Cells.Item($intRow,1).Font.Bold = $True
    $Sheet.Cells.Item($intRow,2).Font.Bold = $True
    $Sheet.Cells.Item($intRow,3).Font.Bold = $True
    $Sheet.Cells.Item($intRow,4).Font.Bold = $True
    $Sheet.Cells.Item($intRow,5).Font.Bold = $True
    $Sheet.Cells.Item($intRow,6).Font.Bold = $True
    $Sheet.Cells.Item($intRow,7).Font.Bold = $True
    $intRow++
    $Sheet.Cells.Item($intRow,1) = $vSvr
    $Sheet.Cells.Item($intRow,2) = $ssd.NetName
    $Sheet.Cells.Item($intRow,3) = $ssd.Product
    $Sheet.Cells.Item($intRow,4) = $ssd.Edition
    $Sheet.Cells.Item($intRow,5) = $ssd.VersionString
    $Sheet.Cells.Item($intRow,6) = $ssd.BuildNumber
    $Sheet.Cells.Item($intRow,7) = $ssd.isclustered
    $intRow++
    $intRow++
    $Sheet.Cells.Item($intRow,1) = "OBJECT ID"
    $Sheet.Cells.Item($intRow,2) = "DB NAME"
    $Sheet.Cells.Item($intRow,3) = "PROCEDURE NAME"
    $Sheet.Cells.Item($intRow,4) = "CACHED TIME"
    $Sheet.Cells.Item($intRow,5) = "LAST EXECUTION TIME"
    $Sheet.Cells.Item($intRow,6) = "TOTAL WORKER TIME"
    $Sheet.Cells.Item($intRow,7) = "MAX PHYSICAL READS"
    $Sheet.Cells.Item($intRow,8) = "TOTAL ELAPSED TIME"
    $Sheet.Cells.Item($intRow,9) = "AVG ELAPSED TIME (per execution)"
    $Sheet.Cells.Item($intRow,10) = "AVG ELAPSED TIME (per execution in seconds)"
    $Sheet.Cells.Item($intRow,11) = "EXECUTION COUNT"
    $Sheet.Cells.Item($intRow,12) = "LAST ELAPSED TIME (Microseconds)"
    $Sheet.Cells.Item($intRow,13) = "LAST ELAPSED TIME (Seconds)"
    $Sheet.Cells.Item($intRow,14) = "MIN ELAPSED TIME (Seconds)"
    $Sheet.Cells.Item($intRow,15) = "MAX ELAPSED TIME (Seconds)"
    $Sheet.Cells.Item($intRow,1).Font.Bold = $True
    $Sheet.Cells.Item($intRow,2).Font.Bold = $True
    $Sheet.Cells.Item($intRow,3).Font.Bold = $True
    $Sheet.Cells.Item($intRow,4).Font.Bold = $True
    $Sheet.Cells.Item($intRow,5).Font.Bold = $True
    $Sheet.Cells.Item($intRow,6).Font.Bold = $True
    $Sheet.Cells.Item($intRow,7).Font.Bold = $True
    $Sheet.Cells.Item($intRow,8).Font.Bold = $True
    $Sheet.Cells.Item($intRow,9).Font.Bold = $True
    $Sheet.Cells.Item($intRow,10).Font.Bold = $True
    $Sheet.Cells.Item($intRow,11).Font.Bold = $True
    $Sheet.Cells.Item($intRow,12).Font.Bold = $True
    $Sheet.Cells.Item($intRow,13).Font.Bold = $True
    $Sheet.Cells.Item($intRow,14).Font.Bold = $True
    $Sheet.Cells.Item($intRow,15).Font.Bold = $True
    $intRow++
	$ProdConn = "server=$vSvr;database=master;Integrated Security=true";

	$vRetDataTable = $null
	$vRetDataTable = Get-DataTable-DS ($cmd_PrStat)
	$vRetDataTable | foreach-object {
        $Sheet.Cells.Item($intRow, 1) = $_."Object ID"
        $Sheet.Cells.Item($intRow, 2) = $_."DB Name"
        $Sheet.Cells.Item($intRow, 3) = $_."Procedure Name"
        $Sheet.Cells.Item($intRow, 4) = $_."Cached Time"
        $Sheet.Cells.Item($intRow, 5) = $_."Last Execution Time"
		$Sheet.Cells.Item($intRow, 6) = $_."Total Worker Time"
        $Sheet.Cells.Item($intRow, 7) = $_."Max Physical Reads"
        $Sheet.Cells.Item($intRow, 8) = $_."Total Elapsed Time"
		$Sheet.Cells.Item($intRow, 9) = $_."Avg Elapsed Time (per execution)"
        $Sheet.Cells.Item($intRow, 10) = $_."Avg Elapsed Time (per execution in seconds)"
        $Sheet.Cells.Item($intRow, 11) = $_."Execution Count"
		$Sheet.Cells.Item($intRow, 12) = $_."Last Elapsed Time (Microseconds)"
        $Sheet.Cells.Item($intRow, 13) = $_."Last Elapsed Time (Seconds)"
        $Sheet.Cells.Item($intRow, 14) = $_."Min Elapsed Time (Seconds)"
        $Sheet.Cells.Item($intRow, 15) = $_."Max Elapsed Time (Seconds)"
        $intRow ++
     }

$intRow ++
$intRow ++
}
$Sheet.UsedRange.EntireColumn.AutoFit();
$Excel.Worksheets.Item(3).Delete();
$Excel.Worksheets.Item(2).Delete();
$Excel.Worksheets.Item(1).Name = "Proc Stats details";
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