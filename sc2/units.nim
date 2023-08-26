# Converted protobufs
import ../s2clientprotocol/raw_pb

import sugar

proc own*(units: seq[Unit]): seq[Unit] =
    result = collect:
        for unit in units:
            if unit.alliance == Alliance.Self:
                unit

proc ofType*(units: seq[Unit], unitType: uint32): seq[Unit] =
    result = collect:
        for unit in units:
            if unit.unitType == unitType:
                unit
