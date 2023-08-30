# nimble install ws
import ws

# Converted protobufs
import ../s2clientprotocol/sc2api_pb
import ../s2clientprotocol/raw_pb
import ../s2clientprotocol/common_pb

import osproc

type
    SC2Process* = ref SC2ProcessObj
    SC2ProcessObj* = object
        ip*: string
        port*: string
        cwd*: string
        process*: Process
    Client* = ref ClientObj
    ClientObj* = object
        process*: SC2Process
        ws*: WebSocket
        wsConnected*: bool
    Bot* = ref BotObj
    BotObj* = object of RootObj
        client*: Client
        gameData*: ResponseData
        gameInfo*: ResponseGameInfo
        observation*: ResponseObservation
        actions*: seq[Action]
        status*: Status
        name*: string
    GameSetup* = ref GameSetupObj
    GameSetupObj* = object
        player1*: PlayerSetup
        player1bot*: Bot
        player2*: PlayerSetup
        player2bot*: Bot
        mapName*: string
        realtime*: bool
        randomSeed*: uint32
        # maxGameDurationSeconds: uint32
