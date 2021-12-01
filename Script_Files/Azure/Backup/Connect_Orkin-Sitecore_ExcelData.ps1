<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute read-host command one time only. If password changes re-execute command and store credentials in encrypted file.
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureAccount.txt;      ssubrahm@rollins.com
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnPass.txt;     *****a27
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureServerName.txt;   prod1811-orkin-175640-sql.database.windows.net
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzuredBName.txt;       prod-orkin-ecommerce
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLAccount.txt;   OrkinEcommDbReader
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnPass.txt;  cZVHZ=2^H&+ma9fH
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\BossServerName.txt;    RWBDBAGH203\MOBILE01
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
write-host "Truncate staging tables in management server..." -ForegroundColor Green;
#invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\truncateSQL.sql";
invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -Query "Truncate Table DBA.DBO.Staging_eCommerceTransaction;" -AbortOnError;
invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -Query "Truncate Table DBA.DBO.Staging_tWebCommerceBasket;" -AbortOnError;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Connect to Azure Portal (using office 365 email credentials). 
# Store password as encrypted string file. 
# Create a new credential object.
$AzureAccount = "ssubrahm@rollins.com";
#$AzureAccount = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureAccount.txt' | ConvertTo-SecureString;
$AzureConnPass = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnPass.txt' | ConvertTo-SecureString;
($Credential_AZ = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureAccount, $AzureConnPass);

write-host "Connecting to Azure Portal: " $Credential_AZ "-" $AzureAccount -ForegroundColor Green;
Connect-AzureRmAccount -Credential $Credential_AZ -ErrorAction Stop > $null;
Select-AzureRMSubscription -Tenant 08269009-94b5-4924-8377-7e84dddfa998 -InformationAction SilentlyContinue -ErrorAction Stop > $null;
write-host "Selected Subscription..." -ForegroundColor Green;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Credentials to connect to SQL Azure database (using sql account and password).
# Store password as encrypted string file. 
$AzureSQLAccount = "OrkinEcommDbReader";
#$AzureSQLAccount = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLAccount.txt' | ConvertTo-SecureString;
$AzureSQLConnPass = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnPass.txt' | ConvertTo-SecureString;
$PasswordSQL = (New-Object PSCredential $AzureSQLAccount,$AzureSQLConnPass).GetNetworkCredential().Password;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Fetch Azure SQL server and database names. Execute SQL command.
$AzureServerName = "prod1811-orkin-175640-sql.database.windows.net";
#$AzureServerName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureServerName.txt' | ConvertTo-SecureString;
$AzuredBName = "prod-orkin-ecommerce";
#$AzuredBName = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzuredBName.txt' | ConvertTo-SecureString; 

# Set SQL connectivity parameters.
# sessioncomplete between (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()) - 1, 0)) and (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) and
$params = @{
    'Database' = $AzuredBName
    'ServerInstance' = $AzureServerName
    'Username' = $AzureSQLAccount
    'Password' = $PasswordSQL
    'Query' = 'select * from [dbo].[EcommerceTransaction] order by sessioncomplete DESC;'
};
#'Query' = 'select * from [dbo].[EcommerceTransaction] where firstname not like ''test%'' and lastname not like ''test%'' and emailaddress not like ''%capgemini%'' order by sessioncomplete DESC;'
write-host "Loading table Staging_EcommerceTransaction table from Azure data into management server..." -ForegroundColor Green;

# Execute command against Azure SQL server and insert into MGMT server DBA database into table [dbo].[Staging_EcommerceTransaction].
$Results = invoke-sqlcmd @params -AbortOnError -As DataTables;
Write-SqlTableData -ServerInstance RWSQLMGMTH202 -DatabaseName DBA -SchemaName dbo -TableName Staging_EcommerceTransaction -InputData $Results;

DisConnect-AzureRmAccount > $null;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Connect to BOSS production Replica2, execute SQL query for tWebCommerceBasket and store results in MGMT server DBA database into table DBA.DBO.Staging_tWebCommerceBasket.
write-host "Loading table Staging_tWebCommerceBasket table from Replica2 data into management server..." -ForegroundColor Green;
$Results = invoke-sqlcmd -ServerInstance RWBDBAGH203\MOBILE01 -Database prodServSuiteData -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Select_tWebCommerceBasket.sql" -As DataTables;
Write-SqlTableData -ServerInstance RWSQLMGMTH202 -DatabaseName DBA -SchemaName dbo -TableName Staging_tWebCommerceBasket -InputData $Results;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute command on MGMT server DBA database join Staging_EcommerceTransaction] & Staging_tWebCommerceBasket and export to CSV file.
write-host "Generate ecommercedata from management server staging tables ..." -ForegroundColor Green;
$TableAz = invoke-sqlcmd -ServerInstance RWSQLMGMTH202 -Database DBA -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\ecomm_sales.sql" -As DataTables;
$TableAz | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm1.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Connect to BOSS production Replica2, execute SQL query and store results in Excel file. Windows Authentication used when user and password not supplied.
write-host "Executing eCommerce leads query from Replica2 data .... " -ForegroundColor Green;
$TableR2 = Invoke-Sqlcmd -InputFile "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\ecomm_leads.sql" -ServerInstance RWBDBAGH203\MOBILE01 -Database prodServSuiteData -AbortOnError;
$TableR2 | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm2.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Merge Excel .CSV files - sales: eComm1.csv & leads: eComm2.csv into eComm_data.xlsx. 
# Rename each worksheet as Sales and Leads in file eComm_data.xlsx.
# File names eComm1 and eComm2 is named due to sorting requirement when merging the two files.
# Remove file if it exists.
write-host "Merge sales and leads csv files into one excel file .... " -ForegroundColor Green;
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
$objRange = $Workbook.Sheets.Item("Leads").Range("R1").EntireColumn;
$objRange.WrapText = $False;
$Workbook.Worksheets.Item(1).Activate();
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
