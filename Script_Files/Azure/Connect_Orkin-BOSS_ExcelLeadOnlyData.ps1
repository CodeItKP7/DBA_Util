<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute read-host command one time only. If password changes re-execute command and store credentials in encrypted file.
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureAccount.txt;      ssubrahm@rollins.com
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnPass.txt;     *****a29
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureServerName.txt;   prod1811-orkin-175640-sql.database.windows.net
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzuredBName.txt;       prod-orkin-ecommerce
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLAccount.txt;   OrkinEcommDbReader
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnPass.txt;  cZVHZ=2^H&+ma9fH
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\BossServerName.txt;    RWBDBAGH213\MOBILE01
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\BossdBName.txt;        prodServSuiteData
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\MgmtServerName.txt;    RWSQLMGMTH202
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\MgmtdBName.txt;        DBA
# $Credential = Get-Credential # this will prompt for new credentials.
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
cls;

write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;

write-host "Setting path" -ForegroundColor Yellow;
#Set script and file location path
$vPath = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure";
Set-Location $vPath;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$BossServerName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\BossServerName.txt' | ConvertTo-SecureString;
$BossdBName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\BossdBName.txt' | ConvertTo-SecureString;
$MgmtServerName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\MgmtServerName.txt' | ConvertTo-SecureString;
$MgmtdBName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\MgmtdBName.txt' | ConvertTo-SecureString;

# Truncate tables DBA.DBO.Staging_eCommerceTransaction & DBA.DBO.Staging_tWebCommerceBasket.
#write-host "Truncate staging tables in management server..." -ForegroundColor Green;
##invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\truncateSQL.sql";
#invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -Query "Truncate Table DBA.DBO.Staging_eCommerceTransaction;" -AbortOnError;
#invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -Query "Truncate Table DBA.DBO.Staging_tWebCommerceBasket;" -AbortOnError;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Connect to BOSS production Replica2, execute SQL query ecomm_lead_only.sql and store results in new tab in Excel file. Windows Authentication used when user and password not supplied.
write-host "Executing eCommerce leads query from Replica2 data .... " -ForegroundColor Green;
$TableR2 = Invoke-Sqlcmd -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\ecomm_lead_only.sql" -ServerInstance RWBDBAGH213\MOBILE01 -Database prodServSuiteData -AbortOnError;
$TableR2 | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComLO.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Merge Excel .CSV file - eComLO into eCommLO_data.xlsx. 
# Remove file if it exists.
write-host "Merge sales and leads csv files into one excel file .... " -ForegroundColor Green;
$vFullPath = join-path $vPath "\eCommLO_data.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
# Create Excel Object
$ExcelObject=New-Object -ComObject excel.application
$ExcelObject.visible=$false
# Fetch 3 .CSV files
$ExcelFiles=Get-ChildItem -Path C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComLO.csv
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
$Workbook.Worksheets.Item(1).Name = "Lead Only";
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
C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Send_Email_leadonly "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eCommLO_data.xlsx" "eCommerce Lead Only Data";
write-host "Email Sent .... "-ForegroundColor Yellow;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
write-host "Session Disconnected .... "-ForegroundColor Green;
write-host "End time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
cls;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
