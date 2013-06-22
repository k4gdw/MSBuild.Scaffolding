1. How to run build script?
Build script could be run using msbuild console
application. The simplest way to call it is  by
using Visual Studio command prompt.

ex. "msbuild [YourSolutionName].proj".

(The actual file name could be seen in the "Build" solution folder)

2. Build Targets
Default build script target set to Build. So in most cases on build server you'll want to run Publish target. It could easily done by specifying /t:Publish argument.
ex. "msbuild [YourSolutionName].proj /t:Publish"

3. Assembly version
Build Number and Revision could be passed to build script using BuildNumber & RevisionNumber arguments.
ex. "msbuild [YourSolutionName].proj /t:Publish /p:BuildNumber=1 /p:RevisionNumber=101"