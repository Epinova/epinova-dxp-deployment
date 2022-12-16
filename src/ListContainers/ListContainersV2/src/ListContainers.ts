import tl = require("azure-pipelines-task-lib");
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
        let Environment = tl.getInput("Environment");
        let Timeout = tl.getInput("Timeout");
        let RunVerbose = tl.getBoolInput("RunVerbose", false);

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
        var args = [__dirname + "\\ListContainers.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", ClientSecret,
        "-ProjectId", ProjectId,
        "-Environment", Environment,
        "-Timeout", Timeout
        ];
        if (RunVerbose) {
            args.push("-RunVerbose");
            args.push("true");
        }

        var argsShow = [__dirname + "\\ListContainers.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", "***",
        "-ProjectId", ProjectId,
        "-Environment", Environment,
        "-Timeout", Timeout
        ];
        if (RunVerbose) {
            argsShow.push("-RunVerbose");
            argsShow.push("true");
        }

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