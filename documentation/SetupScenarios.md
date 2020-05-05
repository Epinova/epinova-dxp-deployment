# Setup senarios (YAML)
Different projects has different branch and release strategi. That is why we have tried to cover the most common senarios. Pick the ones that fit you best.   
[Branch strategy](BranchStrategy.md)  
All the senarios below has YAML files that can be used.

[<= Back to root](../README.md)

## Prerequisites/Preparation
### Create variable group
All tasks and YAML files are using variables that can be reused by one to many pipelines. In Azure DevOps you can use a variable group for this use case.  
[How to create the variable group](CreateVariableGroup.md)  

### Create environments
To be able to have approval steps before deployment can start to different environments we need to setup environments in Azure DevOps. The YAML files use these environments and that´s why we need them.  
[How to create the environments](CreateEnvironments.md)  

## YAML Pipelines
## [Branch:develop] (WebPackage) => Integration, [Branch:release] (NuGet) => Preproduction => Production
This senario build and deploy the develop branch to integration with the WebPackage method. And build and deploy a release branch to preproduction that can be approved and deployed to production.  
`develop => integration (WebPackage)` [Develop-Inte_webpackage.yml](../Pipelines/Develop-Inte_webpackage.yml)  
`release => Prep => Prod (NuGet)` [Release-PrepProd.yml](../Pipelines/Release-PrepProd.yml)  

## [Branch:develop] (NuGet) => Integration, [Branch:release] (NuGet) => Preproduction => Production
This senario build and deploy the develop branch to integration with the NuGet method. And build and deploy a release branch to preproduction that can be approved and deployed to production. Equal to the senario above but the package technic is different.  
`develop => integration (NuGet)` [Develop-Inte.yml](../Pipelines/Develop-Inte.yml)  
`release => Prep => Prod (NuGet)` [Release-PrepProd.yml](../Pipelines/Release-PrepProd.yml)  

## [Branch:master] (WebPackage) => Integration => Preproduction => Production
This senario build and deploy the master branch to integration with the WebPackage method. The deploy can after approval continue to preproduction and production.  
`master => inte => prep => prod (WebPackage)`  

## [Branch:master] (NuGet) => Integration => Preproduction => Production
This senario build and deploy the master branch to integration with the Nuget method. The deploy can after approval continue to preproduction and production.  
`master => inte => prep => prod (NuGet)` [Master-IntePrepProd.yml](../Pipelines/Master-IntePrepProd.yml)  

## Reset - Integration => Preproduction => Production
`reset inte => prep => prod` [Reset-IntePrepProd.yml](../Pipelines/Reset-IntePrepProd.yml)  

## Hotfix
`Hotfix* => prod (nuget)`  *No YAML file yet*

[<= Back to root](../README.md)
