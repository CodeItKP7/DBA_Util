#**********************************************************************************
# Script Name:  SQL_BOSS_IdentitySpillOver_report.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  Capture all identity columns on all tables and databases, and all values to see if they are in danger of spilling over designated data type limits.
# Date created: 01/11/2017
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH202 management server
#               calls this powershell script on a monthly basis and
#               emails the excel file as an attachment to the DBA group.
# SQL Job:      Generate_BOSS_IdentitySpillOver
# Server List:  CMS - production from RWSQLMGMTH202.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\BOSS_IdentitySpillOver_report_ORKIN.xlsx
#**********************************************************************************

cls;
$vPath = "C:\Powersh\Rollins\DBA_Admin";
Set-Location $vPath;
$vFullPath = join-path $vPath "Output_Files\BOSS_IdentitySpillOver_report_ORKIN.xlsx";
if (Test-Path $vFullPath) { Remove-Item $vFullPath};

# Open Excel object
$Excel = New-Object -ComObject Excel.Application ;
$Excel.visible = $True;
$Excel = $Excel.Workbooks.Add();
$Sheet = $Excel.Worksheets.Item(1) ;
$intRow = 1;

# Function to populate data from SQL Server
function Get-DataTable([string]$vSQL)
{
    $dataSet= new-object "System.Data.DataSet" "DS";
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($vSQL, $SQLcon);
	$da.Fill($dataSet) | Out-Null;
	return $dataSet.Tables[0];
}
# Query to execute - limit searching tables where identity value is > 100000000
$cmd =  "SELECT sys.tables.name AS [Table Name], sys.schemas.name AS [Schema Name], sys.identity_columns.name AS [Column Name], sys.types.name AS [Data Type], sys.identity_columns.last_value AS [Last Value], " + `
        "sys.identity_columns.max_length, CASE lower(sys.types.name) WHEN 'int' THEN	CAST(cast(sys.identity_columns.last_value as int) / 2147483647.0 * 100.0 AS DECIMAL(5,2)) " + `
        "WHEN 'bigint' THEN	CAST(cast(sys.identity_columns.last_value as bigint) / 9223372036854775807.0 * 100.0 AS DECIMAL(5,2))  END AS [Percentage of ID's Used], " + `
	    "CASE lower(sys.types.name) WHEN 'int' THEN	2147483647 - cast(sys.identity_columns.last_value as int) WHEN 'bigint' THEN 9223372036854775807 - cast(sys.identity_columns.last_value as bigint) END AS [Remaining], " + `
	    "seed_value AS [Starting Number], increment_value AS [Increment By] " + `
        "FROM sys.identity_columns " + `
        "INNER JOIN sys.tables ON sys.identity_columns.object_id = sys.tables.object_id " + `
	    "INNER JOIN sys.types ON sys.types.user_type_id = sys.identity_columns.user_type_id " + `
        "INNER JOIN sys.schemas ON sys.schemas.schema_id = sys.tables.schema_id " + `
        "WHERE sys.identity_columns.last_value > 100000000 " + `
        "ORDER BY last_value DESC ";

