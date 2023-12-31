# Octopus - Epinova DXP Deployment
Step templates and documentation on how you can use and work with Epinova DXP deployment in Octopus to deploy to all environments in Optimizely (formerly known as Episerver) DXP (a.k.a DXC).  
You can implement this in many different ways. This is the way we did it in one of our projects. Note: We are working mostly with Azure DevOps so we don't have ninja skills in Octopus deploy. If you have any comments or a better solution for this setup, please contact us.

## Install 
To install Epinova DXP deployment to Octopus deploy you need to do the following steps:  
* Set up your project NuGet package in the 'Packages' feed. Example: Automatic upload from TeamCity or other build server. Make sure that you follow the nameing convension from Optimizely. Tips is to only use lower case and have a name like `[Websitename].cms.app.[version].nupkg`. Example: `coolwebsite.cms.app.1.0.0.69.nupkg`  
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
#### Variable template
Next step is to create the variable template in the variable set:  
Name: `DXP deployment`  
Description: `Variables for DXP deployment`
##### ClientKey
**Variable name:** `ClientKey`  
**Label:** ClientKey  
**Help text:** The DXP API ClientKey for the current environment.  
**Control type:** Single-line text box  
##### ClientSecret
**Variable name:** `ClientSecret`  
**Label:** ClientSecret  
**Help text:** The DXP API ClientSecret for the current environment.  
**Control type:** Sensitive/password box  
##### ProjectId
**Variable name:** `ProjectId`  
**Label:** ProjectId  
**Help text:** The DXP project id.  
**Control type:** Single-line text box  
#### Add Variable values
For the each variable template, create a variable in the variable set.  
##### ClientKey
**Variable name:** `ClientKey`  
**Value:** [your client key copied from PAAS portal]  
##### ClientSecret
**Variable name:** `ClientSecret`  
**Value:** [your client secret copied from PAAS portal]  
##### ProjectId
**Variable name:** `ProjectId`  
**Value:** [your project ID copied from PAAS portal]  

### Step templates
The step templates is the tasks that can be used in the deploy process in project(s).  
In Octopus, go to Library/Step Templates. We can now import templates that will help you to get up and running faster then add all this information manually.  
For each task in the list below:
1. Import content from `[TaskName].template.json` file.
2. Click on the Step tab and copy the script from `[TaskName].ps1` and paste it into the field 'Inline source code'
3. Check that you have 2 referenced packages, `EpiCloud` and `EpinovaDxpToolBucket`. Save your changes.  
Note: `DeployNuGetPackage` task needs one extra (3:rd package). And it should be `#{sourcepackage}`. This will be specified by the project and added automatically depending on the reference to sourcepackage in the project.

Repeat the steps for all tasks that you want to use.

#### Templates
[StepTemplates/AwaitStatus.template.json](StepTemplates/AwaitStatus.template.json)  
[StepTemplates/AwaitStatus.ps1](StepTemplates/AwaitStatus.ps1)  
[StepTemplates/CompleteDeploy.template.json](StepTemplates/CompleteDeploy.template.json)  
[StepTemplates/CompleteDeploy.ps1](StepTemplates/CompleteDeploy.ps1)  
[StepTemplates/DeployNuGetPackage.template.json](StepTemplates/DeployNuGetPackage.template.json)  
[StepTemplates/DeployNuGetPackage.ps1](StepTemplates/DeployNuGetPackage.ps1)  
[StepTemplates/DeployTo.template.json](StepTemplates/DeployTo.template.json)  
[StepTemplates/DeployTo.ps1](StepTemplates/DeployTo.ps1)  
[StepTemplates/ExpectStatus.template.json](StepTemplates/ExpectStatus.template.json)  
[StepTemplates/ExpectStatus.ps1](StepTemplates/ExpectStatus.ps1)  
[StepTemplates/ResetDeploy.template.json](StepTemplates/ResetDeploy.template.json)  
[StepTemplates/ResetDeploy.ps1](StepTemplates/ResetDeploy.ps1)  
[StepTemplates/SmokeTestIfFailReset.template.json](StepTemplates/SmokeTestIfFailReset.template.json)  
[StepTemplates/SmokeTestIfFailReset.ps1](StepTemplates/SmokeTestIfFailReset.ps1)  

