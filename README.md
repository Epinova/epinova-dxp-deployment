# Epinova DXP Deployment
Bucket of release tasks helping you to deploy to all environments in Episerver DXP from Azure DevOps. The release tasks use the [Deployment API](https://world.episerver.com/digital-experience-cloud-service/deploying/episerver-digital-experience-cloud-deployment-api/). There are some developers out there that want/need help with deployment to the Episerver DXC enviroment. And that is why this deployment extension is created. 
  
  
***NOTE: There is only support for CMS deployment at the moment. We will look into the Commerce support ASAP.***
  
## Tasks ##

### Deploy NuGet package (Episerver DXP) ###  
Take a NuGet package from your drop folder in Azure DevOps and upload it to your Episerver DXP project and start a deployment to the specified environment.  
[Deploy NuGet package documentation](documentation/DeployNugetPackage.md)  
  
### Deploy To (Episerver DXP) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  
[Deploy to documentation](documentation/DeployTo.md)  

### Complete deploy (Episerver DXP) ###
Both "Deploy nuget package (Episerver DXP)" and "Move deploy (Episerver DXP)" tasks deploy a packe to a environment. That will deploy the package to a slot. The task "Complete deploy (Episerver DXP)" will complete the deploy and move the packe from slot to the real environment.  
[Complete deploy documentation](documentation/CompleteDeploy.md)

### Smoke test if fail reset (Episerver DXP) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  
[Smoke test if fail reset documentation](documentation/SmokeTestIfFailReset.md)

### Reset deploy (Episerver DXP) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification".  
[Reset deploy documentation](documentation/ResetDeploy.md)

## Setup scenarios ##
More detailed description how you can setup and use these tasks in different scenarios. Both with YAML and manual setup.  
[Setup senarios](documentation/SetupSenarios.md)
  
## Problems ##
A collection of problems that has been found and how to fix it.  
[Problems](documentation/Problems.md)