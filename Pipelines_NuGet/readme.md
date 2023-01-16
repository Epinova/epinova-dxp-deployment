# Epinova.OptimizelyDxp.Pipelines
NuGet with YML pipelines that can be used in projects to setup pipelines for deployment to Optmizely DXP fast and easy. 

## Usage/Installation
1. Install 'Epinova.OptimizelyDxp.Pipelines' NuGet package from the feed. Epinova NuGet feed: https://nuget.epinova.no/nuget/  
2. Commit/checkin '$(SolutionDir)\.azuredevops\EpinovaOptimizelyDxpPipelines' files.
  
[More detailed description for installation](Installation.md)


## Pipelines
### [ContentCopy-IntePrep.yml](content/.azuredevops/EpinovaOptimizelyDxpPipelines/ContentCopy-IntePrep.yml)
Copy databases and blobs from source environment to target environment. Source: Integration, Target: Preproduction

### [ContentCopy-PrepInte.yml](content/.azuredevops/EpinovaOptimizelyDxpPipelines/ContentCopy-PrepInte.yml)
Copy databases and blobs from source environment to target environment. Source: Preproduction, Target: Integration

### [ContentCopy-ProdPrep.yml](content/.azuredevops/EpinovaOptimizelyDxpPipelines/ContentCopy-ProdPrep.yml)
Copy databases and blobs from source environment to target environment. Source: Production, Target: Preproduction

### [Reset-IntePrepProd.yml](content/.azuredevops/EpinovaOptimizelyDxpPipelines/Reset-IntePrepProd.yml)
Used when there is a environment that has for some reason stoped during deployment. If you need to reset you can run this pipeline.  
It will start to look at the Integration environment and ask if the environmnet is in a state that can be reset. If so it will be reseted. If not it will go to 'Preproduction' and repeat. And in the end the same for the 'Production' environment. 

### [Reset-Inte.yml](content/.azuredevops/EpinovaOptimizelyDxpPipelines/Reset-Inte.yml)
Used when there is a environment that has for some reason stoped during deployment. If you need to reset the 'Integration' environment you can run this pipeline.  

## Prerequisites/Preparation
### Create variable group
All tasks and YAML files are using variables (from variable group 'DXP-variables') that can be reused by one to many pipelines. In Azure DevOps you can use a variable group for this use case.  
[How to create variable group in Azure DevOps](../documentation/CreateVariableGroup.md)  
