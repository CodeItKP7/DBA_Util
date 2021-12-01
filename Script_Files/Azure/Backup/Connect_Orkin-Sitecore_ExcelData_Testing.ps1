cls;
# Connect to Azure Portal (using email credentials). 
# Store password as encrypted string file. 
# Create a new credential object.
write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
$AzureAccount = "ssubrahm@rollins.com";
$password = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnCred.txt' | ConvertTo-SecureString;
#[ValidateNotNullOrEmpty()] $secureStringPwd = "Mayhs99a21"
#$secureStringPwd = $secureStringPwd|ConvertTo-SecureString -AsPlainText -Force;
($Credential_AZ = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureAccount, $secureStringPwd);

write-host "Connecting to Azure Portal: " $Credential_AZ "-" $AzureAccount -ForegroundColor Green;
Connect-AzureRmAccount -Credential $Credential_AZ -Tenantid 08269009-94b5-4924-8377-7e84dddfa998  -ErrorAction Stop > $null;
Select-AzureRMSubscription -Tenant 08269009-94b5-4924-8377-7e84dddfa998  -ErrorAction Stop > $null;
write-host "Selected Subscription...";
#Get-AzureRmSqlServer -ServerName prod1811-orkin-175640-sql -ResourceGroupName prod1811-orkin

#DisConnect-AzureRmAccount > $null;
#Add-AzureRmAccount -Credential $Credential_AZ -Subscription Orkin-Sitecore -ErrorAction Stop > $null;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Credentials to connect to SQL Azure database (using sql account and password).
# Store password as encrypted string file. 
$AzureSQLAccount = "OrkinEcommDbReader";
$SecurepasswordSQL = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnCred.txt' | ConvertTo-SecureString;
$PasswordSQL = (New-Object PSCredential $AzureSQLAccount,$SecurepasswordSQL).GetNetworkCredential().Password;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Fetch Azure SQL server and database names.
$vPath = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure";
Set-Location $vPath;
$ServerName = Get-AzureRmSqlServer -ServerName prod1811-orkin-175640-sql -ResourceGroupName orkin-prod-ecomm | where {$_.ServerName -eq 'prod1811-orkin-175640-sql'} | select FullyQualifiedDomainName -ExpandProperty FullyQualifiedDomainName;
$ServerInstance = $ServerName ;#+ '.database.windows.net';
write-host "Connecting to Azure SQL Server: " $ServerInstance -ForegroundColor Yellow;
$dBName = Get-AzureRmSqlDatabase -ServerName $ServerName -ResourceGroupName prod1811-orkin | select databasename -ExpandProperty databasename | where {$_.databasename -eq 'prod-orkin-ecommerce'};
write-host "Connecting to Azure SQL Database: " $dBName -ForegroundColor Cyan;

# Set SQL connectivity parameters.
# sessioncomplete between (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()) - 1, 0)) and (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) and
$params = @{
    'Database' = $dBName
    'ServerInstance' = $ServerInstance
    'Username' = $AzureSQLAccount
    'Password' = $passwordSQL
    #'Query' = 'select ReferenceId,FirstName,LastName,PhoneNumber,EmailAddress,EmailOptIn,BillingStreetNumber,BillingStreetName,BillingCity,BillingState,BillingZipCode,BillingFullAddress,ServiceStreetNumber,ServiceStreetName,ServiceCity,ServiceState,ServiceZipCode,ServiceFullAddress,Acreage,AcreageDescription,CallToSchedule,BillingSameAsService,BillingFirstName,BillingLastName,LastStep,AppointmentDate,AppointmentTime,TransactionResponse,TransactionToken,ServiceName,ServiceType,BasePrice,SalesTax,Subtotal,TotalDueToday,IsPropertyOwner,CampaignCode,UserAgent,AcceptTermsAndConditions,Querystring,SessionStart,SessionComplete from [dbo].[EcommerceTransaction] where firstname not like ''test%'' and lastname not like ''test%'' and emailaddress not like ''%liquidhub%'' order by sessioncomplete DESC;'
    'Query' = 'select * from [dbo].[EcommerceTransaction] where firstname not like ''test%'' and lastname not like ''test%'' and emailaddress not like ''%liquidhub%'' order by sessioncomplete DESC;'
};
write-host "Executing SQL command.... " -ForegroundColor Green;

# Execute command and export to CSV file.
$Tables = Invoke-Sqlcmd @params;
$Tables | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eCommTest2.csv" -NoTypeInformation -UseCulture -force;

DisConnect-AzureRmAccount > $null;
