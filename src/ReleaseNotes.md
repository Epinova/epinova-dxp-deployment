# Release notes

## v2.1.10
- Handle exception "A package named '$BlobName' is already linked to a deployment and cannot be overwritten." from Linux environment. Do not handle it as error.

## v2.1.9
- Treat......

## v2.1.8
- Support EpiCloud v1.

## v2.0.3
- Fix #176. Support Linux multiple package uploads.

## v2.0.2
- Fix #173. DeployNuGetPackage and DeployTo: Updated v1 and v2 tasks to handle param ZeroDowntimeMode = Not specified.

## v2.0.0
- All tasks are updated to v2 and have cross platform (Windows/Ubuntu/MacOS) support.

## v1.14.1
- Added SuppressAzureRmModulesRetiringWarning.

## v1.14.0
- Added 'Succeeded or Reset' option in Expected status.

## v1.13.3-v1.13.4
- Solve issue with Get-DxpLatestEnvironmentDeployment Count error.

## v1.13.2
- Add logic to not install modules when exist on agent.

## v1.13.0-v1.13.1
- Import Azure.Storage with MinVersion 4.4.0 to remove warning.

## v1.12.0
- Added ZeroDowntime into DeployNuGetPackage task.

## v1.11.5
- Added ZeroDowntime into DeployTo. Added a warning to DeploySmoothTo that is deprecated. 

## v1.11.4
- Install latest Azure.Storage.

## v1.11.1-1.11.3
- SmokeTestIfFailReset: New prop 'Reset on fail' describes if reset will be made or not when smoke test fails.

## v1.10.24-1.10.30
- Fix SmokeTestIfFailReset bug with response error when request fails.

## v1.10.23
- Polish the script that gets the latest deployment for a specific environment.

## v1.10.11-1.10.22
- Print out EpiCloud version in tasks.

## v1.10.10
- Fixed bug with SetVariable DeploymentId in DeployNuGetPackage task.
- Fixed bug with SetVariable DeploymentId in DeployTo task.

## v1.10.9
- Fixed ExpectedStatus bug in DeployNuGetPackage regarding support for DirectDeploy.

## v1.10.8
- Handle status Failed in progress function.

## v1.10.2-1.10.7
- Fixed ExpectedStatus bug in DeployNuGetPackage regarding support for DirectDeploy.

## v1.10.1
- DeployNuGetPackage: Added  support for DirectDeploy.

## v1.9.43
- Fix for #120 DeployNuGetPackage task is not working for commerce. (##[error]The variable '$resolvedCmsPackagePath' cannot be retrieved because it has not been set.)

## v1.9.33 - v1.9.42
- Start using EpinovaDxpDeploymentUtil.ps1 script. Problem with authentication in custom module.
- Test using splat on function calls.
- Centralize EpiCloud module. Deploy with script during build to ps_modules folder(s).
- Centralize EpinovaDxpDeploymentUtil script. Deploy with script during build to ps_modules folder(s).
- Centralize VstsTaskSdk module. Deploy with script during build to ps_modules folder(s).
- Create one CopyScripts build script. That handle all the scripts and modules that should be copied during build.
- Fixed bug in SmokeTestIfFailReset regarding $deploymentId

## v1.9.19 - v1.9.32
- Added EpinovaDxpDeploymentUtil module to verify local PSModules.  
- Build script that move modules auto to ps_modules folders in tasks.  
- Fixed some result texts.

## v1.9.18
- Added SecurityProtocol Tls12 to all tasks  

## v1.9.13, - v1.9.17
- Added EpinovaDxpDeploymentUtil module to verify local PSModules.  

## v1.9.12
- Added ps_module to PSModulePath in all tasks.  

## v1.9.11
- Added EpiCloud in the ps_modules.  

## v1.9.10
- Added detailed description [how to setup content harmonization with YAML/Classic mode](documentation/ContentHarmonization.md) .

## v1.9.9
- Set ContentCopy params IncludeBlob and IncludeDb as default `true`.

## v1.9.8
- Fixed ContentCopy script bug.

## v1.9.0
- Implemented "Content copy" task.  

## v1.8.0
- #61: Implement "Deploy smooth to" task.

## v1.7.1
- #58: Added CurrentStatus in error/warning text when something goes wrong/timeout.

## v1.7.0
- #55: Add task "ExpectStatus".

## v1.6.1, v1.6.2
- #48: Fixed guid in AwaitStatus task and vss-extension.json.

## v1.6.0
- #48: Add task "AwaitStatus".

## v1.5.1
- Small documentation updates.

## v1.5
- #44: SmokeTestIfFailReset: Add function to retry URL checks for specified number of times. This will help when it takes time for the application to start up on the slot example.

## v1.4
- #26: DeployTo: Fix problem with using SourceApp = 'cms,commerce'.  
- #45: Show start and end DateTime when run DeployNuGetPackage, DeployTo, CompleteDeploy, ExportDb, ResetDeploy.

## v1.3
- #36: ExportDb: Added new task ExportDb.  

## v1.2
- #34: DeployTo: Add support for IncludeBlob and IncludeDb in the task.  

## v1.1.4
- #23, #30: DeployNugetPackage: Bugfix. Code does not get to the extra debug info.  
  
## v1.1.3
- #23, #30: DeployNugetPackage: Bugfix. Spec char error.  

## v1.1.2
- #23, #30: DeployNugetPackage: Added more debug info when no nupkg found.  

## v1.1.1
- #23: DeployNugetPackage: Added support for upload both cms and commerce at the same time. "cms,commerce".  

## v1.1.0
- #23: DeployNugetPackage: Added support for upload of specified SourceApp. You can now run DeployNugetPackage twice to upload cms and commerce package.  

## v1.0.9
- #26: Removed the space between "cms,commerce" (the actual value and not just the title) 

## v1.0.8
- #24: Removed the space between "cms,commerce"