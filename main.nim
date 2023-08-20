# nimble install protobuf_serialization
import protobuf_serialization
import protobuf_serialization/proto_parser

# nimble install ws
import asyncdispatch, ws

import strformat
import os
import system
import osproc

import_proto3 "s2clientprotocol/common.proto"
import_proto3 "s2clientprotocol/data.proto"
import_proto3 "s2clientprotocol/debug.proto"
import_proto3 "s2clientprotocol/error.proto"
import_proto3 "s2clientprotocol/query.proto"
import_proto3 "s2clientprotocol/raw.proto"
import_proto3 "s2clientprotocol/score.proto"
# import_proto3 "s2clientprotocol/spatial.proto"
# import_proto3 "s2clientprotocol/ui.proto"
import_proto3 "s2clientprotocol/sc2api.proto"

# let a = PointI(x: 1, y: 2)

# import typetraits
# echo a
# echo a.type.name
# echo fmt"{a}"
# echo fmt"{a}".type.name

# Start game
# https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L139
let ip = "127.0.0.1"
let port = "38941"
let cwd = "/media/ssd480/Games/starcraft3/drive_c/Program Files (x86)/StarCraft II/"
echo "Launching sc2"
var process: Process = startProcess(
    "/usr/bin/wine",
    cwd, 
    ["start", "/d", fmt"{cwd}/Support64/", "/unix", fmt"{cwd}/Versions/Base90136/SC2_x64.exe", "-listen", ip, "-port", port, "-dataDir", cwd, "-tempDir", "/tmp/SC2_0peqhatp"]
)

proc main() {.async.} =
    # Connect to websocket 
    # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L204
    let wsTarget = fmt"ws://{ip}:{port}/sc2api"
    # https://github.com/treeform/ws#example-client-socket
    echo "Connecting to websocket"
    var ws: WebSocket
    while ws == nil:
        try:
            ws = await newWebSocket(wsTarget)
        except WebSocketClosedError, OSError:
            sleep(1000)

    # Create game (= send which map to load)
    # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/controller.py#L22C15-L22C26
    let createGameRequest = Request(
        create_game: RequestCreateGame(
            local_map: LocalMap(
                map_path: "(2)CatalystLE.SC2Map",
            ),
            player_setup: @[
                PlayerSetup(
                    type: 1,
                    # race: 1,
                ),
                PlayerSetup(
                    type: 2,
                    race: 1,
                    difficulty: 7,
                ),
            ],
            realtime: false
        )
    )
    echo "Sending load map request"
    echo fmt"{createGameRequest}"
    let encoded: seq[byte] = Protobuf.encode(createGameRequest)
    echo encoded
    let encodedString: string = newString(encoded.len)
    copyMem(encodedString[0].unsafeAddr, encoded[0].unsafeAddr, encoded.len)
    echo encodedString
    await ws.send(encodedString)
    echo "Receiving"
    # https://github.com/treeform/ws/blob/5ac521b72d7d4860fb394e5e1f9f08cf480e9822/src/ws.nim#L436C6-L436C25
    let data: seq[byte] = await ws.receiveBinaryPacket()
    echo "Received"
    echo data
    let dataDecoded = Protobuf.decode(data, Response)
    echo dataDecoded

    # Join game as player (map loading will start after this request)
    let joinGameRequest = Request(
        join_game: RequestJoinGame(
            race: 1,
            options: InterfaceOptions(
                raw: true,
                score: true,
                show_cloaked: true,
                show_burrowed_shadows: true,
                show_placeholders: true,
                raw_affects_selection: true,
                raw_crop_to_playable_area: true,
            ),
        )
    )
    let encoded2: seq[byte] = Protobuf.encode(joinGameRequest)
    let encodedString2: string = newString(encoded2.len)
    copyMem(encodedString2[0].unsafeAddr, encoded2[0].unsafeAddr, encoded2.len)
    echo "Sending"
    await ws.send(encodedString2)
    echo "Receiving"
    # Next receive will be after the game has been loaded
    let data2: seq[byte] = await ws.receiveBinaryPacket()
    echo "Received"
    echo data2
    let dataDecoded2 = Protobuf.decode(data2, Response)
    echo "Decoding"
    echo dataDecoded2

    # Wait a bit
    sleep(1000)

    # close when done
    ws.close()

waitFor main()

# End process when done
# I guess on linux this only kills the wine process, not the game?
if process.running:
    process.terminate
    process.kill
process.close

# Run with
# nim c -r main.nim
# nim c -r -d:release main.nim
