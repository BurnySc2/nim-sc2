# nimble install ws
import ws

# Converted protobufs
import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

import strformat
import asyncdispatch

import sc2process

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
    await c.ws.send(serialize(request))
    let data: seq[byte] = await c.ws.receiveBinaryPacket()
    result = newResponse(data)
    if result.error.len > 0:
        echo result.id
        echo result.status
        echo result.error


proc createGame*(c: ref Client): Future[Response] {.async.} =
    var request = newRequestCreateGame()
    var localMap = newLocalMap()
    localMap.map_path = "(2)CatalystLE.SC2Map"
    request.local_map = localMap
    var p1 = newPlayerSetup()
    p1.ftype = PlayerType.Participant
    var p2 = newPlayerSetup()
    p2.ftype = PlayerType.Computer
    p2.race = Race.Terran
    p2.difficulty = Difficulty.VeryHard
    request.player_setup = @[p1, p2]
    request.realtime = false
    var finalRequest = newRequest()
    finalRequest.create_game = request
    return await c.sendRequest(finalRequest)

proc joinGame*(c: ref Client): Future[Response] {.async.} =
    var request = newRequestJoinGame()
    request.race = Race.Terran
    var options = newInterfaceOptions()
    options.raw = true
    options.score = true
    options.show_cloaked = true
    options.show_burrowed_shadows = true
    options.show_placeholders = true
    options.raw_affects_selection = true
    options.raw_crop_to_playable_area = true
    request.options = options
    var finalRequest = newRequest()
    finalRequest.join_game = request
    return await c.sendRequest(finalRequest)

proc getGameInfo*(c: ref Client): Future[Response] {.async.} =
    var request = newRequestGameInfo()
    var finalRequest = newRequest()
    finalRequest.game_info = request
    return await c.sendRequest(finalRequest)

proc getObservation*(c: ref Client, gameLoop: uint32): Future[Response] {.async.} =
    var request = newRequestObservation()
    request.gameLoop = gameLoop
    var finalRequest = newRequest()
    finalRequest.observation = request
    return await c.sendRequest(finalRequest)

proc step*(c: ref Client, count: uint32): Future[Response] {.async.} =
    var request = newRequestStep()
    request.count = count
    var finalRequest = newRequest()
    finalRequest.step = request
    return await c.sendRequest(finalRequest)

proc sendActions*(c: ref Client, actions: seq[Action]): Future[Response] {.async.} =
    # Dont send request if actions list empty?
    var actionsRequest = newRequestAction()
    actionsRequest.actions = actions
    var finalRequest = newRequest()
    finalRequest.action = actionsRequest
    return await c.sendRequest(finalRequest)
