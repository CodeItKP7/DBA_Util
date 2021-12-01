#**********************************************************************************
# Script Name:  SQLAgentJob_report.ps1
# Script Path:  C:\Powersh\Rollins\DBA_Admin\Script_Files
# Description:  Last SQL Agent job report script for WALTHAM production sql server only [WWSQLDBH201.wsinet.local].
# Date created: 12/17/2014
# Created By:   Shyam Subrahmanyam
# Group:        ITC Operations (Rollins Inc.)
# Execution:    SQL Agent job on the RWSQLMGMTH201 management server
#               calls this powershell script on a daily basis and
#               emails the excel file as an attachment to the DBA group.
# SQL Job:      Generate_SQLAgentJob_Report
# Server List:  CMS - production from RWSQLMGMTH201.
# Excel path:   C:\Powersh\Rollins\DBA_Admin\Output_Files\SQLAgentJob_report_WALTHAM.xlsx
#**********************************************************************************

$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vFullPath = join-path $vPath "Output_Files\SQLAgentJob_report_WALTHAM.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
$Excel = New-Object -ComObject Excel.Application 
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1) 
$intRow = 1
foreach ($vSvr in gc "Prod_Servers_WALTHAM.txt")
{
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null;
     [System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”) | out-null;
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr;

     # Impersonate sa user for Waltham SQL server.
     $s.ConnectionContext.LoginSecure = $false
     $s.ConnectionContext.set_Login('sa')
     $s.ConnectionContext.set_Password('fQJJFlMnM?xX-Cw') #'p35tp@c'

     $js = $s.JobServer.jobs | select parent, name, datecreated, datelastmodified, currentrunstatus, LastRunDate, LastRunOutcome, NextRunDate, isenabled, OwnerLoginName | ? {$_.isenabled -eq $true} ;

     $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME"
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $intRow++
     $Sheet.Cells.Item($intRow,1) = $vSvr
     $intRow++
     $Sheet.Cells.Item($intRow,1) = "NAME"
     $Sheet.Cells.Item($intRow,2) = "DATE CREATED"
     $Sheet.Cells.Item($intRow,3) = "DATE LAST MODIFIED"
     $Sheet.Cells.Item($intRow,4) = "CURRENT RUN STATUS"
     $Sheet.Cells.Item($intRow,5) = "LAST RUN DATE"
     $Sheet.Cells.Item($intRow,6) = "LAST RUN OUTCOME"
     $Sheet.Cells.Item($intRow,7) = "NEXT RUN DATE"
     $Sheet.Cells.Item($intRow,8) = "OWNER"
     for ($col = 1; $col –le 8; $col++)
     {    $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }
     $intRow++

     ForEach ($row in $js) 
     {
          $Sheet.Cells.Item($intRow, 1) = $row.Name
          $Sheet.Cells.Item($intRow, 2) = $row.datecreated
          $Sheet.Cells.Item($intRow, 3) = $row.datelastmodified

          $Sheet.Cells.Item($intRow, 4) = $row.currentrunstatus
          if ($row.currentrunstatus -eq 1) { $Sheet.Cells.Item($intRow, 4) = "Executing" }
          elseif ($row.currentrunstatus -eq 4) { $Sheet.Cells.Item($intRow, 4) = "Idle" }
          else { $Sheet.Cells.Item($intRow, 4) = "Unknown"}

          $Sheet.Cells.Item($intRow, 5) = $row.LastRunDate
          $Sheet.Cells.item($intRow, 5).Interior.ColorIndex = 44

		  $Sheet.Cells.Item($intRow, 6) = $row.LastRunOutcome
          if ($row.LastRunOutcome -eq 0) { $Sheet.Cells.Item($intRow, 6) = "Failed" }
          elseif ($row.LastRunOutcome -eq 1) { $Sheet.Cells.Item($intRow, 6) = "Succeeded" }
          elseif ($row.LastRunOutcome -eq 2) { $Sheet.Cells.Item($intRow, 6) = "Retry" }
          elseif ($row.LastRunOutcome -eq 3) { $Sheet.Cells.Item($intRow, 6) = "Canceled" }
          elseif ($row.LastRunOutcome -eq 4) { $Sheet.Cells.Item($intRow, 6) = "In progress" }
          else {$Sheet.Cells.Item($intRow, 6) = "Unknown"}
		  if ($row.LastRunOutcome -eq 0) { $fgColor = 3 } else {$fgColor = 50}
		  $Sheet.Cells.item($intRow, 6).Interior.ColorIndex = $fgColor

          $Sheet.Cells.Item($intRow, 7) = $row.NextRunDate
          $Sheet.Cells.Item($intRow, 8) = $row.OwnerLoginName
          $intRow ++
     }
$intRow ++
}
$Sheet.UsedRange.EntireColumn.AutoFit();
$Excel.Worksheets.Item(3).Delete();
$Excel.Worksheets.Item(2).Delete();
$Excel.Worksheets.Item(1).Name = "SQL Job Details";
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