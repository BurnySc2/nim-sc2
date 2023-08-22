# nimble install protobuf_serialization
import protobuf_serialization
import protobuf_serialization/codec
import protobuf_serialization/proto_parser

# nimble install ws
import asyncdispatch, ws

import_proto3 "../s2clientprotocol/sc2api.proto"

import sc2process
import enums

import strformat

type Client* = object
    process*: SC2Process
    ws*: WebSocket
    wsConnected: bool

proc wsPath(c: ref Client): string =
    fmt"ws://{c.process.ip}:{c.process.port}/sc2api"

proc connect*(c: ref Client) {.async.} =
    let path = c.wsPath
    while c.ws == nil:
        try:
            c.ws = await newWebSocket(path)
        except WebSocketClosedError, OSError:
            await sleepAsync(100)
    c.wsConnected = true

proc disconnect*(c: ref Client) = 
    c.wsConnected = false
    c.ws.close
    c.ws = nil

proc execute(c: ref Client, request: RequestCreateGame | RequestJoinGame) {.async.} =
    var finalRequest = Request()
    when request is RequestCreateGame:
        finalRequest.create_game = request
    when request is RequestJoinGame:
        finalRequest.join_game = request
    let encoded: seq[byte] = Protobuf.encode(finalRequest)
    let encodedString: string = newString(encoded.len)
    copyMem(encodedString[0].unsafeAddr, encoded[0].unsafeAddr, encoded.len)
    await c.ws.send(encodedString)
    let data: seq[byte] = await c.ws.receiveBinaryPacket()
    let dataDecoded = Protobuf.decode(data, Response)
    echo dataDecoded
    # TODO Return response

proc createGame*(c: ref Client) {.async.} =
    let request = RequestCreateGame(
            local_map: LocalMap(
                map_path: "(2)CatalystLE.SC2Map",
        ),
        player_setup: @[
            PlayerSetup(
                type: PlayerType.Participant.ord,
                # race: 1,
            ),
            PlayerSetup(
                type: PlayerType.Computer.ord,
                # race: 1,
                    # difficulty: 1,
                race: Race.Terran.ord,
                difficulty: Difficulty.VeryHard.ord,
            ),
        ],
        realtime: false
    )
    await c.execute request

proc joinGame*(c: ref Client) {.async.} =
    let request = RequestJoinGame(
            race: Race.Terran.ord,
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
    await c.execute request


