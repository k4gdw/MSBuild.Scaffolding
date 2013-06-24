del *.nupkg
nuget pack Package.nuspec

REM deploy to my local NuGet repository
copy *.nupkg z:\