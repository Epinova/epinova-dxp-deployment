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
        let Urls = tl.getInput("Urls");
        let ResetOnFail = tl.getInput("ResetOnFail");
        let SleepBeforeStart = tl.getInput("SleepBeforeStart");
        let NumberOfRetries = tl.getInput("NumberOfRetries");
        let SleepBeforeRetry = tl.getInput("SleepBeforeRetry");
        let Timeout = tl.getInput("Timeout");
        let ErrorActionPreference = tl.getInput("ErrorActionPreference");

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
        var args = [__dirname + "\\SmokeTestIfFailReset.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", ClientSecret,
        "-ProjectId", ProjectId,
        "-TargetEnvironment", TargetEnvironment,
        "-Urls", Urls,
        "-ResetOnFail", ResetOnFail,
        "-SleepBeforeStart", SleepBeforeStart,
        "-NumberOfRetries", NumberOfRetries,
        "-SleepBeforeRetry", SleepBeforeRetry,
        "-ErrorActionPreference", ErrorActionPreference,
        "-Timeout", Timeout
        ];

        var argsShow = [__dirname + "\\SmokeTestIfFailReset.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", "***",
        "-ProjectId", ProjectId,
        "-TargetEnvironment", TargetEnvironment,
        "-Urls", Urls,
        "-ResetOnFail", ResetOnFail,
        "-SleepBeforeStart", SleepBeforeStart,
        "-NumberOfRetries", NumberOfRetries,
        "-SleepBeforeRetry", SleepBeforeRetry,
        "-ErrorActionPreference", ErrorActionPreference,
        "-Timeout", Timeout
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