$vRetDataTable = new-object "System.Data.DataTable" "DS1";

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
    $Sheet.Cells.Item($intRow,1).Font.ColorIndex = 3
    $Sheet.Cells.Item($intRow,2) = $ssd.NetName
    $Sheet.Cells.Item($intRow,3) = $ssd.Product
    $Sheet.Cells.Item($intRow,4) = $ssd.Edition
    $Sheet.Cells.Item($intRow,5) = $ssd.VersionString
    $Sheet.Cells.Item($intRow,6) = $ssd.BuildNumber
    $Sheet.Cells.Item($intRow,7) = $ssd.isclustered
    $intRow++
    $intRow++
    $Sheet.Cells.Item($intRow,1) = "Report only lists values > 100,000,000"
    $Sheet.Cells.Item($intRow,1).Font.Bold = $True
    $Sheet.Cells.Item($intRow,1).Font.ColorIndex = 50
    $intRow++
    $intRow++
    $Sheet.Cells.Item($intRow,1) = "DB NAME"
    $Sheet.Cells.Item($intRow,1).Font.Bold = $True
    $Sheet.Cells.Item($intRow,2) = "TABLE NAME"
    $Sheet.Cells.Item($intRow,3) = "SCHEMA NAME"
    $Sheet.Cells.Item($intRow,4) = "COLUMN NAME"
    $Sheet.Cells.Item($intRow,5) = "DATA TYPE"
    $Sheet.Cells.Item($intRow,6) = "LAST VALUE"
    $Sheet.Cells.Item($intRow,7) = "MAX LENGTH (bytes)"
    $Sheet.Cells.Item($intRow,8) = "PERCENTAGE OF ID'S USED"
    $Sheet.Cells.Item($intRow,9) = "REMAINING"
    $Sheet.Cells.Item($intRow,10) = "SEED STARTING NUMBER"
    $Sheet.Cells.Item($intRow,11) = "INCREMENT BY"
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
    $intRow++
	
    $dbslist = $s.Databases | select name | where-object {$_.name -notin ('tempdb', 'model')};
    $dbslist = $dbslist.name;
    $NullFlag = $true;

    foreach ($dbrow in $dbslist)
    {
        $Sheet.Cells.Item($intRow,1) = $dbrow.ToUpper();
        $Sheet.Cells.Item($intRow,1).Font.Bold = $True;
        $SQLcon = "server=$vSvr;database=$dbrow;Integrated Security=true";
        $Sheet.Cells.Item($intRow, 2) = "-"
        $Sheet.Cells.Item($intRow, 3) = "-"
        $Sheet.Cells.Item($intRow, 4) = "-"
        $Sheet.Cells.Item($intRow, 5) = "-"
        $Sheet.Cells.Item($intRow, 6) = "-"
        $Sheet.Cells.Item($intRow, 7) = "-"
        $Sheet.Cells.Item($intRow, 8) = "-"
        $Sheet.Cells.Item($intRow, 9) = "-"
        $Sheet.Cells.Item($intRow, 10) = "-"
        $Sheet.Cells.Item($intRow, 11) = "-"

        ForEach ($row in $cmd) 
        {
	        $vRetDataTable = $null
	        $vRetDataTable = Get-DataTable ($cmd)
	        $vRetDataTable | foreach-object {
                $Sheet.Cells.Item($intRow, 2) = $_."Table Name"
                $Sheet.Cells.Item($intRow, 3) = $_."Schema Name"
                $Sheet.Cells.Item($intRow, 4) = $_."Column Name"
                $Sheet.Cells.Item($intRow, 5) = $_."Data Type"
                $Sheet.Cells.Item($intRow, 6) = $_."Last Value"
		        $Sheet.Cells.Item($intRow, 7) = $_."max_length"
                $Sheet.Cells.Item($intRow, 8) = $_."Percentage of ID's Used"
                $Sheet.Cells.Item($intRow, 9) = $_."Remaining"
		        $Sheet.Cells.Item($intRow, 10) = $_."Starting Number"
                $Sheet.Cells.Item($intRow, 11) = $_."Increment By"
            $intRow ++
            }
        }
        $intRow ++
        $intRow ++
    }
}
$Sheet.UsedRange.EntireColumn.AutoFit();
$Excel.Worksheets.Item(3).Delete();
$Excel.Worksheets.Item(2).Delete();
$Excel.Worksheets.Item(1).Name = "Identity Spill Over";
$Excel.SaveAs($vFullPath);
$Excel.Close();

Start-Sleep 1
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel)|out-null;
$Excel=$null;
Remove-Variable Excel;
#spps -n excel;
[gc]::Collect();
[gc]::WaitForPendingFinalizers();

cls;