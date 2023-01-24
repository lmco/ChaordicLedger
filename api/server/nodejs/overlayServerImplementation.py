import argparse
from datetime import datetime
import json
import logging
import os
import shutil
import sys

log = logging.getLogger(__name__)


def configureLogging(outdir):
    formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s',
                                  '%m-%d-%Y %H:%M:%S')

    log.setLevel(logging.INFO)

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.INFO)
    stdout_handler.setFormatter(formatter)

    file_handler = logging.FileHandler(os.path.join(
        outdir, f"{datetime.now().isoformat().replace(':','_').split('.')[0]}.log"))
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    log.addHandler(file_handler)
    log.addHandler(stdout_handler)


def validateArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--inputdir", action="store",
                        help="The input directory", required=True)
    parser.add_argument("-m", "--mapfile", action="store",
                        help="The map of the functions to their implementations", required=True)
    parser.add_argument("-o", "--outputdir", action="store",
                        help="The output directory", required=True)
    parser.add_argument("-f", "--outputfile", action="store",
                        help="The output file", required=True)
    parser.add_argument("-n", "--namespace", action="store",
                        help="The Kubernetes namespace", default="chaordicledger")

    args = parser.parse_args()

    if not os.path.exists(args.inputdir):
        raise Exception(f"Input dir {args.inputdir} does not exist")

    config = None
    with open(args.mapfile, 'r') as f:
        config = json.load(f)

    if not os.path.exists(args.outputdir):
        raise Exception(f"Output dir {args.outputdir} does not exist")

    namespace = args.namespace
    if namespace is None or namespace == "":
        namespace = "default"

    return (args.inputdir, config, args.outputdir, args.outputfile, namespace)


def getReplacementExpression(arg, stringify):
    retVal = "sed 's|{{" + arg + "}}|${" + arg + "}|g'"

    if arg == "formData" or arg == "body":
        if stringify:
            retVal = "sed 's|{{" + arg + "}}|\"${JSON.stringify(" + arg + ")}\"|g'"
        else:
            retVal = "sed 's|{{" + arg + "}}|\"${tmpfileName}\"|g'"

    return retVal