### Environments
If you already have environments that you want to use and could match DXP environments, Integration / Preproduction / Production, you don´t need to do this step. But if you want specific environments for DXP you can do like this.  
Go to Infrastructure/Environments and click on 'Add environment'. Create 3 environments.  
1. `DXP_Integration`  
2. `DXP_Preproduction`  
3. `DXP_Production`  
  
  
### Lifecycles
These lifecycles should match how you want to work with CI/CD in your project. This example is set up to deploy the latest committed code to the 'development" branch to DXP Integration environment and 'main'/'release'/'hotfix' branches to DXP Preproduction. If the application is working as expected you can approve the deployment so that it deploys to production.  
1. `Optimizely DXP - Development`  
    1.1 Go to Library/Lifecycles and click 'Add lifecycle'.   
    1.2 Name: `Optimizely DXP - Development`.  
    1.3 Description: `Automatically deploy to Optimizely DXP development/integration environment.`  
    1.4 Add phase: Phase 1. Call it `Integration` and select the environment `DXP_Integration`.  
    1.5 Save
2. `Optimizely DXP - Release`  
    2.1 Click 'Add lifecycle'.   
    2.2 Name: `Optimizely DXP - Release`.  
    2.3 Description: `Release pipeline for deployment to Optimizely DXP environments preproduction/production.`  
    2.4 Add phase: Phase 1. Call it `Release` and select the environments `DXP_Preproduction` and `DXP_Production`.  
    2.5 Save
  
### Project
This is a very simplified description how to set up the project. There are so many exceptions for each customer/project etc. So this is just a brief example how we set it up.  
Go to Projects and click on 'Add project'.  
Name: `Website - DXP`  
Description: `Deployment to Optimizely DXP. Dev => Integration, Release => Preproduction/Production`  
Lifecycle: Set `Optimizely DXP - Development` as default.  
#### Channels
Now when project is created we will add extra channels (lifecycle) so that we can have on project to handle all CI/CD cases we want.  
**Update default channel** 
1. Change the default channel that points to lifecycle `Optimizely DXP - Development`.  
2. Change name to `Development/Integration`  
3. Description to `Will deploy package to Optimizely DXP integration environment.`.  
4. Lifecycle is set to `Inherit from parent` that in this case will be `Optimizely DXP - Development`.  
5. Save changes.  

**Create release channel**  
1. Click on 'Add channel'.
2. Name: `Release - Preproduction/Production`  
3. Description `Deploy release to Optimizely DXP environments preproduction and production.`.  
4. Select `Optimizely DXP - Release` as lifecycle.  
5. Save.  

**Create reset channel**  
1. Click on 'Add channel'.  
2. Name: `Reset - Preproduction/Production`  
3, Description `This channel will help you if you find errors in the slot environment and need to cancel/reset the deployment.`.  
4. Select `Optimizely DXP - Release` as lifecycle.  
5. Save. 

#### Triggers
You can set up triggers of your choice. In our case we will trigger the releases from TeamCity so we will not add any triggers in Octopus.  

#### Variables - Variables sets 
Go to Variables/Variables sets. Click on 'Include library variable sets' and add the `DXP deployment` variable set.

#### Variables - Project variables
Go to Variables/Project. Create the following variables. Some of them has multiple values depending on scope.  
1. **Name:** `DirectDeploy`  
1.1 **Value:** `True`  
1.2 **Scope:** `DXP_Integration`  
2.1 **Value:** `False`  
2.2 **Scope:** `DXP_Preproduction`  

2. **Name:** `SourceApp`  
**Value:** `cms`
  
3. **Name:** `TargetEnvironment`  
3.1.1 **Value:** `Integration`  
3.1.2 **Scope:** `DXP_Integration`  
3.2.1 **Value:** `Preproduction`  
3.2.2 **Scope:** `DXP_Preproduction`  
3.3.1 **Value:** `Production`  
3.3.2 **Scope:** `DXP_Production`  

4. **Name:** `WarmUpUrl`  
4.1.1 **Value:** `https://nasa01mstr1ssz2inte.dxcloud.episerver.net/Util/Login?ReturnUrl=%2Fepiserver%2Fcms`  
4.1.2 **Scope:** `DXP_Integration`  
4.2.1 **Value:** `https://nasa01mstr1ssz2prep-slot.dxcloud.episerver.net/Util/Login?ReturnUrl=%2Fepiserver%2Fcms`  
4.2.2 **Scope:** `DXP_Preproduction`  
4.3.1 **Value:** `https://nasa01mstr1ssz2prod-slot.dxcloud.episerver.net/Util/Login?ReturnUrl=%2Fepiserver%2Fcms`  
4.3.2 **Scope:** `DXP_Production`  

