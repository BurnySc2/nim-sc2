import unittest
import ../s2clientprotocol/common_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/sc2api_pb

suite "protobuf test suite":
    let point = newPoint2D()
    point.x = 10
    point.y = 20

    check:
        $point == $newPoint2D(serialize(point))

    let actionRawUnitCommand = newActionRawUnitCommand()
    actionRawUnitCommand.abilityId = 1234
    actionRawUnitCommand.unitTags = @[1234.uint64]
    actionRawUnitCommand.targetWorldSpacePos = point
    # Print out the bytes
    # echo cast[seq[byte]](serialize(actionRawUnitCommand))
    # echo cast[seq[byte]](serialize(actionRawUnitCommand)).len - 2
    check:
        $actionRawUnitCommand == $newActionRawUnitCommand(serialize(actionRawUnitCommand))

    let actionRaw = newActionRaw()
    actionRaw.unitCommand = actionRawUnitCommand
    let serialized = serialize(actionRaw)
    let deserialized = newActionRaw(serialized)
    check:
        $actionRaw == $deserialized

    let action = newAction()
    action.actionRaw = actionRaw
    check:
        $action == $newAction(serialize(action))
