<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute read-host command one time only. If password changes re-execute command and store credentials in encrypted file.
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\BossServerName.txt;  RWBDBAGH213\MOBILE01
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\BossdBName.txt;      prodServSuiteData
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\MgmtServerName.txt;  RWSQLMGMTH202
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\MgmtdBName.txt;      DBA
# $Credential = Get-Credential # this will prompt for new credentials.
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
cls;

write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;

write-host "Setting path" -ForegroundColor Yellow;
#Set script and file location path
$vPath = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo";
Set-Location $vPath;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#
$BossServerName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\BossServerName.txt' | ConvertTo-SecureString;
$BossdBName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\BossdBName.txt' | ConvertTo-SecureString;
$MgmtServerName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\MgmtServerName.txt' | ConvertTo-SecureString;
$MgmtdBName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\MgmtdBName.txt' | ConvertTo-SecureString;
#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Remove file if it exists.
$vFullPath = join-path $vPath "\tssmarq1.csv"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}

# Connect to BOSS production Replica2, execute SQL query tssmarketingprocessq.sql and store results in new tab in Excel file. Windows Authentication used when user and password not supplied.
write-host "Executing Marketo integration query from Live data .... " -ForegroundColor Green;
$TableR2 = Invoke-Sqlcmd -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\tssmarketingprocessq.sql" -ServerInstance RWBDBAGH213\MOBILE01 -Database prodServSuiteData -AbortOnError;
$TableR2 | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\tssmarq1.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Merge Excel .CSV file - eComLO into eCommLO_data.xlsx. 
# Remove file if it exists.
write-host "Merge sales and leads csv files into one excel file .... " -ForegroundColor Green;
$vFullPath = join-path $vPath "\tssmarq.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
# Create Excel Object
$ExcelObject=New-Object -ComObject excel.application
$ExcelObject.visible=$false
# Fetch all .CSV files
$ExcelFiles=Get-ChildItem -Path C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\tssmarq1.csv
# Create new Workbook
$Workbook=$ExcelObject.Workbooks.add()
$Worksheet=$Workbook.Sheets.Item("Sheet1")
# Loop both files, copy worksheet into new excel file
foreach($ExcelFile in $ExcelFiles){
    $Everyexcel=$ExcelObject.Workbooks.Open($ExcelFile.FullName)
    $Everysheet=$Everyexcel.sheets.item(1)
    $Everysheet.Copy($Worksheet)
    $Everyexcel.Close()
}
# Rename worksheets accordingly
$Workbook.Worksheets.Item(1).Name = "Marketo Data";
$Workbook.Worksheets.Item("Sheet1").Delete();
$Workbook.Worksheets.Item("Sheet2").Delete();
$Workbook.Worksheets.Item("Sheet3").Delete();
#$objRange = $Workbook.Sheets.Item("Leads").Range("R1").EntireColumn;
#$objRange.WrapText = $False;
$Workbook.Worksheets.Item(1).Activate();
$Workbook.SaveAs($vFullPath);
$ExcelObject.Quit();
spps -n excel;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Send email including attachment.
C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\Send_Email_Marketo "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Marketo\tssmarq.xlsx" "Marketo Integration Data";
write-host "Email Sent .... "-ForegroundColor Yellow;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
write-host "Session Disconnected .... "-ForegroundColor Green;
write-host "End time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
cls;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
