import tl = require("vsts-task-lib/task");
import { basename } from "path";

import {
    logInfo,
    logError
}  from "./agentSpecific";

export async function run() {
    try {

        // $ClientKey,
        // $ClientSecret,
        // $ProjectId, 
        // $TargetEnvironment,
        // $ExpectedStatus,
        // $Timeout

        // Get the build and release details
        let ClientKey = tl.getInput("ClientKey");
        let ClientSecret = tl.getInput("ClientSecret");
        let ProjectId = tl.getInput("ProjectId");
        let TargetEnvironment = tl.getInput("TargetEnvironment");
        let ExpectedStatus = tl.getInput("ExpectedStatus");
        let Timeout = tl.getInput("Timeout");

        // we need to get the verbose flag passed in as script flag
        var verbose = (tl.getVariable("System.Debug") === "true");

        // let url = tl.getEndpointUrl("SYSTEMVSSCONNECTION", false);
        // let token = tl.getEndpointAuthorizationParameter("SYSTEMVSSCONNECTION", "ACCESSTOKEN", false);

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
        var args = [__dirname + "\\ExpectStatus.ps1",
        "-ClientKey", `'${ClientKey}'`,
        "-ClientSecret", `'${ClientSecret}'`,
        "-ProjectId", `'${ProjectId}'`,
        "-TargetEnvironment", `'${TargetEnvironment}'`,
        "-ExpectedStatus", `'${ExpectedStatus}'`,
        "-Timeout", Timeout
        ];
        // if (verbose) {
        //     args.push("-Verbose");
        // }

        logInfo(`${executable} ${args.join(" ")}`);

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