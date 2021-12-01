cls
REM ***** Batch PS script execution started *****

powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\BOSS_AdhocSQLStats_report.ps1"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\Last_DB_Backup_report.ps1"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\BOSS_ProcStats_report.ps1"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\SQLAgentJob_report.ps1"

REM ***** Batch PS script execution completed *****

powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\Send_Email_BOSS.ps1" "C:\Powersh\Rollins\DBA_Admin\Output_Files\BOSS_AdhocSQLStats_ORKIN.xlsx" "Daily AdhocSQL Stats Report"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\Send_Email.ps1" "C:\Powersh\Rollins\DBA_Admin\Output_Files\LastDbBackup_Report_ORKIN.xlsx" "Daily Backup Report"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\Send_Email_BOSS.ps1" "C:\Powersh\Rollins\DBA_Admin\Output_Files\BOSS_ProcStats_ORKIN.xlsx" "Daily Proc Stats Report"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\Send_Email.ps1" "C:\Powersh\Rollins\DBA_Admin\Output_Files\SQLAgentJob_report_ORKIN.xlsx" "Daily Job Report"

REM ***** Batch PS emails sent *****

powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\DB_Backup_FileCopy_to_Sharepoint.ps1"
powershell.exe -nologo -noprofile -file "C:\Powersh\Rollins\DBA_Admin\Script_Files\SQLJobs_FileCopy_to_Sharepoint.ps1"

REM ***** Batch PS documents copied to d: and sharepoint site *****
