# Converted protobufs
import s2clientprotocol/sc2api_pb
import s2clientprotocol/raw_pb
import s2clientprotocol/common_pb
import s2clientprotocol/data_pb

import asyncdispatch
import os
import system
import strformat
import logging

import sc2/sc2process
import sc2/client
import sc2/newType

var logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

# Start game
# https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L139
const ip = "127.0.0.1"
const port = "38941"
const cwd = "/media/ssd480/Games/starcraft3/drive_c/Program Files (x86)/StarCraft II/"

proc main() {.async.} =
    var process: SC2Process = SC2Process(ip: ip, port: port, cwd: cwd)
    withSC2Process(process):
        # Connect to websocket
        # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L204
        # https://github.com/treeform/ws#example-client-socket
        logger.log(lvlInfo, "Connecting to websocket")
        # Not sure why it needs to be like this
        # https://nim-lang.org/docs/manual.html#types-object-construction
        let client: ref Client = (ref Client)(process: process)
        await client.connect

        # Create game (= send which map to load)
        # https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/controller.py#L22C15-L22C26
        discard await client.createGame

        # Join game as player (map loading will start after this request)
        discard await client.joinGame

        # Request game info
        let gameInfo: Response = await client.getGameInfo
        let spawnLocations = gameInfo.gameInfo.startRaw.startLocations
        assert spawnLocations.len == 1, "Requires two player map"
        let enemySpawn = spawnLocations[0]
        echo fmt"Enemy spawn at {enemySpawn.x=} {enemySpawn.y=}"
        var status = gameInfo.status

        # Request data
        let gameData = await client.getGameData()
        # Write to enum file?
        # Overwrite enum values when trying to access them? Dont crash when enum doesnt exist
        # for i, unit in gameData.data.units[0..100]:
        #     echo $unit

        var gameLoop: uint32 = 0
        # Loop while game is not over
        while status == Status.inGame:
            # Request observation
            let responseObservation = await client.getObservation(gameLoop)
            # if responseObservation.observation.hasPlayerResult:
            #     # Game is over
            #     break
            let observation = responseObservation.observation.observation
            gameLoop = observation.gameLoop
            var raw: ObservationRaw = observation.rawData

            if gameLoop == 0:
                var unitActions: seq[Action]
                for i, unit in raw.units:
                    if unit.alliance != Alliance.Self:
                        continue
                    # echo $unit
                    unitActions.add(newAction(abilityId = 3674, # Attack
                    unitTags = @[unit.tag],
                            targetWorldSpacePos = enemySpawn))
                let responseAction = await client.sendActions(unitActions)

            # Request step
            let responseStep = await client.step(32)
            status = responseStep.status

            # Request query

            # Request map_command?
            # Request ping?
            # Request available_maps?
            # Request debug?
            # Send actions

            if gameLoop > (22.4 * 120).uint64:
                echo "Ending game, game ran for 120 seconds"
                break

        # Wait a bit
        sleep(1000)

        # Close when done
        client.disconnect
waitFor main()

# Run with
# nim c -r main.nim
# nim c -r -d:release main.nim
