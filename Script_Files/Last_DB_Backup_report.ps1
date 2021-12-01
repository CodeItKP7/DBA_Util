#**********************************************************************************
# Script Name:  Last_DB_Backup_report.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  Last DB backup report script for all production sql servers.
# Date created: 08/27/2014
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH201 management server
#               calls this powershell script on a daily basis and
#               emails the excel file as an attachment to the DBA group.
# SQL Job:      Generate_Last_DB_Backup_Report
# Server List:  CMS - production from RWSQLMGMTH201.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\LastDbBackup_Report.xlsx
#**********************************************************************************

$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
#$vToday = (Get-date -UFormat "%m%d%Y").ToString()
#$vYest = (get-date).AddDays(-1).ToString("MMddyyyy")
#$vPathExtn = "Output_Files\LastDbBackup_Report_ORKIN_" + $vToday + ".xlsx"
#$vYestPathExtn = "Output_Files\LastDbBackup_Report_ORKIN_" + $vYest + ".xlsx"

$vPathExtn = "Output_Files\LastDbBackup_Report_ORKIN.xlsx"
$vFullPath = join-path $vPath $vPathExtn
#$vFullPathYest = join-path $vPath $vYestPathExtn
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
#if (Test-Path $vFullPathYest) { Remove-Item $vFullPathYest}

$Excel = New-Object -ComObject Excel.Application 
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1) 
$intRow = 1
foreach ($vSvr in gc "Prod_Servers.txt")
{
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null;
     [System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”) | out-null;
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr;
     $ssd = $s.Information | select Parent, NetName, Product, Edition, VersionString, BuildNumber, isclustered ;
     $dbs = $s.Databases.GetEnumerator() | select Name,ID,LastBackupDate,LastDifferentialBackupDate,LastLogBackupDate,RecoveryModel,Owner,Status | sort ID;

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
     $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
     $Sheet.Cells.Item($intRow,2) = "ID"
     $Sheet.Cells.Item($intRow,3) = "LAST BACKUP DATE"
     $Sheet.Cells.Item($intRow,4) = "LAST DIFF BACKUP DATE"
     $Sheet.Cells.Item($intRow,5) = "LAST LOG BACKUP DATE"
     $Sheet.Cells.Item($intRow,6) = "RECOVERY MODEL"
     $Sheet.Cells.Item($intRow,7) = "OWNER"
     $Sheet.Cells.Item($intRow,8) = "STATUS"
     for ($col = 1; $col –le 8; $col++)
     {    $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }
     $intRow++

     ForEach ($db in $dbs) 
     {
          $Sheet.Cells.Item($intRow, 1) = $db.Name
          $Sheet.Cells.Item($intRow, 2) = $db.ID
          $Sheet.Cells.Item($intRow, 3) = $db.LastBackupDate
          $Sheet.Cells.Item($intRow, 4) = $db.LastDifferentialBackupDate
          $Sheet.Cells.Item($intRow, 5) = $db.LastLogBackupDate
          #$Sheet.Cells.item($intRow, 4).Interior.ColorIndex = 44

		  $Sheet.Cells.Item($intRow, 6) = $db.RecoveryModel
		  if ($db.RecoveryModel -eq 1) { $Sheet.Cells.Item($intRow, 6) = "Full" }
		  elseif ($db.RecoveryModel -eq 3) { $Sheet.Cells.Item($intRow, 6) = "Simple" }
		  else { $Sheet.Cells.Item($intRow, 6) = "Bulk Logged" }
          if ($db.RecoveryModel -eq 3)  { $fgColor = 50 }  else { $fgColor = 3 }
		  $Sheet.Cells.item($intRow, 6).Interior.ColorIndex = $fgColor

          $Sheet.Cells.Item($intRow, 7) = $db.Owner
          $Sheet.Cells.Item($intRow, 8) = $db.Status
          if ($db.Status -eq 1) { $Sheet.Cells.Item($intRow, 8) = "Normal" }
          elseif ($db.Status -eq 2) { $Sheet.Cells.Item($intRow, 8) = "Restoring" }
          elseif ($db.Status -eq 193) { $Sheet.Cells.Item($intRow, 8) = "Read-Only" }
          elseif ($db.Status -eq 129) { $Sheet.Cells.Item($intRow, 8) = "Shutdown\Normal" }
          elseif ($db.Status -eq 544) { $Sheet.Cells.Item($intRow, 8) = "Offline" }
          else { $Sheet.Cells.Item($intRow, 8) = "Unknown" }

          $intRow ++
     }
$intRow ++
}
$Sheet.UsedRange.EntireColumn.AutoFit();
$Excel.Worksheets.Item(3).Delete();
$Excel.Worksheets.Item(2).Delete();
$Excel.Worksheets.Item(1).Name = "Backup details";
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
