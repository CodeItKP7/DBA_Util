<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Execute read-host command one time only. If password changes re-execute command and store credentials in encrypted file.
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnCred.txt;
# read-host -Prompt 'Enter Password' -assecurestring | convertfrom-securestring | out-file C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnCred.txt;
# $Credential = Get-Credential # this will prompt for new credentials.
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
cls;
# Connect to Azure Portal (using email credentials). 
# Store password as encrypted string file. 
# Create a new credential object.
write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;

$AzureAccount = "ssubrama@rollins.com";
#$password = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureConnCred.txt' | ConvertTo-SecureString;
$password = 'Mayhs99a16'
$Credential_AZ = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureAccount, $password;

write-host "Connecting to Azure Portal: " $Credential_AZ "-" $AzureAccount -ForegroundColor Green;
Connect-AzureRmAccount -Credential $Credential_AZ -ErrorAction Stop > $null;
write-host "Setting Subscription for session: Orkin-Sitecore" -ForegroundColor Cyan;
Select-AzureRMSubscription –SubscriptionName Orkin-Sitecore -ErrorAction Stop > $null;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Credentials to connect to SQL Azure database (using sql account and password).
# Store password as encrypted string file. 
$AzureSQLAccount = "OrkinEcommDbReader";
#$SecurepasswordSQL = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\AzureSQLConnCred.txt' | ConvertTo-SecureString;
#$PasswordSQL = (New-Object PSCredential $AzureSQLAccount,$SecurepasswordSQL).GetNetworkCredential().Password;
$PasswordSQL = 'cZVHZ=2^H&+ma9fH'
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Fetch Azure SQL server and database names.
$vPath = "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure";
Set-Location $vPath;
$ServerName = Get-AzureRmSqlServer -ResourceGroupName orkin-prod-ecomm | where {$_.ServerName -eq 'orkin-prod-ecomm-645080-sql'} | select ServerName -ExpandProperty ServerName;
$ServerInstance = $ServerName + '.database.windows.net';
write-host "Connecting to Azure SQL Server: " $ServerInstance -ForegroundColor Yellow;
$dBName = Get-AzureRmSqlDatabase -ServerName $ServerName -ResourceGroupName orkin-prod-ecomm | select databasename -ExpandProperty databasename | where {$_.databasename -eq 'orkin-prod-ecomm-645080-ecommerce-db'};
write-host "Connecting to Azure SQL Database: " $dBName -ForegroundColor Cyan;

# Set SQL connectivity parameters.
$params = @{
    'Database' = $dBName
    'ServerInstance' = $ServerInstance
    'Username' = $AzureSQLAccount
    'Password' = $passwordSQL
    'Query' = 'select ReferenceId,FirstName,LastName,PhoneNumber,EmailAddress,EmailOptIn,BillingStreetNumber,BillingStreetName,BillingCity,BillingState,BillingZipCode,BillingFullAddress,ServiceStreetNumber,ServiceStreetName,ServiceCity,ServiceState,ServiceZipCode,ServiceFullAddress,Acreage,AcreageDescription,CallToSchedule,BillingSameAsService,BillingFirstName,BillingLastName,LastStep,AppointmentDate,AppointmentTime,TransactionResponse,TransactionToken,ServiceName,ServiceType,BasePrice,SalesTax,Subtotal,TotalDueToday,IsPropertyOwner,CampaignCode,UserAgent,AcceptTermsAndConditions,Querystring,SessionStart,SessionComplete from [dbo].[EcommerceTransaction] where sessioncomplete between (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()) - 1, 0)) and (DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) and (firstname not like ''test%'' and lastname not like ''test%'') and emailaddress not like ''%liquidhub%'' order by sessioncomplete DESC;'
};
write-host "Executing SQL command.... " -ForegroundColor Green;

# Execute command and export to CSV file.
$Tables = Invoke-Sqlcmd @params;
$Tables | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Output_Files\eComm.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Send email including attachment.
#C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Send_Email "C:\PowerSh\Rollins\DBA_Admin\Output_Files\eComm.csv" "eCommerce Mosquito Data";
#write-host "Email Sent .... "-ForegroundColor Yellow;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Always Disconnect from Azure portal at end of script\session.
DisConnect-AzureRmAccount > $null;
write-host "Session Disconnected .... "-ForegroundColor Green;
write-host "End time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>


#Get-AzureRmSqlDatabase -ResourceGroupName "orkin-prod-ecomm" -ServerName "orkin-prod-ecomm-645080-sql" | where databasename -eq "orkin-prod-ecomm-645080-ecommerce-db";
# 'Query' = 'select ReferenceId,FirstName,LastName,PhoneNumber,EmailAddress,EmailOptIn,BillingStreetNumber,BillingStreetName,BillingCity,BillingState,BillingZipCode,BillingFullAddress,ServiceStreetNumber,ServiceStreetName,ServiceCity,ServiceState,ServiceZipCode,ServiceFullAddress,Acreage,AcreageDescription,CallToSchedule,BillingSameAsService,BillingFirstName,BillingLastName,LastStep,AppointmentDate,AppointmentTime,TransactionResponse,TransactionToken,ServiceName,ServiceType,BasePrice,SalesTax,Subtotal,TotalDueToday,IsPropertyOwner,CampaignCode,UserAgent,AcceptTermsAndConditions,Querystring,SessionStart,SessionComplete from [dbo].[EcommerceTransaction] where campaigncode is not null order by sessioncomplete DESC;'
# 'Query' = 'select ReferenceId,FirstName,LastName,PhoneNumber,EmailAddress,EmailOptIn,BillingStreetNumber,BillingStreetName,BillingCity,BillingState,BillingZipCode,BillingFullAddress,ServiceStreetNumber,ServiceStreetName,ServiceCity,ServiceState,ServiceZipCode,ServiceFullAddress,Acreage,AcreageDescription,CallToSchedule,BillingSameAsService,BillingFirstName,BillingLastName,LastStep,AppointmentDate,AppointmentTime,TransactionResponse,TransactionToken,ServiceName,ServiceType,BasePrice,SalesTax,Subtotal,TotalDueToday,IsPropertyOwner,CampaignCode,UserAgent,AcceptTermsAndConditions,Querystring,SessionStart,SessionComplete from [dbo].[EcommerceTransaction] order by sessioncomplete DESC;'
# 'Query' = 'select ReferenceId,FirstName,LastName,PhoneNumber,EmailAddress,EmailOptIn,BillingStreetNumber,BillingStreetName,BillingCity,BillingState,BillingZipCode,BillingFullAddress,ServiceStreetNumber,ServiceStreetName,ServiceCity,ServiceState,ServiceZipCode,ServiceFullAddress,Acreage,AcreageDescription,CallToSchedule,BillingSameAsService,BillingFirstName,BillingLastName,LastStep,AppointmentDate,AppointmentTime,TransactionResponse,TransactionToken,ServiceName,ServiceType,BasePrice,SalesTax,Subtotal,TotalDueToday,IsPropertyOwner,CampaignCode,UserAgent,AcceptTermsAndConditions,Querystring,SessionStart,SessionComplete from [dbo].[EcommerceTransaction] where sessioncomplete between '2018-04-04 12:00:00 AM' and '2018-04-04 11:59:59 PM' order by sessioncomplete DESC;'

#$Tables | Out-GridView
#$Tables[0].Rows | %{ echo $_. }
#$Tables[1] | Out-GridView
