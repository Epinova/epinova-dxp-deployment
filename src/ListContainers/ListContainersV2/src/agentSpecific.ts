import tl = require("azure-pipelines-task-lib");

// moving the logging function to a separate file

export function logDebug (msg: string) {
    tl.debug(msg);
}

export function logWarning (msg: string) {
    tl.warning(msg);
 }

export function logInfo (msg: string) {
     console.log(msg);
}

export function logError (msg: string) {
    tl.error(msg);
    tl.setResult(tl.TaskResult.Failed, msg);
}