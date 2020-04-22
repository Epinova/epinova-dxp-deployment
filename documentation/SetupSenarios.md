# Setup senarios (YAML)
Different projects has different branch and release strategi. That is why we have tried to cover the most common senarios. Pick the ones that fit you best.   
[Branch strategy](BranchStrategy.md)  
All the senarios below has YAML files that can be used.

[<= Back to root](../README.md)

## Create variable group


## [Branch:develop] (WebPackage) => Integration, [Branch:release] (NuGet) => Preproduction => Production
This senario build and deploy the develop branch to integration with the WebPackage method. And build and deploy a release branch to preproduction that can be approved and deployed to production.  
`develop => integration (WebPackage)` [Develop-Inte_webpackage.yaml](../Pipelines/Develop-Inte_webpackage.yaml)  
`release => Prep => Prod (NuGet)` [Release-PrepProd.yaml](../Pipelines/Release-PrepProd.yaml)  

## [Branch:develop] (NuGet) => Integration, [Branch:release] (NuGet) => Preproduction => Production
This senario build and deploy the develop branch to integration with the NuGet method. And build and deploy a release branch to preproduction that can be approved and deployed to production. Equal to the senario above but the package technic is different.  
`develop => integration (NuGet)` [Develop-Inte.yaml](../Pipelines/Develop-Inte.yaml)  
`release => Prep => Prod (NuGet)` [Release-PrepProd.yaml](../Pipelines/Release-PrepProd.yaml)  

## [Branch:master] (WebPackage) => Integration => Preproduction => Production
This senario build and deploy the master branch to integration with the WebPackage method. The deploy can after approval continue to preproduction and production.  
`master => inte => prep => prod (WebPackage)`  

## [Branch:master] (NuGet) => Integration => Preproduction => Production
This senario build and deploy the master branch to integration with the Nuget method. The deploy can after approval continue to preproduction and production.  
`master => inte => prep => prod (NuGet)` [Master-IntePrepProd.yaml](../Pipelines/Master-IntePrepProd.yaml)  

## Reset - Integration => Preproduction => Production
`reset inte => prep => prod` [Reset-IntePrepProd.yaml](../Pipelines/Reset-IntePrepProd.yaml)  

## Hotfix
`Hotfix* => prod (nuget)`  

[<= Back to root](../README.md)
