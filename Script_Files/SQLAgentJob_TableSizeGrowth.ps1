
$vPath = "C:\Powersh\Rollins\DBA_Admin"
Set-Location $vPath
$vFullPath = join-path $vPath "Output_Files\SQLAgentTableSizeGrowthDaily.xlsx"
if (Test-Path $vFullPath) { Remove-Item $vFullPath}

# Query to execute
$cmd_PrStat = "  " + `
              "  " + `
              "  " + `
              "  " + `
              "  " + `
              "  " 
              ;

# Function to populate data from SQL Server
function Get-DataTable-DS([string]$pSQL)
{
	$dataSet= new-object "System.Data.DataSet" "DS";
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($pSQL, $ProdConn);
	$da.Fill($dataSet) | Out-Null;
	return $dataSet.Tables[0];
}


$intRow = 1
$vRetDataTable = new-object "System.Data.DataTable" "DS1"
foreach ($vSvr in gc "Prod_Servers_BOSS_Live.txt")
{
     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null;
     [System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.SmoExtended”) | out-null;
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $vSvr;






$intRow ++
}

[gc]::Collect();
[gc]::WaitForPendingFinalizers();

cls;