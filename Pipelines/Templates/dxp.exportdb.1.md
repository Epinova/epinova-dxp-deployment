# dxp.exportdb.1.yml

This pipeline is made for exporting Cms/Commerce database from Integration/Preproduction/Production environment in DXP.  
  
## Requirements
You need to setup a variable group "DXP-variables". [Information how to set up this variable group you can find on GitHub](https://github.com/Epinova/epinova-dxp-deployment/blob/master/documentation/CreateVariableGroup.md)  
In example 2 below you can see that we have setup  service connection with the name "DxpPipelinesTemplates".

## Setup
1. [Setup "DXP-variables" variable group](https://github.com/Epinova/epinova-dxp-deployment/blob/master/documentation/CreateVariableGroup.md)
2. Add your dxp-exportdb.yml


## dxp-exportdb.yml (Use downloaded template in your repo)
```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: DXP-variables

parameters:
- name: databaseType
  displayName: 'The type of database that you want to export? epicms or epicommerce'
  type: string
  default: epicms
  values:
  - epicms
  - epicommerce
- name: dxpEnvironment
  displayName: 'The environment that you want to export the database from. Integration/Preproduction/Production'
  type: string
  default: Integration
  values:
  - Integration
  - Preproduction
  - Production

steps:
- checkout: none  # Don't sync sources
- ${{ if eq(parameters.databaseType, 'epicms') }}:
  - template: dxp.exportdb.1.yml
    parameters:
      clientKey: $(ClientKey)
      clientSecret: $(ClientSecret)
      projectId: $(DXP.ProjectId)
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 1800 #30min
- ${{ if eq(parameters.databaseType, 'epicommerce') }}:
  - template: dxp.exportdb.1.yml
    parameters:
      clientKey: $(ClientKey)
      clientSecret: $(ClientSecret)
      projectId: $(DXP.ProjectId)
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 7200 #2hours
```

## dxp-exportdb.yml (If you link to the template in GitHub)
```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: DXP-variables

parameters:
- name: databaseType
  displayName: 'The type of database that you want to export? epicms or epicommerce'
  type: string
  default: epicms
  values:
  - epicms
  - epicommerce
- name: dxpEnvironment
  displayName: 'The environment that you want to export the database from. Integration/Preproduction/Production'
  type: string
  default: Integration
  values:
  - Integration
  - Preproduction
  - Production

resources:
  repositories:
  - repository: templates
    type: github
    name: Epinova/epinova-dxp-deployment
    ref: refs/heads/master
    endpoint: DxpPipelinesTemplates # Azure DevOps service connection

steps:
- checkout: none  # Don't sync sources
- ${{ if eq(parameters.databaseType, 'epicms') }}:
  - template: /Pipelines/Templates/dxp.exportdb.1.yml@templates
    parameters:
      clientKey: $(ClientKey)
      clientSecret: $(ClientSecret)
      projectId: $(DXP.ProjectId)
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 1800 #30min
- ${{ if eq(parameters.databaseType, 'epicommerce') }}:
  - template: /Pipelines/Templates/dxp.exportdb.1.yml@templates
    parameters:
      clientKey: $(ClientKey)
      clientSecret: $(ClientSecret)
      projectId: $(DXP.ProjectId)
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 7200 #2hours
```

