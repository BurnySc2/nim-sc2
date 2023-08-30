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
import unit
import units
import types

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

proc observationRaw*(bot: Bot): ObservationRaw = bot.observation.observation.rawData
proc enemySpawns*(bot: Bot): seq[Point2D] = bot.gameInfo.startRaw.startLocations
proc gameLoop*(bot: Bot): uint32 = bot.observation.observation.gameLoop

# proc newBot*(): Bot =
#     # Init variables
#     result = Bot(status: Status.unknown)

proc initBot*(bot: Bot) {.async.} =
    let gameDataResponse = await bot.client.getGameData
    bot.status = gameDataResponse.status
    bot.gameData = gameDataResponse.data
    # Write to enum file?
    # Overwrite enum values when trying to access them? Dont crash when enum doesnt exist
    # for i, unit in gameData.data.units[0..100]:
    #     echo $unit

    let gameInfoResponse = await bot.client.getGameInfo
    bot.status = gameInfoResponse.status
    bot.gameInfo = gameInfoResponse.gameInfo

    assert bot.enemySpawns.len == 1, "Requires two player map"

method onStart*(bot: Bot) {.async.} =
    discard

method step*(bot: Bot) {.async.} =
    discard

# Alternatively something like this to avoid dynamic dispatch
# proc onStart*(bot: Bot) {.async.} =
#     discard
# proc step*(bot: Bot) {.async.} =
#     discard
# proc botLoop*[T: Bot](bot: T) {.async.} =

proc botLoop*(bot: Bot) {.async.} =
    await bot.initBot
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
