# nimble install protobuf_serialization
import protobuf_serialization
import protobuf_serialization/proto_parser

import asyncdispatch

import os
import system

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

import sc2/sc2process
import sc2/client
# import sc2/proto

# Start game
# https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L139
const ip = "127.0.0.1"
const port = "38941"
const cwd = "/media/ssd480/Games/starcraft3/drive_c/Program Files (x86)/StarCraft II/"

var process: SC2Process = SC2Process(ip: ip, port: port, cwd: cwd)
withSC2Process(process):
    proc main() {.async.} =
        # Connect to websocket
        # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L204
        # https://github.com/treeform/ws#example-client-socket
        echo "Connecting to websocket"
        # Not sure why it needs to be like this
        # https://nim-lang.org/docs/manual.html#types-object-construction
        let client: ref Client = (ref Client)(process: process)
        await client.connect

        # Create game (= send which map to load)
        # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/controller.py#L22C15-L22C26
        await client.createGame

        # Join game as player (map loading will start after this request)
        await client.joinGame

        # Wait a bit
        sleep(1000)

        # Close when done
        client.disconnect
    waitFor main()

# End process when done
# I guess on linux this only kills the wine process, not the game?
# if process.running:
#     process.terminate
#     process.kill
# process.close

# Run with
# nim c -r main.nim
# nim c -r -d:release main.nim
