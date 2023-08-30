import ../s2clientprotocol/sc2api_pb

import asyncdispatch
import os

import bot
import client
import newType
import sc2process
import types


# Run games which takes a single game setup
proc runGame*(game: GameSetup): Future[Result] {.async.} =
    # Player1 needs to be a bot object
    # Player2 needs to be a bot object or ai (not observer!)
    assert game.player1.ftype == PlayerType.Participant
    assert game.player2.ftype in [PlayerType.Participant, PlayerType.Computer]

    # TODO Find free ports

    # Start both sc2 clients (one after the other on linux due to wine?)

    # Try to websocket connect (timeout = 30sec, error afterwards)
    # Run create game on host while second client is starting
    const ip = "127.0.0.1"
    const portP1 = "38941"
    # const portP2 = "38942"
    const cwd = "/media/ssd480/Games/starcraft3/drive_c/Program Files (x86)/StarCraft II/"
    let processP1 = SC2Process(ip: ip, port: portP1, cwd: cwd)
    processP1.launch
    # let processP2 = SC2Process(ip: ip, port: portP2, cwd: cwd)
    # processP2.launch
    let clientP1 = Client(process: processP1)
    game.player1bot.client = clientP1
    await clientP1.connect

    # let clientP2 = Client(process: processP2)
    # game.player2bot.client = clientP2
    # await clientP2.connect

    discard await clientP1.createGame(game = game)
    discard await clientP1.joinGame(playerSetup = game.player1)
    # discard await clientP2.joinGame

    # Run till game completed
    await game.player1bot.botLoop

    # Wait a bit
    sleep(1000)

    # Close ws connection when done
    clientP1.disconnect
    # clientP2.disconnect

    processP1.kill
    # processP2.kill

# Run games which takes a seq of games
proc runGames*(games: seq[GameSetup]): Future[seq[Result]] {.async.} =
    # Try to re-use the sc2 clients without ending them
    discard

when isMainModule:
    import ../s2clientprotocol/common_pb
    import ../examples/terran/worker_rush_bot
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
    discard waitFor runGame(game)

    # Run with
    # nim c -r main.nim
    # nim c -r -d:release main.nim
