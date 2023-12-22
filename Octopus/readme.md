# Octopus - Epinova DXP Deployment
Step templates and documentation on how you can use and work with Epinova DXP deployment in Octopus to deploy to all environments in Optimizely (formerly known as Episerver) DXP (a.k.a DXC).  
You can implement this in many different ways. This is the way we did it in one of our projects. Note: We are working mostly with Azure DevOps so we don't have ninja skills in Octopus deploy. If you have any comments or a better solution for this setup, please contact us.

## Install 
To install Epinova DXP deployment to Octopus deploy you need to do the following steps:  
* Install 'EpiCloud' and 'EpinovaDxpToolBucket' PowerShell modules to the package feed.
* Create a variable set that holds the Optimizely Deployment API credentials.
* Create 7 step templates
* Create 3 environments
* Create 2 lifecycles
* Create project

We will now go through each step in more details.

### Install NuGet/PowerShell modules
Go to PowerShell Gallery and download the latest versions of 'EpiCloud' and 'EpinovaDxpToolBucket'.  
[https://www.powershellgallery.com/packages/EpiCloud](https://www.powershellgallery.com/packages/EpiCloud)  
[https://www.powershellgallery.com/packages/EpinovaDxpToolBucket](https://www.powershellgallery.com/packages/EpinovaDxpToolBucket)  
In Octopus, go to Library/Packages. Upload the 2 Nuget packages so that they exist in the package feed. If you want to be more advanced, you can probably set up an external feed for the packages via Library/External Feeds. However, we have not tried that, so please consult the Octopus documentation on how to use this type of setup.  
  
### Variable set
In [Optimizely DXP PAAS portal](https://paasportal.episerver.net/), you can create API key/secret for your project. These key, secret and project ID will be used by deployment script when running deployment scripts against [Optimizely Deployment API](https://docs.developers.optimizely.com/digital-experience-platform/docs/deployment-api). 
In the PAAS portal, go to your target project. Under the 'API' tab you will be able to generate new 'Deployment API Credentials'. Copy the key, secret and project ID.  
In Octopus, go to Library/Variable sets. Create a new variable set and give it a descriptive name and description. If you will have more than one DXP project in your Octopus solution, you need to add some information to the variable set name that describes which project it is related to. 
#### Variable templates
Next step is to create the variable templates in the variable set:  
##### ClientKey
**Variable name:** ClientKey  
**Label:** ClientKey  
**Help text:** The DXP API ClientKey for the current environment.  
**Control type:** Single-line text box  
##### ClientSecret
**Variable name:** ClientSecret  
**Label:** ClientSecret  
**Help text:** The DXP API ClientSecret for the current environment.  
**Control type:** Sensitive/password box  
##### ProjectId
**Variable name:** ProjectId  
**Label:** ProjectId  
**Help text:** The DXP project id.  
**Control type:** Single-line text box  
#### Add Variable values
For the each variable template, create a variable in the variable set.  
##### ClientKey
**Variable name:** ClientKey  
**Value:** [your client key copied from PAAS portal]  
##### ClientSecret
**Variable name:** ClientSecret  
**Value:** [your client secret copied from PAAS portal]  
##### ProjectId
**Variable name:** ProjectId  
**Value:** [your project ID copied from PAAS portal]  

### Step templates
The step templates is the tasks that can be used in the deploy process in project(s).  
In Octopus, go to Library/Step Templates. We can now import templates that will help you to get up and running faster then add all this information manually.  
[StepTemplates/AwaitStatus.template.json](First json)  
[StepTemplates/AwaitStatus.ps1](First ps1)  

**In short:**
Install the extension to your Azure DevOps project: [https://marketplace.visualstudio.com/items?itemName=epinova-sweden.epinova-dxp-deploy-extension](https://marketplace.visualstudio.com/items?itemName=epinova-sweden.epinova-dxp-deploy-extension). Click on the green "Get it free" button and follow the instructions.  
Microsoft has general information on how to install an Azure DevOps extension:  [https://docs.microsoft.com/en-us/azure/devops/marketplace/install-extension](https://docs.microsoft.com/en-us/azure/devops/marketplace/install-extension)  
In the end of that page, there also a link to how to manage extension permission. [https://docs.microsoft.com/en-us/azure/devops/marketplace/how-to/grant-permissions](https://docs.microsoft.com/en-us/azure/devops/marketplace/how-to/grant-permissions)  

## Tasks ##

### Deploy NuGet package (Optimizely DXP) ###  
Take a NuGet package from your drop folder in Azure DevOps and upload it to your Optimizely (formerly known as Episerver) DXP project and start a deployment to the specified environment.  
[Deploy NuGet package documentation](documentation/DeployNugetPackage.md)  
  
### Deploy To (Optimizely DXP) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  
Can also be used for Content copy during deployment. With the IncludeBlob and IncludeDb you can now sync/deploy both ways.  
Also support Zero Downtime Deployment (aka ZDD or Smooth deployment).  
[Deploy to documentation](documentation/DeployTo.md)  

### Deploy Smooth To (Optimizely DXP) ###
<span style="color:red">_**Deprecated! You should stop using this task DeploySmoothTo. You should change to DeployTo.**_</span>  
Do the same thing as the "Deploy to" task. But this has support for Smooth deployment (Zero downtime deployment).  
This task was created during the [closed beta](https://world.optimizely.com/service-and-product-lifecycles/#CloudServicesLifecycle). There was not everybody that could use this feature. That is why this is like a copy past of the "Deploy To" task but with smooth deployment support.  
Now when this feature is public for all DXP users, it is implemented in to the "Deploy to" task.  
[Deploy smooth to documentation](documentation/DeploySmoothTo.md)  

### Content copy (Optimizely DXP) ###
Copy content database and/or blobs between your environments.  
[Content copy documentation](documentation/ContentCopy.md)  
[Example how to use Content copy](documentation/ContentHarmonization.md)  

### Complete deploy (Optimizely DXP) ###
Both "Deploy nuget package (Optimizely DXP)" and "Move deploy (Optimizely DXP)" tasks deploy a package to a environment. That will deploy the package to a slot. The task "Complete deploy (Optimizely DXP)" will complete the deploy and move the packe from slot to the real environment.  
[Complete deploy documentation](documentation/CompleteDeploy.md)

### Smoke test if fail reset (Optimizely DXP) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  
[Smoke test if fail reset documentation](documentation/SmokeTestIfFailReset.md)

### Reset deploy (Optimizely DXP) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification".  
[Reset deploy documentation](documentation/ResetDeploy.md)

### Export DB (Optimizely DXP) ###
Export database as a bacpac file from specified environment.  
[Export DB documentation](documentation/ExportDb.md)  

### Await status (Optimizely DXP) ###
Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that verify correct status. If status is AwaitingVerification/Reset/Succeeded, nothing will happen.  
[Await status documentation](documentation/AwaitStatus.md)  

### Expect status (Optimizely DXP) ###
Task that check the status for an environment. if environment is not in the expected status the task will fail.  
[Expect status documentation](documentation/ExpectStatus.md)  

## Setup scenarios ##
More detailed description how you can setup and use these tasks in different scenarios. Both with YAML and manual setup.  
[Setup senarios](documentation/SetupScenarios.md)  
[Example how to setup content harmonization between DXP environments](documentation/ContentHarmonization.md)
  
## Problems ##
A collection of problems that has been found and how to fix it.  
[Problems](documentation/Problems.md)

## Release notes ##
[Release notes](src/ReleaseNotes.md)

## Epinova.OptimizelyDxp.Pipelines Nuget - YML examples
We have set togheter a number of YML examples that you can use in your projects to fast get your project deployed to DXP.
[Epinova.OptimizelyDxp.Pipelines documentation](Pipelines_NuGet/Introduction.md)  

## Epinova.OptimizelyDxp.Pipelines Nuget

