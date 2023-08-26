# nimble install ws
import ws

# Converted protobufs
import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/common_pb

import asyncdispatch
import logging
import strformat

import sc2process
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

proc getAvailableMaps*(c: Client): Future[Response] {.async.} # Defined later
proc createGame*(c: Client): Future[Response] {.async.} =
    let request = newRequestCreateGame()
    let localMap = newLocalMap()
    localMap.mapPath = "(2)CatalystLE.SC2Map"

    # Validate that the requested map is available
    let mapsResponse = await c.getAvailableMaps
    let maps = mapsResponse.availableMaps.localMapPaths
    doAssert maps.contains(localMap.mapPath), fmt"Map '{localMap.mapPath}' was not found. Available maps are: {maps}"

    request.localMap = localMap
    let p1 = newPlayerSetup()
    p1.ftype = PlayerType.Participant
    let p2 = newPlayerSetup()
    p2.ftype = PlayerType.Computer
    p2.race = Race.Terran
    p2.difficulty = Difficulty.VeryHard
    request.playerSetup = @[p1, p2]
    request.realtime = false
    let finalRequest = newRequest()
    finalRequest.createGame = request
    return await c.sendRequest(finalRequest)

proc joinGame*(c: Client): Future[Response] {.async.} =
    let request = newRequestJoinGame()
    request.race = Race.Terran
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

proc getAvailableMaps*(c: Client): Future[Response] {.async.} =
    let request = newRequestAvailableMaps()
    let finalRequest = newRequest()
    finalRequest.availableMaps = request
    return await c.sendRequest(finalRequest)

proc getGameInfo*(c: Client): Future[Response] {.async.} =
    let request = newRequestGameInfo()
    let finalRequest = newRequest()
    finalRequest.gameInfo = request
    return await c.sendRequest(finalRequest)

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

proc getObservation*(c: Client): Future[Response] {.async.} =
    let request = newRequestObservation()
    let finalRequest = newRequest()
    finalRequest.observation = request
    return await c.sendRequest(finalRequest)

proc step*(c: Client, count: uint32): Future[Response] {.async.} =
    return await c.sendRequest(newRequest(request = newRequestStep(count = count)))

proc sendActions*(c: Client, actions: seq[Action]): Future[Response] {.async.} =
    # TODO Dont send request if actions list empty?
    return await c.sendRequest(newRequest(request = newRequestAction(actions = actions)))

when isMainModule:
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
