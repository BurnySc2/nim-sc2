# Converted protobufs
import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

import newType

proc attack*(unit: Unit, target: Point2D): Action =
    newAction(
        abilityId = 3674,
        unitTags = @[unit.tag],
        targetWorldSpacePos = target
    )
