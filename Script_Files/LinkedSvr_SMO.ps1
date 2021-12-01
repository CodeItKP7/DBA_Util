#**********************************************************************************
# Script Name:  LinkedSvr_SMO.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  List all Linked servers script for all production sql servers.
# Date created: 09/02/2014
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH201 management server
#               calls this powershell script on a daily basis and
#               emails the excel file as an attachment to the DBA group.
# SQL Job:      -
# Server List:  CMS - production from RWSQLMGMTH201.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\LinkedSvr_List.xlsx
#**********************************************************************************

$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vFullPath = join-path $vPath "Output_Files\LinkedSvr_List.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
$Excel = New-Object -ComObject Excel.Application 
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1)
$intRow = 1
foreach ($vSvr in gc "Prod_Servers.txt")
{
	$Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
    $Sheet.Cells.Item($intRow,2) = $vSvr
    $Sheet.Cells.Item($intRow,1).Font.Bold = $True
    $Sheet.Cells.Item($intRow,2).Font.Bold = $True
    $intRow++
    $Sheet.Cells.Item($intRow,1) = "PRODUCT NAME"
    $Sheet.Cells.Item($intRow,2) = "NAME"
    $Sheet.Cells.Item($intRow,3) = "PROVIDER NAME"
    $Sheet.Cells.Item($intRow,4) = "DATA SOURCE"
    $Sheet.Cells.Item($intRow,5) = "REMOTE ACCESS"
    $Sheet.Cells.Item($intRow,6) = "DATA ACCESS"
    for ($col = 1; $col –le 6; $col++)
    {    $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
         $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
         $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
    }
    $intRow++
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
    $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr
    $dbs = $s.LinkedServers.GetEnumerator() | select ProductName,Name,DataSource,DataAccess,ProviderName,Rpc | sort Name
	ForEach ($db in $dbs) 
    { 
		if (($db.ProductName -eq $null) -or ($db.ProductName -eq "")) {$pn = "-NA-"} else {$pn = $db.ProductName.ToUpper()}
		if (($db.DataSource -eq $null) -or ($db.DataSource -eq "")) {$ds = "-NA-"} else {$ds = $db.DataSource.ToUpper()}
		if (($db.Name -eq $null) -or ($db.Name -eq "")) {$dn = "-NA-"} else {$dn = $db.Name.ToUpper()}
		if (($db.ProviderName -eq $null) -or ($db.ProviderName -eq "")) {$prvn = "-NA-"} else {$prvn = $db.ProviderName.ToUpper()}
		$Sheet.Cells.Item($intRow, 1) = $pn
        $Sheet.Cells.Item($intRow, 2) = $dn
        $Sheet.Cells.Item($intRow, 3) = $prvn
        $Sheet.Cells.Item($intRow, 4) = $ds
        $Sheet.Cells.Item($intRow, 5) = $db.Rpc
		$Sheet.Cells.Item($intRow, 6) = $db.DataAccess
        $intRow ++
     }
$intRow ++
}
$Excel.Worksheets.Item(1).Name = "Linked Servers"
$Excel.Worksheets.Item(3).Delete()
$Excel.Worksheets.Item(2).Delete()
$Sheet.UsedRange.EntireColumn.AutoFit()
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