def overlayServerImplementation(inputdir: str, mapfile: dict, outputdir: str, outputfile: str, namespace: str):
    log.info("Overlaying server implementation")

    outputpath = os.path.join(outputdir, outputfile)
    if os.path.isfile(outputpath):
        backuppath = outputpath + ".bak"
        log.info(f"Backing-up {outputpath} as {backuppath}")
        shutil.move(outputpath, backuppath)

    with open(outputpath, 'w') as f:
        openbrace = "{"
        closebrace = "}"

        f.write(f"'use strict';{os.linesep}")
        f.write(f'{os.linesep}')

        # Reference: https://stackoverflow.com/questions/11725691/how-to-get-a-microtime-in-node-js
        f.write(f'const now = (unit) => {openbrace}{os.linesep}')
        f.write(f'  const hrTime = process.hrtime();{os.linesep}')
        f.write(f'  switch (unit) {openbrace}{os.linesep}')
        f.write(f"    case 'milli':{os.linesep}")
        f.write(
            f'      return hrTime[0] * 1000 + hrTime[1] / 1000000;{os.linesep}')
        f.write(f"    case 'micro':{os.linesep}")
        f.write(
            f'      return hrTime[0] * 1000000 + hrTime[1] / 1000;{os.linesep}')
        f.write(f"    case 'nano':{os.linesep}")
        f.write(f'    default:{os.linesep}')
        f.write(
            f'      return hrTime[0] * 1000000000 + hrTime[1];{os.linesep}')
        f.write(f'  {closebrace}{os.linesep}')
        f.write(f'{closebrace};{os.linesep}')
        f.write(f'{os.linesep}')

        for key in mapfile:
            log.info("Processing key \"%s\"", key)
            functionParams = []
            functionExpressions = []
            divider = ""
            stringify=False

            if "passthrough" in mapfile[key] and mapfile[key]["passthrough"] == "true":
                continue

            if "stringifyParameters" in mapfile[key] and mapfile[key]["stringifyParameters"] == "true":
                stringify = True

            if "parameters" in mapfile[key]:
                functionParams = mapfile[key]["parameters"]
                log.info('Parameters for operation "%s" are "%s"',
                         key, functionParams)
                for param in functionParams:
                    functionExpressions.append(getReplacementExpression(param, stringify))
                    divider = " | "

            directResult = False
            if "directResult" in mapfile[key]:
                directResult = (mapfile[key]["directResult"] == "true")

            scriptname = mapfile[key]["script"]
            target = mapfile[key]["target"]
            inputscript = os.path.join(inputdir, scriptname)
            outputscript = os.path.join(outputdir, scriptname)
            log.info("Copying %s to %s for %s", inputscript, outputscript, key)
            shutil.copy(inputscript, outputscript)

            if "local" == target:
                expression = f"/bin/sh ./service/{scriptname}"
            else:
                expression = f'cat ./service/{scriptname}{divider}{" | ".join(functionExpressions)} | exec kubectl -n {namespace} exec {target} -i -- /bin/sh'

            log.info('Expression for operation "%s" is "%s"', key, expression)

            f.write(
                f'exports.{key} = function ({",".join(functionParams)}) {openbrace}{os.linesep}')
            f.write(f"  var start = now('nano')" + f'{os.linesep}')
            f.write(f'  const exec = require("child_process").exec;' +
                    f'{os.linesep}')

            if "copyToTarget" in mapfile[key]:
                src=mapfile[key]["copyToTarget"]["src"]
                dst=mapfile[key]["copyToTarget"]["dst"]
                f.write(f"const fs = require('fs'){os.linesep}")
                f.write(f"var tmpfileName=`formdata_${openbrace}now('nano'){closebrace}.json`{os.linesep}")
                f.write(f'var tmpfilePath=`/tmp/${openbrace}tmpfileName{closebrace}`{os.linesep}')
                f.write(f'let data = JSON.stringify({src});{os.linesep}')
                f.write(f'fs.writeFileSync(tmpfilePath, data);{os.linesep}')

            f.write(
                f'  return new Promise(function (resolve, reject) {openbrace}{os.linesep}')

            if "copyToTarget" in mapfile[key]:
                f.write(f'        exec(`kubectl get pods -l=app={dst} -n chaordicledger | grep -v "NAME" | cut -d " " -f1`, (error, stdout, stderr) => {openbrace}{os.linesep}')
                f.write(f'        if (error) {openbrace}{os.linesep}')
                f.write(f"          var end = now('nano'){os.linesep}")
                f.write('          resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })' + f'{os.linesep}')
                f.write(f'      {closebrace} else {openbrace}{os.linesep}')
                f.write(
                         '        var podname=stdout.trim()' + f'{os.linesep}')
                f.write( '        exec(`kubectl cp -n chaordicledger ${tmpfilePath} ${podname}:${tmpfileName}`, (error, stdout, stderr) => ' + f'{openbrace}{os.linesep}')
                f.write(f'        if (error) {openbrace}{os.linesep}')
                f.write(f"          var end = now('nano'){os.linesep}")
                f.write('           resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })' + f'{os.linesep}')
                f.write(f'        {closebrace} else {openbrace}{os.linesep}')

            f.write(
                        f'    exec(`{expression}`, (error, stdout, stderr) => {openbrace}{os.linesep}')
            f.write(f"      var end = now('nano'){os.linesep}")
            f.write(f'      if (error) {openbrace}{os.linesep}')
            f.write(
                '        resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })' + f'{os.linesep}')
            f.write(
                f'      {closebrace} else {openbrace}{os.linesep}')
            if directResult:
                f.write('        resolve(stdout)' + f'{os.linesep}')
            else:
                f.write(
                    '        const obj = JSON.parse(stdout)' + f'{os.linesep}')
                f.write(
                    '        resolve({ "result": obj, "error": null, "durationInNanoseconds": end - start })' + f'{os.linesep}')
            if "copyToTarget" in mapfile[key]:
                f.write(f'              {closebrace}{os.linesep}')
                f.write(f'          {closebrace});{os.linesep}')
                f.write(f'        {closebrace}{os.linesep}')
                f.write(f'      {closebrace});{os.linesep}')
            f.write(f'      {closebrace}{os.linesep}')
            f.write(f'    {closebrace});{os.linesep}')
            f.write(f'  {closebrace});{os.linesep}')
            f.write(f'{closebrace}{os.linesep}')
            f.write(f'{os.linesep}')


if __name__ == "__main__":
    starttime = datetime.utcnow()

    (inputdir, mapfile, outputdir, outputfile, namespace) = validateArgs()
    configureLogging(outputdir)
    log.info("Input directory: %s", inputdir)
    log.info("Output directory: %s", outputdir)
    log.info("Output file: %s", outputfile)
    log.info("Namespace: %s", namespace)

    overlayServerImplementation(
        inputdir, mapfile, outputdir, outputfile, namespace)

    endtime = datetime.utcnow()
    log.info(
        "Done overlaying server implementation. Execution completed in %s", endtime-starttime)
