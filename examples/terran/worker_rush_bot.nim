# Converted protobufs
import ../../s2clientprotocol/raw_pb

import ../../sc2/bot
import ../../sc2/types
import ../../sc2/unit
import ../../sc2/units

import asyncdispatch
import sugar

type WorkerRushBot* = ref object of Bot

method onStart*(bot: WorkerRushBot) {.async.} =
    let newActions = collect:
        for unit in bot.observationRaw.units.own.ofType(45):
            unit.attack(bot.enemySpawns[0])
    bot.actions &= newActions

when isMainModule:
    import ../../s2clientprotocol/sc2api_pb
    import ../../s2clientprotocol/common_pb
    import ../../sc2/newType
    import ../../sc2/launch
    let game: GameSetup = newGameSetup(
        botObject = WorkerRushBot(),
        botRace = Race.Terran,
        botName = "My amazing bot",
        aiRace = Race.Random,
        aiDifficulty = Difficulty.VeryEasy,
        aiBuild = AIBuild.RandomBuild,
        mapName = "(2)CatalystLE.SC2Map",
        realtime = false,
        randomSeed = 0,
    )
    echo waitFor runGame(game)

    # Run with
    # nim c -r main.nim
    # nim c -r -d:release main.nim
