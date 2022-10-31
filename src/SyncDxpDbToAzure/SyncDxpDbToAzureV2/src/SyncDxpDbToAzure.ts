import tl = require("azure-pipelines-task-lib/task");
import { basename } from "path";

import {
    logInfo,
    logError
}  from "./agentSpecific";

import { AzureRMEndpoint } from 'azure-pipelines-tasks-azure-arm-rest-v2/azure-arm-endpoint';
var uuidV4 = require('uuid/v4');

function convertToNullIfUndefined<T>(arg: T): T|null {
    return arg ? arg : null;
}

export async function run() {
    try {
        // Get the build and release details
        let ClientKey = tl.getInput("ClientKey");
        let ClientSecret = tl.getInput("ClientSecret");
        let ProjectId = tl.getInput("ProjectId");
        let Environment = tl.getInput("Environment");
        let DatabaseType = tl.getInput("DatabaseType");

        let DropPath = tl.getInput("DropPath");

        let serviceName = tl.getInput('ConnectedServiceNameARM',/*required*/true);
        let endpointObject= await new AzureRMEndpoint(serviceName).getEndpoint();
        let input_workingDirectory = "";
        let isDebugEnabled = (tl.getInput('RunVerbose', false) || "").toLowerCase() === "true";
        console.log(serviceName);
        let SubscriptionId = serviceName;
        let ResourceGroupName: string = convertToNullIfUndefined(tl.getInput('ResourceGroupName', false));
        let StorageAccountName: string = convertToNullIfUndefined(tl.getInput('StorageAccountName', false));
        let StorageAccountContainer: string = convertToNullIfUndefined(tl.getInput('StorageAccountContainer', false));
        let SqlServerName: string = convertToNullIfUndefined(tl.getInput('SqlServerName', false));
        let SqlDatabaseName: string = convertToNullIfUndefined(tl.getInput('SqlDatabaseName', false));
        let RunDatabaseBackup = convertToNullIfUndefined(tl.getBoolInput('RunDatabaseBackup', false));
        let SqlDatabaseLogin: string = convertToNullIfUndefined(tl.getInput('SqlDatabaseLogin', false));
        let SqlDatabasePassword: string = convertToNullIfUndefined(tl.getInput('SqlDatabasePassword', false));
        let SqlSku: string = convertToNullIfUndefined(tl.getInput('SqlSku', false));

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
        var args = [__dirname + "\\SyncDxpDbToAzure.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", ClientSecret,
        "-ProjectId", ProjectId,
        "-Environment", Environment,
        "-DatabaseType", DatabaseType,
        "-SubscriptionId", SubscriptionId,
        "-ResourceGroupName", ResourceGroupName,
        "-StorageAccountName", StorageAccountName,
        "-StorageAccountContainer", StorageAccountContainer,
        "-SqlServerName", SqlServerName,
        "-SqlDatabaseName", SqlDatabaseName,
        "-RunDatabaseBackup", RunDatabaseBackup,
        "-SqlDatabaseLogin", SqlDatabaseLogin,
        "-SqlDatabasePassword", SqlDatabasePassword,
        "-SqlSku", SqlSku,
        "-DropPath", DropPath,
        "-Timeout", Timeout
        ];
        if (RunVerbose) {
            args.push("-RunVerbose");
            args.push("true");
        }

        var argsShow = [__dirname + "\\SyncDxpDbToAzure.ps1",
        "-ClientKey", ClientKey,
        "-ClientSecret", "***",
        "-ProjectId", ProjectId,
        "-Environment", Environment,
        "-DatabaseType", DatabaseType,
        "-SubscriptionId", SubscriptionId,
        "-ResourceGroupName", ResourceGroupName,
        "-StorageAccountName", StorageAccountName,
        "-StorageAccountContainer", StorageAccountContainer,
        "-SqlServerName", SqlServerName,
        "-SqlDatabaseName", SqlDatabaseName,
        "-RunDatabaseBackup", RunDatabaseBackup,
        "-SqlDatabaseLogin", SqlDatabaseLogin,
        "-SqlDatabasePassword", SqlDatabasePassword,
        "-SqlSku", SqlSku,
        "-DropPath", DropPath,
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