# Problems
This is a collection of problems that we or other has bumped into and how it could be fixed..  

[<= Back](../README.md)

## Exception calling "FromBase64String" with "1" argument(s):...
### Error
If you run into the error message.  "Exception calling "FromBase64String" with "1" argument(s): "The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.". That means that some of the parameters sent to the script is wrong.  
In our case I have missed to link the Variable Group with DXP.ProjectId etc to the release pipeline. So after linked the variable group it started to work.  

This was the Inputs before the fix:  

    2020-03-18T23:17:43.8255269Z Task         : Deploy nuget package (Episerver DXP)
    2020-03-18T23:17:43.8255695Z Description  : Start a deploy of a nuget package to target environment for your DXP project. (Episerver DXP, former DXC)
    2020-03-18T23:17:43.8256235Z Version      : 1.0.1
    2020-03-18T23:17:43.8256452Z Author       : Ove Lartelius
    2020-03-18T23:17:43.8257005Z Help         : https://github.com/Epinova/epinova-dxp-deployment/blob/master/documentation/DeployNugetPackage.md
    2020-03-18T23:17:43.8257447Z ==============================================================================
    2020-03-18T23:17:46.0117138Z Inputs:
    2020-03-18T23:17:46.0122538Z ClientKey: $(PreProduction.ClientKey)
    2020-03-18T23:17:46.0132437Z ClientSecret: **** (it is a secret...)
    2020-03-18T23:17:46.0139977Z ProjectId: $(DXP.ProjectId)
    2020-03-18T23:17:46.0148881Z TargetEnvironment: Preproduction
    2020-03-18T23:17:46.0155487Z UseMaintenancePage: False
    2020-03-18T23:17:46.0162196Z DropPath: d:\a\r1\a/_Baerum.Kommune-Develop/drop
    2020-03-18T23:17:46.0169895Z Timeout: 1800

And after we fixed the so that the variable group where linked to the release pipeline:  

**version:** `1.0.3`  


[<= Back](../README.md)
