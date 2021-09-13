import tl = require("azure-pipelines-task-lib/task");
import { basename } from "path";

import {
    logInfo,
    logError
}  from "./agentSpecific";

export async function run() {
    try {
        // Get the build and release details
        let ClientKey = tl.getInput("ClientKey");
        let ClientSecret = tl.getInput("ClientSecret");
        let ProjectId = tl.getInput("ProjectId");
        let TargetEnvironment = tl.getInput("TargetEnvironment");
        let SourceApp = tl.getInput("SourceApp");
        let DirectDeploy = tl.getInput("DirectDeploy");
        let UseMaintenancePage = tl.getInput("UseMaintenancePage");
        let DropPath = tl.getInput("DropPath");
        let Timeout = tl.getInput("Timeout");
        let ZeroDowntimeMode = tl.getInput("ZeroDowntimeMode");

        // we need to get the verbose flag passed in as script flag
        var verbose = (tl.getVariable("System.Debug") === "true");

        // find the executeable
        let executable = "pwsh";
        if (tl.getVariable("AGENT.OS") === "Windows_NT") {
            if (!tl.getBoolInput("usePSCore")) {
                executable = "powershell.exe";
            }
            logInfo(`Using executable '${executable}'`);
        } else {
            logInfo(`Using executable '${executable}' as only only option on '${tl.getVariable("AGENT.OS")}'`);
        }

        // we need to not pass the null param
        var args = [__dirname + "\\DeployNuGetPackage.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", ClientSecret,
        "-ProjectId", ProjectId,
        "-TargetEnvironment", TargetEnvironment,
        "-SourceApp", SourceApp,
        "-DirectDeploy", "$" + DirectDeploy,
        "-UseMaintenancePage", "$" + UseMaintenancePage,
        "-DropPath", DropPath,
        "-Timeout", Timeout
        ];
        if (ZeroDowntimeMode) {
            args.push("-ZeroDowntimeMode");
            args.push(ZeroDowntimeMode);
        }

        var argsShow = [__dirname + "\\DeployNuGetPackage.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", "***",
        "-ProjectId", ProjectId,
        "-TargetEnvironment", TargetEnvironment,
        "-SourceApp", SourceApp,
        "-DirectDeploy", DirectDeploy,
        "-UseMaintenancePage", UseMaintenancePage,
        "-DropPath", DropPath,
        "-Timeout", Timeout,
        "-ZeroDowntimeMode", ZeroDowntimeMode
        ];

        logInfo(`${executable} ${argsShow.join(" ")}`);

        var spawn = require("child_process").spawn, child;
        child = spawn(executable, args);
        child.stdout.on("data", function (data) {
            logInfo(data.toString());
        });
        child.stderr.on("data", function (data) {
            logError(data.toString());
        });
        child.on("exit", function () {
            logInfo("Script finished");
        });
    }
    catch (err) {
        logError(err);
    }
}

run();