import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

import types

# Helper functions to create protobuf objects in one go
proc newRequestStep*(count: uint32): RequestStep =
    result = newRequestStep()
    result.count = count

proc newRequest*(request: RequestStep): Request =
    result = newRequest()
    # result.id = id
    result.step = request

proc newRequestAction*(actions: seq[Action]): RequestAction =
    result = newRequestAction()
    result.actions = actions

proc newRequest*(request: RequestAction): Request =
    result = newRequest()
    # Crashes when setting id - assuming that it errors when sending same id multiple times
    # result.id = id
    result.action = request

proc newAction*(abilityId: int32, unitTags: seq[uint64], targetWorldSpacePos: Point2D): Action =
    let actionRawUnitCommand = newActionRawUnitCommand()
    actionRawUnitCommand.abilityId = abilityId
    actionRawUnitCommand.unitTags = unitTags
    actionRawUnitCommand.targetWorldSpacePos = targetWorldSpacePos
    # TODO queue https://github.com/Blizzard/s2client-proto/blob/bb587ce9acb37b776b516cdc1529934341426580/s2clientprotocol/raw.proto#L192

    let actionRaw = newActionRaw()
    actionRaw.unitCommand = actionRawUnitCommand

    result = newAction()
    result.actionRaw = actionRaw

proc newAction*(abilityId: int32, unitTags: seq[uint64], x: float32, y: float32): Action =
    # TODO queue param
    let target = newPoint2D()
    target.x = x
    target.y = y
    newAction(abilityId = abilityId, unitTags = unitTags, targetWorldSpacePos = target)

# proc newAction*(abilityId: int32, unitTags: seq[uint64], x: float32, y: float32): Action =
    # TODO target unit tag, e.g. abilities that target units like transfuse, inject

# proc newAction*(abilityId: int32, unitTags: seq[uint64]): Action =
    # TODO without target, e.g. stop command

# Create bot setup
proc newPlayerSetup*(
    race: Race,
    botName: string = "My amazing bot",
): PlayerSetup =
    result = newPlayerSetup()
    result.ftype = PlayerType.Participant
    result.race = race
    result.playerName = botName

# Create ai setup
proc newPlayerSetup*(
    race: Race,
    difficulty: Difficulty,
    aiBuild: AIBuild = AIBuild.RandomBuild,
): PlayerSetup =
    result = newPlayerSetup()
    result.ftype = PlayerType.Computer
    result.race = race

# Create game: custom bot vs built-in-AI
proc newGameSetup*(
    botObject: Bot,
    botRace: Race = Race.Random,
    botName: string = "My amazing bot",
    aiRace: Race = Race.Random,
    aiDifficulty: Difficulty = Difficulty.VeryEasy,
    aiBuild: AIBuild = AIBuild.RandomBuild,
    mapName: string,
    realtime: bool,
    randomSeed: uint32,
): GameSetup =
    let player1 = newPlayerSetup(race = botRace, botName = botName)
    let player2 = newPlayerSetup(race = aiRace, difficulty = aiDifficulty, aiBuild = aiBuild)
    result = GameSetup(player1: player1, player1bot: botObject, player2: player2, mapName: mapName, realtime: realtime,
            randomSeed: randomSeed)

# Create game: custom bot vs custom bot
proc newGameSetup*(
    bot1Object: Bot,
    bot1Race: Race = Race.Random,
    bot1Name: string = "My amazing bot1",
    bot2Object: Bot,
    bot2Race: Race = Race.Random,
    bot2Name: string = "My amazing bot2",
    aiBuild: AIBuild = AIBuild.RandomBuild,
    mapName: string,
    realtime: bool = false,
    randomSeed: uint32,
): GameSetup =
    let player1 = newPlayerSetup(race = bot1Race, botName = bot1Name)
    let player2 = newPlayerSetup(race = bot2Race, botName = bot2Name)
    result = GameSetup(player1: player1, player2: player2, mapName: mapName, realtime: realtime, randomSeed: randomSeed)
