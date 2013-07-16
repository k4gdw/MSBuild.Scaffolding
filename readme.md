MSBuild.Scaffolding
===================

[Powershell][1]  package  that  adds  basic  MSBuild script and required
infrastructure to your solution.

Features
--------
*	Creates basic build script that could be used in CI or DEV builds.
*	Updates `SharedAssemblyInfo.cs` or  `SharedAssemblyInfo.vb`  by  the
	proper  build  and  revision  number  during  each  build  (by using
	MSBuildCommunity tasks)
*	`Enable-Versioning`  cmdlet  allows  to  easily  configure  solution  
	projects to use `SharedAssemblyInfo.cs`/`SharedAssemblyInfo.vb`.

### How to install it and configure solution? ###
![Solution Configuration using Package Manager Console][2]

### How solution looks like after `Enable-Versioning` ###
![Solution Explorer with MSBuild.Scaffolding installed][3]

### How to run Build Script? ###
`msbuild {BUILD_SCRIPT_NAME}.proj /p:BuildNumber=1 /:RevisionNumber=22
	/t:publish`

### Enable-Versioning explained ###
*	In Visual Studio please open Package Manager Console
*	Type `Enable-Versioning` and hit Enter - all  the  projects  in  the
	solution   will   be   configured   to   use   version   from    the
	`SharedAssemblyInfo.cs` or `SharedAssemblyInfo.vb`
*	Type  `Enable-Versioning  {PROJECT_NAME}`  and  hit  Enter  -   only
	specified project  will  be  configured  to  use  version  from  the
	`SharedAssemblyInfo.cs` or `SharedAssemblyInfo.vb`

Notes
-----
Please note that this package is the solution level package. It will  be
added to the solution itself.  It  won't  be  downloaded  by  the  NuGet
Package Restore feature. Hence all the needed files are being added into
Build folder. In order to use Enable-Versioning cmdlet package should be
installed.

Copyright
---------
Copyright © 2012 Michael Ayvazyan, 2013 Bryan Johns / K4GDW Consulting

License
-------
This project is licensed under [MIT][4].  Refer to [license.txt][5] for
more information.

[1]:	http://is.gd/sk2UtP "Read more about Windows PowerShell"
[2]:	http://is.gd/eYjLOk "Solution Configuration"
[3]:	http://is.gd/V6OKio "Solution Explorer"
[4]:	http://is.gd/bGhlDg "Read more about the MIT license form"
[5]:	http://is.gd/RpoC54 "License"