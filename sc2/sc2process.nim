import strformat
import system
import osproc
import logging

import types

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

proc launch*(p: SC2Process) =
    logger.log(lvlInfo, "Launching sc2")
    p.process = startProcess(
        command = "/usr/bin/wine",
        workingDir = p.cwd,
        args = ["start", "/d", fmt"{p.cwd}/Support64/", "/unix",
                fmt"{p.cwd}/Versions/Base90136/SC2_x64.exe", "-listen", p.ip, "-port",
                p.port, "-dataDir", p.cwd, "-tempDir", "/tmp/SC2_0peqhatp", ]
    )

proc kill(p: SC2Process) =
    logger.log(lvlInfo, "Killing sc2")
    p.process.close()
    discard execCmd("/usr/bin/wineserver -k")

template withSC2Process*(process: SC2Process, body: untyped): untyped =
    # Alternatively: https://nim-lang.org/docs/manual.html#exception-handling-defer-statement
    process.launch
    try:
        body
    finally:
        # End process when done
        # I guess on linux this only kills the wine process, not the game?
        # if process.running:
        #     process.terminate
        #     process.kill
        # process.close
        process.kill
