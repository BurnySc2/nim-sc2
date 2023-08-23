# Converted protobufs
import s2clientprotocol/sc2api_pb
import s2clientprotocol/raw_pb
import s2clientprotocol/common_pb

import asyncdispatch

import os
import system
import strformat

import sc2/sc2process
import sc2/client

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
        echo "Connecting to websocket"
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
        # TODO Request data
        # https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/sc2api.proto#L404-L418

        var gameLoop: uint32 = 0
        # Loop while game is not over
        while status == Status.in_game:
            # Request observation
            let responseObservation = await client.getObservation(gameLoop)
            # if responseObservation.observation.hasPlayerResult:
            #     # Game is over
            #     break
            let observation = responseObservation.observation.observation
            gameLoop = observation.gameLoop
            var raw: ObservationRaw = observation.raw_data

            # https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/sc2api.proto#L373
            var actions: seq[Action]
            for i, unit in raw.units:
                if unit.alliance != Alliance.Self:
                    continue
                # https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/sc2api.proto#L630
                var action = newAction()
                # https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/raw.proto#L177C9-L177C18
                var actionRaw = newActionRaw()
                # https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/raw.proto#L185
                var aRawUnitCommand = newActionRawUnitCommand()
                aRawUnitCommand.abilityId = 3674 # Attack
                aRawUnitCommand.unitTags = @[unit.tag]
                # var target = newPoint2D()
                # target.x = 50
                # target.y = 50
                # aRawUnitCommand.targetWorldSpacePos = target
                aRawUnitCommand.targetWorldSpacePos = enemySpawn
                actionRaw.unitCommand = aRawUnitCommand
                action.actionRaw = actionRaw
                # Error if populated!
                # action.gameLoop = gameLoop
                actions.add(action)
                # TODO why does it crash when sending more than one action?
                if actions.len > 0:
                    break

            # Send actions
            let responseAction = await client.sendActions(actions)

            # Request step
            let responseStep = await client.step(32)
            status = responseStep.status

            # Request query

            # Request map_command?
            # Request ping?
            # Request available_maps?
            # Request debug?
            # Send actions

            if gameLoop > cast[uint64](toInt(22.4 * 120)):
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
