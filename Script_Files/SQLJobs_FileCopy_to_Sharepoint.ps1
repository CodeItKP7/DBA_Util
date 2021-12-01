$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vToday = (Get-date -UFormat "%m%d%Y").ToString()
$vFullPath = join-path $vPath $vPathExtn
#phased out 10/19/2021 # $vDest = "\\myteamsites\sites\datafixteam\Audit Logs\ServSuite Data Fix Audit Logs\2021 SQL Agent Jobs report\SQLAgentJob_report_ORKIN_" + $vToday + ".xlsx"
$vDest = "\\rwgscapefsh201\AuditLogs\SQL Agent Jobs report\SQLAgentJob_report_ORKIN_" + $vToday + ".xlsx"
$vDest2 = "D:\SOX_reports_secondary_copy\SQLAgentJob_report_ORKIN_" + $vToday + ".xlsx"
copy-item "C:\PowerSh\Rollins\DBA_Admin\Output_Files\SQLAgentJob_report_ORKIN.xlsx" $vDest
copy-item "C:\PowerSh\Rollins\DBA_Admin\Output_Files\SQLAgentJob_report_ORKIN.xlsx" $vDest2
