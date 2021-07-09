# dxp.exportdb.1.yml

This pipeline is made for exporting Cms/Commerce database from Integration/Preproduction/Production environment in DXP.  
  
## Requirements
You need to setup a variable group "DXP-variables". [Information how to set up this variable group you can find on GitHub](https://github.com/Epinova/epinova-dxp-deployment/blob/master/documentation/CreateVariableGroup.md)  

## Setup
1. [Setup "DXP-variables" variable group](https://github.com/Epinova/epinova-dxp-deployment/blob/master/documentation/CreateVariableGroup.md)
2. Add your dxp-exportdb.yml


## dxp-exportdb.yml (In Epinova organization)
```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: DXP-variables

parameters:
- name: clientKey
  displayName: ''
  type: string
  default: $(ClientKey)
- name: clientSecret
  displayName: ''
  type: string
  default: $(ClientSecret)
- name: projectId
  displayName: ''
  type: string
  default: $(DXP.ProjectId)
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
  - template: dxp.exportdb.1.yml@pipelines
    parameters:
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 1800 #30min
- ${{ if eq(parameters.databaseType, 'epicommerce') }}:
  - template: dxp.exportdb.1.yml@pipelines
    parameters:
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 7200 #2hours
```

## dxp-exportdb.yml (In Epinova-Sweden organization)
```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: DXP-variables

parameters:
- name: clientKey
  displayName: ''
  type: string
  default: $(ClientKey)
- name: clientSecret
  displayName: ''
  type: string
  default: $(ClientSecret)
- name: projectId
  displayName: ''
  type: string
  default: $(DXP.ProjectId)
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
  - repository: pipelines
    name: Contoso/BuildTemplates
    endpoint: epinovaPipelineConnection # Azure DevOps service connection

steps:
- checkout: none  # Don't sync sources
- ${{ if eq(parameters.databaseType, 'epicms') }}:
  - template: dxp.exportdb.1.yml@pipelines
    parameters:
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 1800 #30min
- ${{ if eq(parameters.databaseType, 'epicommerce') }}:
  - template: dxp.exportdb.1.yml@pipelines
    parameters:
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 7200 #2hours
```

## dxp-exportdb.yml (if you copy the template files to your project)
```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: DXP-variables

parameters:
- name: clientKey
  displayName: ''
  type: string
  default: $(ClientKey)
- name: clientSecret
  displayName: ''
  type: string
  default: $(ClientSecret)
- name: projectId
  displayName: ''
  type: string
  default: $(DXP.ProjectId)
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
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 1800 #30min
- ${{ if eq(parameters.databaseType, 'epicommerce') }}:
  - template: dxp.exportdb.1.yml
    parameters:
      clientKey: ${{ parameters.clientKey }}
      clientSecret: ${{ parameters.clientSecret }}
      projectId: ${{ parameters.projectId }}
      dxpEnvironment: ${{ parameters.dxpEnvironment }}
      databaseType: ${{ parameters.databaseType }}
      retentionHours: 24
      timeout: 7200 #2hours
```