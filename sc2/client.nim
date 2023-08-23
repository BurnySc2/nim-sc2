# nimble install protobuf_serialization
import protobuf_serialization

# nimble install ws
import asyncdispatch, ws

# Reduce compile time by a few seconds
const useProtoFiles = false
when useProtoFiles:
    import protobuf_serialization/proto_parser
    import_proto3 "../s2clientprotocol/sc2api.proto"
else:
    import proto

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

proc sendRequest(c: ref Client, request: Request): Future[Response] {.async.} =
    echo fmt"Sending: {request}"
    var encoded: seq[byte] = Protobuf.encode(request)
    if encoded.len == 0:
        # getGameInfo
        encoded = @[74.byte, 0.byte]
    assert encoded.len != 0
    echo fmt"Sending encoded: {encoded}"
    let encodedString: string = newString(encoded.len)
    copyMem(encodedString[0].unsafeAddr, encoded[0].unsafeAddr, encoded.len)
    # echo fmt"Sending encoded string: {encodedString}"
    await c.ws.send(encodedString)
    let data: seq[byte] = await c.ws.receiveBinaryPacket()
    echo fmt"Receiving raw: {data}"
    result = Protobuf.decode(data, Response)
    echo fmt"Receiving: {result}"

proc execute(c: ref Client, request: RequestCreateGame): Future[Response] {.async.} =
    return await c.sendRequest(Request(create_game: request))

proc execute(c: ref Client, request: RequestJoinGame): Future[Response] {.async.} =
    return await c.sendRequest(Request(join_game: request))

proc execute(c: ref Client, request: RequestGameInfo): Future[Response] {.async.} =
    return await c.sendRequest(Request(game_info: request))

# proc execute(c: ref Client, request: RequestQuit): Future[Response] {.async.} =
#     return await c.sendRequest(Request(quit: request))

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
    discard await c.execute request

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
    discard await c.execute request

proc getGameInfo*(c: ref Client) {.async.} =
    discard await c.execute(RequestGameInfo())

# proc quit*(c: ref Client) {.async.} =
#     discard await c.execute(RequestQuit())

