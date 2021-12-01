import-module dbatools
cd C:\PowerSh\Rollins
Find-DbaInstance -DiscoveryType DomainServer -ScanType All | Export-Csv -Path .\SQLServerList.csv
#Out-file -FilePath 'C:\Users\richard.cheatham\Documents\SQL Server Management Studio\SQLServerList.txt'

install-module dbatools -scope AllUsers

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module dbatools

Find-DbaInstance -DiscoveryType DomainServer -ScanType All | Out-gridview


