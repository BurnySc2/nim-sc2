import strformat
import system
import osproc

type SC2Process* = object 
    ip*: string
    port*: string
    cwd*: string
    process: Process

proc launch*(p: var SC2Process) =
    echo "Launching sc2"
    p.process = startProcess(
        "/usr/bin/wine",
        p.cwd,
        ["start", "/d", fmt"{p.cwd}/Support64/", "/unix",
                fmt"{p.cwd}/Versions/Base90136/SC2_x64.exe", "-listen", p.ip, "-port",
                p.port, "-dataDir", p.cwd, "-tempDir", "/tmp/SC2_0peqhatp", ]
    )

proc kill(p: SC2Process) =
    echo "Killing sc2"
    p.process.close()
    discard execCmd("/usr/bin/wineserver -k")

template withSC2Process*(process: var SC2Process, body: untyped): untyped =
    process.launch
    try:
        body
    finally:
        process.kill
