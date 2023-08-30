# nimble install ws
import ws

# Converted protobufs
import ../s2clientprotocol/sc2api_pb

import asyncdispatch
import logging
import strformat

import newType
import types

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

proc wsPath(c: Client): string =
    fmt"ws://{c.process.ip}:{c.process.port}/sc2api"

proc connect*(c: Client) {.async.} =
    let path = c.wsPath
    while c.ws == nil:
        try:
            c.ws = await newWebSocket(path)
        except WebSocketClosedError, OSError:
            await sleepAsync(100)
    c.wsConnected = true

proc disconnect*(c: Client) =
    c.wsConnected = false
    c.ws.close
    c.ws = nil

proc validateRequest*(request: Request) =
    let serialized = serialize(request)
    var deserialized: Request
    try:
        deserialized = newRequest(serialized)
    except IOError as e:
        logger.log(lvlError, fmt"Error deserializing the request: {request}")
        raise e
    assert $request == $deserialized, fmt"Error, deserializing the serialized request does not result in the same:\n\n{request} \n\n!=\n\n{deserialized}"

proc sendRequest(c: Client, request: Request): Future[Response] {.async.} =
    when not defined(release):
        # Dont run in release mode
        validateRequest(request)
    await c.ws.send(serialize(request))
    var data: seq[byte]
    try:
        data = await c.ws.receiveBinaryPacket()
    except WebSocketClosedError as e:
        logger.log(lvlError, "Error when receiving response. Request was:")
        logger.log(lvlError, &"  {request}")
        raise e
    result = newResponse(data)
    if result.error.len > 0:
        logger.log(lvlInfo, "Respone with error:")
        logger.log(lvlInfo, &"  {result}")
        logger.log(lvlInfo, "Request of previous response was:")
        logger.log(lvlInfo, &"  {request}")

# Sc2 api requests - interacton with the sc2 client ---------------------------
# https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/sc2api.proto#L84-L119
proc getAvailableMaps*(c: Client): Future[Response] {.async.} # Defined later
proc createGame*(c: Client, game: GameSetup): Future[Response] {.async.} =
    let request = newRequestCreateGame()
    let localMap = newLocalMap()
    localMap.mapPath = game.mapName

    # Validate that the requested map is available
    let mapsResponse = await c.getAvailableMaps
    let maps = mapsResponse.availableMaps.localMapPaths
    doAssert maps.contains(localMap.mapPath), fmt"Map '{localMap.mapPath}' was not found. Available maps are: {maps}"

    request.localMap = localMap
    request.playerSetup = @[game.player1, game.player2]
    request.realtime = game.realtime
    request.randomSeed = game.randomSeed
    let finalRequest = newRequest()
    finalRequest.createGame = request
    return await c.sendRequest(finalRequest)

proc joinGame*(c: Client, playerSetup: PlayerSetup): Future[Response] {.async.} =
    let request = newRequestJoinGame()
    request.race = playerSetup.race
    let options = newInterfaceOptions()
    options.raw = true
    options.score = true
    options.showCloaked = true
    options.showBurrowedShadows = true
    options.showPlaceholders = true
    options.rawAffectsSelection = true
    options.rawCropToPlayableArea = true
    request.options = options
    let finalRequest = newRequest()
    finalRequest.joinGame = request
    return await c.sendRequest(finalRequest)

proc restartGame*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc startReplay*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc quickSave*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc quickLoad*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc quit*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc getGameInfo*(c: Client): Future[Response] {.async.} =
    let request = newRequestGameInfo()
    let finalRequest = newRequest()
    finalRequest.gameInfo = request
    return await c.sendRequest(finalRequest)

proc getObservation*(c: Client): Future[Response] {.async.} =
    let request = newRequestObservation()
    let finalRequest = newRequest()
    finalRequest.observation = request
    return await c.sendRequest(finalRequest)

proc sendActions*(c: Client, actions: seq[Action]): Future[Response] {.async.} =
    # TODO Dont send request if actions list empty?
    return await c.sendRequest(newRequest(request = newRequestAction(actions = actions)))

proc obsAction*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc step*(c: Client, count: uint32): Future[Response] {.async.} =
    return await c.sendRequest(newRequest(request = newRequestStep(count = count)))

proc getGameData*(c: Client): Future[Response] {.async.} =
    let request = newRequestData()
    request.abilityId = true
    request.unitTypeId = true
    request.upgradeId = true
    request.buffId = true
    request.effectId = true
    let finalRequest = newRequest()
    finalRequest.data = request
    return await c.sendRequest(finalRequest)

proc query*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc saveReplay*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc mapCommand*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc replayInfo*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc getAvailableMaps*(c: Client): Future[Response] {.async.} =
    let request = newRequestAvailableMaps()
    let finalRequest = newRequest()
    finalRequest.availableMaps = request
    return await c.sendRequest(finalRequest)

proc saveMap*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc ping*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

proc debug*(c: Client): Future[Response] {.async.} =
    # TODO
    discard

when isMainModule:
    import ../s2clientprotocol/common_pb
    import ../s2clientprotocol/raw_pb

    let point = newPoint2D()
    point.x = 10
    point.y = 20
    assert $point == $newPoint2D(serialize(point))

    let actionRawUnitCommand = newActionRawUnitCommand()
    actionRawUnitCommand.abilityId = 1234
    actionRawUnitCommand.unitTags = @[1234.uint64]
    actionRawUnitCommand.targetWorldSpacePos = point
    # Print out the bytes
    # echo cast[seq[byte]](serialize(actionRawUnitCommand))
    # echo cast[seq[byte]](serialize(actionRawUnitCommand)).len - 2
    assert $actionRawUnitCommand == $newActionRawUnitCommand(serialize(actionRawUnitCommand))

    let actionRaw = newActionRaw()
    actionRaw.unitCommand = actionRawUnitCommand
    let serialized = serialize(actionRaw)
    let deserialized = newActionRaw(serialized)
    assert $actionRaw == $deserialized

    let action = newAction()
    action.actionRaw = actionRaw
    assert $action == $newAction(serialize(action))
