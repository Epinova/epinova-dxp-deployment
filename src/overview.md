# Epinova Optimizely DXP API Azure DevOps deplyment tasks

Tasks

1. **Deploy NuGet package**
1. **Deploy To**
1. **Deploy Smooth To**
1. **Content copy**
1. **Smoke test if fail reset**
1. **Complete deploy**
1. **Reset deploy**
1. **Export DB**
1. **Await status**

## Details

### Deploy nuget package (Optimizely DXP) ###  
Take a NuGet package from your drop folder in Azure DevOps and upload it to your Optimizely (formerly known as Episerver) DXP project and start a deployment to the specified environment.  
Support DirectDeploy and Smooth deployment (Zero downtime deployment).     
Buildt in warm up function exist so that you can warm up your web application after direct deploy when warm up is not done by the DXP environment automatically.
  
### Deploy To (Optimizely DXP) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  
Can also be used for Content syncdown. With the IncludeBlob and IncludeDb you can now sync/deploy both ways.  
Support Smooth deployment (Zero downtime deployment).  

### Deploy Smooth To (Optimizely DXP) ###
<span style="color:red">Deprecated! You should stop using this task DeploySmoothTo. You should change to DeployTo.</span>
Do the same thing as the "Deploy to" task. But this has support for Smooth deployment (Zero downtime deployment).  
Since this function is still in [closed beta](https://world.optimizely.com/service-and-product-lifecycles/#CloudServicesLifecycle). There is not everybody that can use this feature yet. That is why this is like a copy past of the "Deploy To" task but with smooth deployment support.  
When this feature is public for all DXP users, we will implement this feature on the "Deploy to" task.  

### Content copy (Optimizely DXP) ###
Copy database and/or blobs between your environments.

### Complete deploy (Optimizely DXP) ###
Both "Deploy nuget package (Optimizely DXP)" and "Move deploy (Optimizely DXP)" tasks deploy a packe to a environment. That will deploy the package to a slot. The task "Complete deploy (Optimizely DXP)" will complete the deploy and move the packe from slot to the real environment.  

### Smoke test if fail reset (Optimizely DXP) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  

### Reset deploy (Optimizely DXP) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification".  

### Export DB (Optimizely DXP) ###
Export database as a bacpac file from specified environment.  

### Await status (Optimizely DXP) ###
Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that verify correct status. If status is AwaitingVerification/Reset/Succeeded, nothing will happen.  

### Expect status (Optimizely DXP) ###
Task that check the status for an environment. if environment is not in the expected status the task will fail.  

## Documentation
Repository and documentation can be found at GitHub.
[https://github.com/Epinova/epinova-dxp-deployment](https://github.com/Epinova/epinova-dxp-deployment)