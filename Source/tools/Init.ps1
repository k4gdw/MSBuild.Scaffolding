param($installPath, $toolsPath, $package, $project)

function AddItem($fileName, BuildFolder, BuildItems) {
	Copy-Item (Join-Path $toolsPath $fileName) BuildFolder | Out-Null
	BuildItems.AddFromFile((Join-Path BuildFolder $fileName))
}

function UpdateSolution($solution)
{
	# Get the solution name
	$solutionName = [System.IO.Path]::GetFileNameWithoutExtension($solution.FileName)
	$solutionDirectoryName = [System.IO.Path]::GetDirectoryName($solution.FileName)

	BuildFolder = (Join-Path $solutionDirectoryName "Build")	
	if (Test-Path BuildFolder){
		return $false; # already installed
	}

	# Create Build solution folder
	mkdir BuildFolder | Out-Null
	BuildProject = $solution.AddSolutionFolder("Build")
	BuildItems = Get-Interface BuildProject.ProjectItems ([EnvDTE.ProjectItems])
		
	# Add Build script
	BuildScriptPath = (Join-Path $solutionDirectoryName "$solutionName.proj");
	$mBuildScript = Get-Content "$toolsPath\mBuild.proj" | Foreach-Object {$_ -replace "YOUR_SOLUTION_NAME", $solutionName}
	Set-Content -Value $mBuildScript -Path BuildScriptPath
	BuildItems.AddFromFile(BuildScriptPath)

	# Add some infrastructure
	AddItem "MSBuild.Community.Tasks.dll" BuildFolder BuildItems
	AddItem "MSBuild.Community.Tasks.xsd" BuildFolder BuildItems
	AddItem "MSBuild.Community.Tasks.Targets" BuildFolder BuildItems
	AddItem "SharedAssemblyInfo.vb" BuildFolder BuildItems
	AddItem "SharedAssemblyInfo.cs" BuildFolder BuildItems
	AddItem "ReadMe.md" BuildFolder BuildItems
	AddItem "_BuildInfo.xml" BuildFolder BuildItems

	return $true;	
}

function ImportPowershellModule() {

	if ($PSVersionTable.PSVersion -ge (New-Object Version @( 3, 0 )))
	{
		$thisModuleManifest = 'MSBuild.Scaffolding.PS3.psd1'
	}
	else
	{
		$thisModuleManifest = 'MSBuild.Scaffolding.psd1'
	}
	
	$thisModule = Test-ModuleManifest (Join-Path $toolsPath $thisModuleManifest)	
	$name = $thisModule.Name
	
	$importedModule = Get-Module | ?{ $_.Name -eq $name }
	if ($importedModule)
	{
		if ($false -and $importedModule.Version -eq $thisModule.Version) 
		{
			return			
		}
		else 
		{
			Remove-Module $name			
		}    
	}
	Import-Module -Force -Global $thisModule
}

# Get the open solution.
$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])

if (UpdateSolution $solution)
{
	Write-Host "Solution was prepared. Please run Enable-Versioning to configure projects to use SharedAssemblyInfo.cs"
}
else
{
	Write-Host "Build folder already exists... Please remove or rename it and then reinstall the package."
}

ImportPowershellModule
