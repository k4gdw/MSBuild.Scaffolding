# Copyright (c) Microsoft Corporation.  All rights reserved.

$knownExceptions = @(
)


<#
.SYNOPSIS
	Configures project to use SharedAssemblyInfo.

.DESCRIPTION
	Adds reference to .\Build\SharedAssemblyInfo.cs/vb and removes version related attributes from the AssemblyInfo.cs/vb.

.PARAMETER ProjectName
    Specifies the project that should be configured. If omitted, all the supported projects will be updated.
#>

function FileExt($project) {
	if ($project.Type -eq "C#") {
		# Visual C#
		return ".cs"
	}
	# Visual Basic
	if ($project.Type -eq "VB.NET") {
		# Visual Basic
		return ".vb"
	}
}

function IsConfigured($project) {	
	$fileExt = FileExt $project
	$fileName = "SharedAssemblyInfo" + $fileExt 
	foreach($file in $project.ProjectItems) {				
		if ($file.Name -eq $fileName) {
			return $true
		}
	}
	return $false;
}

function ConfigureProject($project) {
	if (IsConfigured $project) {
		return
	}		
	Write-Host Configuring $project.Name
	
	# Add SharedAssemblyInfo
	$fileExt = FileExt $project
	if (!($global:sharedAssemblyInfoPath.EndsWith($fileExt))){
		$global:sharedAssemblyInfoPath = $global:sharedAssemblyInfoPath + $fileExt
	}
	$project.ProjectItems.AddFromFile($global:sharedAssemblyInfoPath) | Out-Null		

	# Update Assembly Info
	$projectDirectoryName = [System.IO.Path]::GetDirectoryName($project.FullName)
	if ($project.Type -eq "VB.NET") {
		$assemblyInfoPath = Join-Path $projectDirectoryName "My Project\AssemblyInfo.vb"
		if ($global:IsTfsInstalled) { 
			TfsCheckedOut $assemblyInfoPath
		}
		(Get-Content $assemblyInfoPath) | Foreach-Object {			
			$_ -replace "\<Assembly\: AssemblyCompany\(","'<Assembly: AssemblyCompany(" `
			   -replace "\<Assembly\: AssemblyCopyright\(","'<Assembly: AssemblyCopyright(" `
			   -replace "\<Assembly\: AssemblyTrademark\(","'<Assembly: AssemblyTrademark(" `
			   -replace "\<Assembly\: AssemblyVersion\(", "'<Assembly: AssemblyVersion(" `
			   -replace "\<Assembly\: AssemblyFileVersion\(","'<Assembly: AssemblyFileVersion(" `
			   -replace "\<Assembly\: AssemblyInformationalVersion\(","'<Assembly: AssemblyInformationalVersion("
		} | Out-File -Encoding UTF8 $assemblyInfoPath
	}
	if ($project.Type -eq "C#") {
		$assemblyInfoPath = Join-Path $projectDirectoryName "Properties\AssemblyInfo.cs"
		if ($global:IsTfsInstalled) { 
			TfsCheckedOut $assemblyInfoPath
		}
		(Get-Content $assemblyInfoPath) | Foreach-Object {			
			$_ -replace '\[assembly\: AssemblyCompany\(','//[assembly: AssemblyCompany(' `
			   -replace '\[assembly\: AssemblyCopyright\(','//[assembly: AssemblyCopyright(' `
			   -replace '\[assembly\: AssemblyTrademark\(','//[assembly: AssemblyTrademark(' `
			   -replace '\[assembly\: AssemblyVersion\(', '//[assembly: AssemblyVersion(' `
			   -replace '\[assembly\: AssemblyFileVersion\(','//[assembly: AssemblyFileVersion(' `
			   -replace '\[assembly\: AssemblyInformationalVersion\(','//[assembly: AssemblyInformationalVersion(' 
		} | Out-File -Encoding UTF8 $assemblyInfoPath
	}
}

function ProcessProject($project, $projectToConfigure) {
	$kind = $project.Kind.ToString() # http://msdn.microsoft.com/en-us/library/hb23x61k(v=vs.80).aspx
	if ($kind -eq "{66A26720-8FB5-11D2-AA7E-00C04F688DDE}") {
		# Solution Folder
		foreach ($p in $project.ProjectItems) {
			if ($p.SubProject) {
				ProcessProject $p.SubProject $projectToConfigure
			}
		}
	} else {	
		if (!($projectToConfigure -eq "" -or $projectToConfigure -eq $project.Name))		{
			return
		}
		if ($kind -eq "{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}" -or $kind -eq "{F184B08F-C81C-45F6-A57F-5ABD9991F28F}") {
			# Visual C# or Visual Basic
			ConfigureProject $project
		} else { 
			# unsupported project type
			Write-Host 'Project Ignored $project.Name - project type isn''t supported'
		}
	}		
}

# Thanks to Jason Stangroome http://blog.codeassassin.com/2010/08/11/automatic-tfs-check-out-for-powershell-ise/
function TfsCheckedOut ([string]$Path, [switch]$Force) {
    if (-not $Force -and -not (Get-Item -Path $Path).IsReadOnly) { return }
    $WorkstationType = [Microsoft.TeamFoundation.VersionControl.Client.Workstation]
    if (-not $WorkstationType::Current.IsMapped($Path)) { return }
    $WorkspaceInfo = $WorkstationType::Current.GetLocalWorkspaceInfo($Path)
    $Collection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($WorkspaceInfo.ServerUri)
    $Collection.EnsureAuthenticated()
    $Workspace = $WorkspaceInfo.GetWorkspace($Collection)
    $Workspace.PendEdit($Path) | Out-Null
}

function Enable-Versioning {
	[CmdletBinding()] 
    param (
        [string] $ProjectName
    )
	$fileExt = FileExt $project
	$fileName = "SharedAssemblyInfo" + $fileExt
	$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
	$solutionDirectoryName = [System.IO.Path]::GetDirectoryName($solution.FileName)
	$solutionDirectoryName = $solutionDirectoryName + "/.build"
	$global:sharedAssemblyInfoPath = (Join-Path $solutionDirectoryName $fileName)
	
	foreach($project in $solution.Projects) {
		if ($ProjectName -eq "") {
			$ProjectName = $project.Name
		}
		ProcessProject $project $ProjectName
	}	
}

$global:sharedAssemblyInfoPath = ""

$global:IsTfsInstalled = $false
try {
    [Reflection.Assembly]::Load('Microsoft.TeamFoundation.VersionControl.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') | Out-Null
    $global:IsTfsInstalled = $true
} catch {
    try {
        [Reflection.Assembly]::Load('Microsoft.TeamFoundation.VersionControl.Client, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') | Out-Null
        $global:IsTfsInstalled = $true
    } catch {        
    }
}

Export-ModuleMember @( 'Enable-Versioning')