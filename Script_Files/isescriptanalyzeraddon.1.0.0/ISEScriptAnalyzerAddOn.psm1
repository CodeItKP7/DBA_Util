#requires -Version 3

if ($host.Name -ne "Windows PowerShell ISE Host")
{
    Write-Warning "This module does only run inside PowerShell ISE"
    return
}

$Dependency="PSScriptAnalyzer"
if (!(Get-Module $Dependency)) 
{ ## Or check for the cmdlets you need   
    ## Load it nested, and we'll automatically remove it during clean up
    Import-Module $Dependency -ErrorAction Stop
} 

#$path = Join-Path -Path $PSScriptRoot -ChildPath "ISEScriptAnalyzerAddOn.dll"
Add-Type -Path $PSScriptRoot\ISEScriptAnalyzerAddOn.dll -PassThru
$typeScriptAnalyzer = [ISEScriptAnalyzerAddOn.Views.MainView] 
$ScriptAnalyzer = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add('Script Analyzer', $typeScriptAnalyzer , $true)
$psISE.CurrentPowerShellTab.VisibleVerticalAddOnTools.SelectedAddOnTool = $ScriptAnalyzer