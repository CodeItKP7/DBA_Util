cls;
# Connect to Azure Portal (using SQL credentials). Pass into array called by Invoke-SQLcmd command.
# SQL account and password not encrypted (visible).
write-host "Start time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
$params = @{
      'Database' = 'prod-orkin-ecommerce'
      'ServerInstance' = 'prod1811-orkin-175640-sql.database.windows.net'
      'Username' = 'OrkinEcommDbReader'
      'Password' = 'cZVHZ=2^H&+ma9fH'
      'OutputSqlErrors' = $true
      'Query' = 'select * from [dbo].[EcommerceTransaction] where firstname not like ''test%'' and lastname not like ''test%'' and emailaddress not like ''%liquidhub%'' order by sessioncomplete DESC;'
}

write-host "Executing SQL command.... " -ForegroundColor Green;

# Execute command and export to CSV file.
$Tables = Invoke-Sqlcmd @params;
$Tables | Export-Csv "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm.csv" -NoTypeInformation -UseCulture -force;

<#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Send email including attachment.
C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\Send_Email "C:\PowerSh\Rollins\DBA_Admin\Script_Files\Azure\eComm.csv" "eCommerce Data";
write-host "Email Sent .... "-ForegroundColor Yellow;
write-host "End time: " (Get-Date -Format g).ToString() -ForegroundColor Yellow;
