# Epinova Optimizely DXP Deployment Templates
Templates that can be used by organisations in Azure DevOps that user Epinova Optimizely DXP Deployment extension tasks.

Get started with [Azure devops pipeline templates documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops)

# List of pipelines

- dxp.exportdb.1.yml [doc](dxp.exportdb.1.md)

# How to use templates from Epinova Optimizely DXP Deployment
! Description how to setup a Service Connection to the github.... or if it is public  just describe that.  

All projects in Azure DevOps (for Epinova-Sweden) that want to use templates from this repository needs to setup a service connection from your project.  
https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops#extend-from-a-template  


# Do's and Don'ts
- Do not make breaking changes
- Use a branch to test if new pipeline still works (ref parameter is branch name)
- Do make new versions when a breaking change happens
- New pipelines should always end with a version number "new-pipeline.1.yml"
- Do not delete templates in use
- Add deprecation notice in old template if you make a new better one. Use [warning.1.yml](tools/warning.1.md)
- Use [VS Code](https://code.visualstudio.com/) and [Azure Pipelines extension](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines) when editing pipelines.