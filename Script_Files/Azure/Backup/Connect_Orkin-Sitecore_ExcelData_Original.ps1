<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute read-host command one time only. If password changes re-execute command and store credentials in encrypted file.
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnCred.txt;
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnCred.txt;
# $Credential = Get-Credential # this will prompt for new credentials.
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
cls;
# Connect to Azure Portal (using office 365 email credentials). 
# Store password as encrypted string file. 
# Create a new credential object.
write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
$AzureAccount = "ssubrahm@rollins.com";
$password = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnCred.txt' | ConvertTo-SecureString;
($Credential_AZ = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureAccount, $password);

write-host "Connecting to Azure Portal: " $Credential_AZ "-" $AzureAccount -ForegroundColor Green;
Connect-AzureRmAccount -Credential $Credential_AZ -ErrorAction Stop > $null;
Select-AzureRMSubscription -Tenant 08269009-94b5-4924-8377-7e84dddfa998 -InformationAction SilentlyContinue -ErrorAction Stop > $null;
write-host "Selected Subscription..." -ForegroundColor Green;;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
#Set script and file location path
$vPath = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure";
Set-Location $vPath;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Credentials to connect to SQL Azure database (using sql account and password).
# Store password as encrypted string file. 
$AzureSQLAccount = "OrkinEcommDbReader";
$SecurepasswordSQL = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnCred.txt' | ConvertTo-SecureString;
$PasswordSQL = (New-Object PSCredential $AzureSQLAccount,$SecurepasswordSQL).GetNetworkCredential().Password;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Fetch Azure SQL server and database names. Execute SQL command.

$ServerName = "prod1811-orkin-175640-sql.database.windows.net";
$dBName = "prod-orkin-ecommerce";

# Set SQL connectivity parameters.
# sessioncomplete between (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()) - 1, 0)) and (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) and
$params = @{
    'Database' = $dBName
    'ServerInstance' = $ServerName
    'Username' = $AzureSQLAccount
    'Password' = $PasswordSQL
    'Query' = 'select * from [dbo].[EcommerceTransaction] where firstname not like ''test%'' and lastname not like ''test%'' and emailaddress not like ''%capgemini%'' order by sessioncomplete DESC;'
};
write-host "Executing eCommerce database SQL command.... " -ForegroundColor Green;

# Execute command and export to CSV file.
$TableAz = Invoke-Sqlcmd @params -AbortOnError;
$TableAz | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm1.csv" -NoTypeInformation -UseCulture -force;

DisConnect-AzureRmAccount > $null;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Connect to BOSS production Replica2, execute SQL query and store results in Excel file. Windows Authentication used when user and password not supplied.

$ServerName = "RWBDBAGH203\MOBILE01";
$dBName = "prodServSuiteData";
write-host "Executing eCommerce database SQL command.... " -ForegroundColor Green;

# Execute command and export to CSV file.
$TableR2 = Invoke-Sqlcmd -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\ecomm_leads.sql" -ServerInstance $ServerName -Database $dBName -AbortOnError;
$TableR2 | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm2.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Merge Excel .CSV files - sales: eComm1.csv & leads: eComm2.csv into eComm_data.xlsx. 
# Rename each worksheet as Sales and Leads in file eComm_data.xlsx.
# File names eComm1 and eComm2 is named due to sorting requirement when merging the two files.
# Remove file if it exists.
$vFullPath = join-path $vPath "\eComm_data.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}
# Create Excel Object
$ExcelObject=New-Object -ComObject excel.application
$ExcelObject.visible=$false
# Fetch 2 .CSV files
$ExcelFiles=Get-ChildItem -Path C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm*.csv
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
$Workbook.Worksheets.Item(1).Name = "Sales";
$Workbook.Worksheets.Item(2).Name = "Leads";
$Workbook.Worksheets.Item("Sheet1").Delete();
$Workbook.Worksheets.Item("Sheet2").Delete();
$Workbook.Worksheets.Item("Sheet3").Delete();
$Workbook.SaveAs($vFullPath);
$ExcelObject.Quit();
spps -n excel;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Send email including attachment.
C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Send_Email "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm_data.xlsx" "eCommerce Data";
write-host "Email Sent .... "-ForegroundColor Yellow;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
write-host "Session Disconnected .... "-ForegroundColor Green;
write-host "End time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
cls;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
