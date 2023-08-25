import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

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