#### Process - Release steps
Since we only have on project, but use 3 lifecycle, there will be steps in the project that is only run on a specific environment and/or channel. Let us set up the process steps first and then describe how the flow will work for the different deployments.  
1. Go to Process and start to add the first task.  
2. Click on the 'Add step' button. Filter the list on 'dxp' to show the step templates that you created eariler.  
3. `Optimizely DXP - Expect status`  
    3.1 Select `Optimizely DXP - Expect status`. This is optional. But I like this one because it makes sure that the status on the target environment is in expected status before start deployment. Then the deployment will not crash if a deployment is alleady running or something is broken.  
    3.2 Name: `Optimizely DXP - Expect status`  
    3.3 Execution location: `Octopus server`  
    3.4 Expected status: `SucceededOrReset`  
    3.5 Channels: `Optimizely DXP - Development`, `Release - Preproduction/Production`  
    3.6 Save
4. `Deploy NuGet package`  
    4.1 Click on the 'Add step' button. Filter the list on 'dxp' to show the step templates that you created eariler.  
    4.2 Select `Optimizely DXP - Deploy NuGet package`.  
    4.3 Name: `Deploy NuGet package`  
    4.3 Execution location: `Octopus server`  
    4.5 Package name: `[Name of the package in Packages that is your website NuGet package]`. Example: `[Websitename].cms.app`  
    4.6 Environments: `DXP_Integration`, `DXP_Preproduction`, `DXP_Production`  
    4.7 Channels: `Optimizely DXP - Development`, `Release - Preproduction/Production`  
    4.8 Save
5. `Test the website`  
    5.1 Click on the 'Add step' button. Filter the list on 'manual'.  
    5.2 Select `Manual intervention Required`.  
    5.3 Name: `Test the website`  
    5.3 Execution location: `Octopus server`  
    5.4 Instructions: `Test your website on #{WarmUpUrl}. If everything is work you can continue.`  
    5.5 Environments: `DXP_Production`  
    5.6 Channels: `Release - Preproduction/Production`  
    5.7 Save
6. `Complete deploy (switch slot)`  
    6.1 Click on the 'Add step' button. Filter the list on 'dxp' to show the step templates that you created eariler.  
    6.2 Select `Optimizely DXP - Complete deploy`.  
    6.3 Name: `Complete deploy (switch slot)`  
    6.4 Execution location: `Octopus server`  
    6.5 Environments: `DXP_Preproduction`, `DXP_Production`  
    6.6 Channels: `Release - Preproduction/Production`  
    6.7 Save
7. `Reset deploy`  
    7.1 Click on the 'Add step' button. Filter the list on 'dxp' to show the step templates that you created eariler.  
    7.2 Select `Optimizely DXP - Reset deploy`.  
    7.3 Name: `Reset deploy`  
    7.4 Execution location: `Octopus server`  
    7.6 Channels: `Reset - Preproduction/Production`  
    7.7 Save

All set!
#### Deployment flow - How does it work?
**`development` branch to `DXP_Integration`**.  
In TeamCity after the `development` branch has been built it will upload the NuGet package to the Octopus Packages feed and create/trigger the project to start a release/deployment for the deafult channel. That means that channel `Optimizely DXP - Development` will be used when run the deployment. The following tasks will be triggered:  
1. Acquire packages will be downloaded. That means latest version of `EpiCloud`, `EpinovaDxpToolBucket` and `[Websitename].cms.app`.  
2. `Optimizely DXP - Expect status` will run and make sure that the target environment is in expected status.  
3. `Deploy NuGet package` will deploy the latest version of your package to DXP and start a 'Direct deploy' deployment of that NuGet package to the Integration environment in DXP. When it is deployed it will also warmup the website with the URL that you provided as warmup URL for this environment.
4. All other tasks will be ignored since it will not meet the requirments for target environment or channel.  

You should now be able to browse you website in the Optimizely DXP integration environment.  
  
