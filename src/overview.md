# Episerver DXP API Azure DevOps deplyment tasks

Tasks

1. **Deploy nuget package**
1. **Deploy To**
1. **Smoke test if fail reset**
1. **Complete deploy**
1. **Reset deploy**
1. **Export DB**
1. **Await status**

## Details

### Deploy nuget package (Episerver DXP) ###  
Take a NuGet package from your drop folder in Azure DevOps and upload it to your Episerver DXP project and start a deployment to the specified environment.  
  
### Deploy To (Episerver DXP) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  
Can also be used for Content syncdown.  With the IncludeBlob and IncludeDb you can now sync/deploy both ways.  

### Complete deploy (Episerver DXP) ###
Both "Deploy nuget package (Episerver DXP)" and "Move deploy (Episerver DXP)" tasks deploy a packe to a environment. That will deploy the package to a slot. The task "Complete deploy (Episerver DXP)" will complete the deploy and move the packe from slot to the real environment.  

### Smoke test if fail reset (Episerver DXP) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  

### Reset deploy (Episerver DXP) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification".  

### Export DB (Episerver DXP) ###
Export database as a bacpac file from specified environment.  

### Await status (Episerver DXP) ###
Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that verify correct status. If status is AwaitingVerification/Reset/Succeeded, nothing will happen.  

### Expect status (Episerver DXP) ###
Task that check the status for an environment. if environment is not in the expected status the task will fail.  

## Documentation
Repository and documentation can be found at GitHub.
[https://github.com/Epinova/epinova-dxp-deployment](https://github.com/Epinova/epinova-dxp-deployment)