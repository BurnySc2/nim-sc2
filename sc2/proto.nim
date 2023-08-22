
import protobuf_serialization
# import protobuf_serialization/files/type_generator

# Attempt at reducing compile time by converting proto files to nim types
type
    AIBuild* = enum
        RandomBuild = 1
        Rush = 2
        Timing = 3
        Power = 4
        Macro = 5
        Air = 6
        
    Difficulty* = enum
        VeryEasy = 1
        Easy = 2
        Medium = 3
        MediumHard = 4
        Hard = 5
        Harder = 6
        VeryHard = 7
        CheatVision = 8
        CheatMoney = 9
        CheatInsane = 10

    Race* = enum
        NoRace = 0
        Terran = 1
        Zerg = 2
        Protoss = 3
        Random = 4

    PlayerType* = enum
        Participant = 1
        Computer = 2
        Observer = 3

    LocalMap* {.proto3.} = object
        map_path* {.fieldNumber: 1.}: string

    RequestCreateGame* {.proto3.} = object
        local_map* {.fieldNumber: 1.}: LocalMap
        player_setup* {.fieldNumber: 3.}: seq[PlayerSetup]
        realtime* {.fieldNumber: 6.}: bool

    InterfaceOptions* {.proto3.} = object
        raw* {.fieldNumber: 1.}: bool
        score* {.fieldNumber: 2.}: bool
        show_cloaked* {.fieldNumber: 3.}: bool
        show_burrowed_shadows* {.fieldNumber: 4.}: bool
        show_placeholders* {.fieldNumber: 5.}: bool
        raw_affects_selection* {.fieldNumber: 6.}: bool
        raw_crop_to_playable_area* {.fieldNumber: 7.}: bool

    RequestJoinGame* {.proto3.} = object
        race* {.fieldNumber: 1, pint.}: int32
        options* {.fieldNumber: 2.}: InterfaceOptions

    Request* {.proto3.} = object
        create_game* {.fieldNumber: 1.}: RequestCreateGame
        join_game* {.fieldNumber: 2.}: RequestJoinGame

    Response* {.proto3.} = object
        create_game* {.fieldNumber: 1.}: ResponseCreateGame
        join_game* {.fieldNumber: 2.}: ResponseJoinGame

    ResponseCreateGame* {.proto3.} = object
        error* {.fieldNumber: 1, pint.}: int32
        error_details* {.fieldNumber: 2.}: string

    ResponseJoinGame* {.proto3.} = object
        player_id* {.fieldNumber: 1, pint.}: int32
        error* {.fieldNumber: 2, pint.}: int32
        error_details* {.fieldNumber: 3.}: string

    PlayerSetup* {.proto3.} = object
        `type`* {.fieldNumber: 1, pint.}: int32

        # Only used for a computer player.
        race* {.fieldNumber: 2, pint.}: int32
        difficulty* {.fieldNumber: 3, pint.}: int32
        player_name* {.fieldNumber: 4.}: string
        ai_build* {.fieldNumber: 5, pint.}: int32
