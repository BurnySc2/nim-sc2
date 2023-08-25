# Converted protobufs
import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

import asyncdispatch
import logging
import strformat
import sugar
import system

import client
import newType

var logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

type
    Bot* = object
        client*: ref Client
        gameData*: ResponseData
        gameInfo*: ResponseGameInfo
        observation*: ResponseObservation
        actions*: seq[Action]
        status*: Status

proc observationRaw*(bot: ref Bot): ObservationRaw = bot.observation.observation.rawData
proc enemySpawns*(bot: ref Bot): seq[Point2D] = bot.gameInfo.startRaw.startLocations
proc gameLoop*(bot: ref Bot): uint32 = bot.observation.observation.gameLoop

proc newBot*(client: ref Client): Future[ref Bot] {.async.} =
    # Init variables
    result = (ref Bot)()
    result.status = Status.unknown
    result.client = client

    let gameDataResponse = await result.client.getGameData
    result.status = gameDataResponse.status
    result.gameData = gameDataResponse.data
    # Write to enum file?
    # Overwrite enum values when trying to access them? Dont crash when enum doesnt exist
    # for i, unit in gameData.data.units[0..100]:
    #     echo $unit

    let gameInfoResponse = await result.client.getGameInfo
    result.status = gameInfoResponse.status
    result.gameInfo = gameInfoResponse.gameInfo

    assert result.enemySpawns.len == 1, "Requires two player map"

proc onStart(bot: ref Bot) {.async.} =
    let newActions = collect:
        for unit in bot.observationRaw.units:
            if unit.alliance != Alliance.Self:
                newAction(abilityId = 3674, # Attack
                unitTags = @[unit.tag], targetWorldSpacePos = bot.enemySpawns[0])
    bot.actions &= newActions

proc step(bot: ref Bot) {.async.} = 
    discard

proc botLoop*(bot: ref Bot) {.async.} =
    while bot.status == Status.inGame:
        # Request observation
        let responseObservation: Response = await bot.client.getObservation
        # if responseObservation.observation.hasPlayerResult:
        #     # Game is over
        #     break
        bot.observation = responseObservation.observation

        if bot.gameLoop == 0:
            await bot.onStart
        await bot.step

        if bot.actions.len > 0:
            let actionsResponse = await bot.client.sendActions(bot.actions)
            bot.status = actionsResponse.status
            # TODO handle actionsResponse.action.result
            bot.actions = @[]

        # Request step
        let responseStep = await bot.client.step(32)
        bot.status = responseStep.status

        if bot.gameLoop > (22.4 * 120).uint64:
            logger.log(lvlInfo, "Ending game, game ran for 120 seconds")
            break

        # Request query

        # Request map_command?
        # Request ping?
        # Request available_maps?
        # Request debug?
        # Send actions
