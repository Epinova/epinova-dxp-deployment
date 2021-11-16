# Problems
This is a collection of problems that we or other has bumped into and how it could be fixed..  

[<= Back](../README.md)

## Azure.Storage v4.4.0 or greater is required. - Error
If you experience the error <span style="color:red">'Azure.Storage' v4.4.0 or greater is required.</span>  
![Azure.Storage error](Images/AzureStorageV440Error/AzureStorageV440Error.jpg)  
[How to solve the Azure.Storage v4.4.0 error](AzureStorage440Error.md)

## Exception calling "FromBase64String" with "1" argument(s):...
### Error
If you run into the error message.  "Exception calling "FromBase64String" with "1" argument(s): "The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.". That means that some of the parameters sent to the script is wrong.  
In our case I have missed to link the Variable Group with DXP.ProjectId etc to the release pipeline. So after linked the variable group it started to work.  

This was the Inputs before the fix:  

    2020-03-18T23:17:43.8255269Z Task         : Deploy nuget package (Optimizely DXP)
    2020-03-18T23:17:43.8255695Z Description  : Start a deploy of a nuget package to target environment for your DXP project. (Optimizely DXP, former DXC)
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

## Smoke test fail
### Problem
Sometimes you will get "error" in the smoke test task and the deploy will reset/rollback. This can be enoying. In the log below you can see that the smoke test task wait for 20 seconds. But when the request the site you get the error " Operation is not valid due to the current state of the object.". 

    2020-06-05T01:23:27.9386079Z Start sleep for 20 seconds before we start check URL(s).
    2020-06-05T01:23:47.9383006Z Start smoketest http://cmsc01xzyqwt29jprod-slot.dxcloud.episerver.net/
    2020-06-05T01:23:47.9503766Z Executing request for URI http://cmsc01xzyqwt29jprod-slot.dxcloud.episerver.net/
    2020-06-05T01:23:48.1827174Z ##[warning] http://cmsc01xzyqwt29jprod-slot.dxcloud.episerver.net/ => Error  after 0.222433 seconds: Operation is not valid due to the current state of the object. 
    2020-06-05T01:23:48.1838705Z We found ERRORS. Smoketest fails. We will set reset flag to TRUE.

The cause of this problem could be:  
1. Your site has a problem/error an can not start.
2. You need a longer sleep time before do the test. 20 seconds may not be enough. The application is not ready yeat. That is depending on how fast your application can start.
3. Your website is behind login and the startpage return HTTP status 301. And will redirect user to login page. This is where you should use the [Environment].UrlSuffix so that the smoke test request: http://cmsc01xzyqwt29jprod-slot.dxcloud.episerver.net/Util/login.aspx
4. You are using a http:// URL but you should use https://. The request in the smoke test expect HTTP status 200 without any redirects.
  


[<= Back](../README.md)
