# Epinova DXC Extensions
Bucket of release tasks helping you to deploy to all environments in Episerver DXC from Azure DevOps. The release tasks use the [Deployment API](https://world.episerver.com/digital-experience-cloud-service/deploying/episerver-digital-experience-cloud-deployment-api/). There are some developers out there that want/need help with deployment to the Episerver DXC enviroment. And that is why this extension is created. 
  
## Tasks ##

### Deploy nuget package (Episerver DXC) ###  
Take a nuget package from your drop folder in Azure DevOps and upload it to your Episerver DXC project and start a deployment to the specified environment. 
[Documentation](documentation/DeployNugetPackage.md)  
  
### Deploy To (Episerver DXC) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.
[Documentation](documentation/DeployTo.md)  

### Complete deploy (Episerver DXC) ###
Both "Deploy nuget package (Episerver DXC)" and "Move deploy (Episerver DXC)" tasks deploy a packe to a environment. That will deploy the package to a slot. The task "Complete deploy (Episerver DXC)" will complete the deploy and move the packe from slot to the real environment.
[Documentation](documentation/CompleteDeploy.md)

### Smoke and reset (Episerver DXC) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK). 
[Documentation](documentation/SmokeAndReset.md)

### Reset deploy (Episerver DXC) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification". 
[Documentation](documentation/ResetDeploy.md)