**`main`/`release`/`hotfix` branch to `DXP Preproduction` => `DXP Production`.**  
In TeamCity after example the `release` branch has been built it will upload the NuGet package to the Octopus Packages feed and create/trigger the project to start a release/deployment for the `Release - Preproduction/Production` channel. That means that channel `Release - Preproduction/Production` will be used when run the deployment. The following tasks will be triggered:  
1. Acquire packages will be downloaded. That means latest version of `EpiCloud`, `EpinovaDxpToolBucket` and `[Websitename].cms.app`.  
2. `Optimizely DXP - Expect status` will run and make sure that the target environment is in expected status.  
3. `Deploy NuGet package` will deploy the latest version of your package to DXP and start a deployment of that NuGet package to the Preproduction environment in DXP. Since you can´t run 'Direct deploy' to preproduction, the deployment will deploy the package to the preproduction slot.  When it is deployed it will also warmup the website with the URL that you provided as warmup URL for this environment.
4. `Test the website` task will not run since it will not meet the requirments for target environment.  
5. `Complete deploy (switch slot)` will run and will complete the deploy for preproduction to swap 'preproduction slot' => preproduction.  
6. Now the deployment to preproduction is finished. Your team can now test the EXP preproduction environment and make sure everything works. 
7. When it is time to deploy that release to production, someone in the team go to the latest release that now stands in the preproduction status and manualy start the release to production.
8. `Optimizely DXP - Expect status` will run and make sure that the target environment is in expected status.  
9. `Deploy NuGet package` will deploy the latest version of your package to DXP and start a deployment of that NuGet package to the Production environment in DXP. Since you can´t run 'Direct deploy' to production, the deployment will deploy the package to the production slot.  When it is deployed it will also warmup the website with the URL that you provided as warmup URL for this environment.
10. `Test the website`. The deployment will not stop at this step and project team can now test the production slot. When everything is tested you can continue deployment. If something is wrong and you need to reset/cancel the deployment. Cancel the release and start a new release with the channel `Reset - Preproduction/Production`. Select the environment that you want to reset and start the Octopus release.   
You can also do this manualy. Go to Optimizely DXP PAAS portal and click reset deployment to production. [https://paasportal.episerver.net/](https://paasportal.episerver.net/).  
11. `Complete deploy (switch slot)` will run and will complete the deploy for production to swap 'production slot' => production.  
12. Site is now released to production.
  
If you need to reset a deployment to a slot:  
Cancel the release and start a new release with the channel `Reset - Preproduction/Production`. Select the environment that you want to reset and start the Octopus release.   
You can also do this manualy. Go to Optimizely DXP PAAS portal and click reset deployment to production. [https://paasportal.episerver.net/](https://paasportal.episerver.net/).

## Tasks ##

### Deploy NuGet package (Optimizely DXP) ###  
Take a NuGet package from your drop folder in Azure DevOps and upload it to your Optimizely (formerly known as Episerver) DXP project and start a deployment to the specified environment.  
[Deploy NuGet package documentation](../documentation/DeployNugetPackage.md)  
  
### Deploy To (Optimizely DXP) ###
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  
Can also be used for Content copy during deployment. With the IncludeBlob and IncludeDb you can now sync/deploy both ways.  
Also support Zero Downtime Deployment (aka ZDD or Smooth deployment).  
[Deploy to documentation](../documentation/DeployTo.md)  

### Complete deploy (Optimizely DXP) ###
Both "Deploy NuGet package (Optimizely DXP)" and "Move deploy (Optimizely DXP)" tasks deploy a package to a environment. That will deploy the package to a slot. The task "Complete deploy (Optimizely DXP)" will complete the deploy and move the packe from slot to the real environment.  
[Complete deploy documentation](../documentation/CompleteDeploy.md)

### Smoke test if fail reset (Optimizely DXP) ###
This task smoke test a slot and decide if we should continue the release or reset the environment slot because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  
[Smoke test if fail reset documentation](../documentation/SmokeTestIfFailReset.md)

### Reset deploy (Optimizely DXP) ###
Reset a specifed environment if the status for the environment is in status "AwaitingVerification".  
[Reset deploy documentation](../documentation/ResetDeploy.md)

### Await status (Optimizely DXP) ###
Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that verify correct status. If status is AwaitingVerification/Reset/Succeeded, nothing will happen.  
[Await status documentation](../documentation/AwaitStatus.md)  

### Expect status (Optimizely DXP) ###
Task that check the status for an environment. if environment is not in the expected status the task will fail.  
[Expect status documentation](../documentation/ExpectStatus.md)  
