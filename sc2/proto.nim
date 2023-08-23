
import protobuf_serialization

# import protobuf_serialization/proto_parser
# import_proto3 "../s2clientprotocol/temp.proto"


# Attempt at reducing compile time by converting proto files to nim types
type
    LocalMap* {.proto3.} = object
        map_path* {.fieldNumber: 1.}: string

    RequestCreateGame* {.proto3.} = object
        local_map* {.fieldNumber: 1.}: LocalMap
        player_setup* {.fieldNumber: 3.}: seq[PlayerSetup]
        realtime* {.fieldNumber: 6.}: bool

    InterfaceOptions* {.proto3.} = object
        raw* {.fieldNumber: 1.}: bool
        score* {.fieldNumber: 2.}: bool
        feature_layer* {.fieldNumber: 3.}: bool
        render* {.fieldNumber: 4.}: bool
        show_cloaked* {.fieldNumber: 5.}: bool
        raw_affects_selection* {.fieldNumber: 6.}: bool
        raw_crop_to_playable_area* {.fieldNumber: 7.}: bool
        show_placeholders* {.fieldNumber: 8.}: bool
        show_burrowed_shadows* {.fieldNumber: 9.}: bool

    RequestJoinGame* {.proto3.} = object
        race* {.fieldNumber: 1, pint.}: int32
        options* {.fieldNumber: 3.}: InterfaceOptions

    Request* {.proto3.} = object
        create_game* {.fieldNumber: 1.}: RequestCreateGame
        join_game* {.fieldNumber: 2.}: RequestJoinGame
        # quit* {.fieldNumber: 8.}: RequestQuit
        game_info* {.fieldNumber: 9.}: RequestGameInfo

    Response* {.proto3.} = object
        create_game* {.fieldNumber: 1.}: ResponseCreateGame
        join_game* {.fieldNumber: 2.}: ResponseJoinGame
        # quit* {.fieldNumber: 8.}: ResponseQuit
        game_info* {.fieldNumber: 9.}: ResponseGameInfo
        id* {.fieldNumber: 97, pint.}: uint32
        error* {.fieldNumber: 98.}: seq[string]
        status* {.fieldNumber: 99, pint.}: int32

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

    RequestGameInfo* {.proto3.} = object
    # RequestQuit* {.proto3.} = object

    ResponseGameInfo* {.proto3.} = object
        map_name* {.fieldNumber: 1.}: string
        mod_names* {.fieldNumber: 6.}: seq[string]
        local_map_path* {.fieldNumber: 2.}: string
        player_info* {.fieldNumber: 3.}: seq[PlayerInfo]
        start_raw* {.fieldNumber: 4.}: StartRaw
        options* {.fieldNumber: 5.}: InterfaceOptions

    StartRaw* {.proto3.} = object
        map_size* {.fieldNumber: 1.}: Size2DI
        pathing_grid* {.fieldNumber: 2.}: ImageData
        terrain_height* {.fieldNumber: 3.}: ImageData
        placement_grid* {.fieldNumber: 4.}: ImageData
        playable_area* {.fieldNumber: 5.}: RectangleI
        start_locations* {.fieldNumber: 6.}: seq[Point2D]

    PlayerInfo* {.proto3.} = object
        player_id* {.fieldNumber: 1, pint.}: int32
        `type`* {.fieldNumber: 2, pint.}: int32
        race_requested* {.fieldNumber: 3, pint.}: int32
        race_actual* {.fieldNumber: 4, pint.}: int32
        difficulty* {.fieldNumber: 5, pint.}: int32
        ai_build* {.fieldNumber: 7, pint.}: int32
        player_name* {.fieldNumber: 6.}: string

    # common.proto
    ImageData* {.proto3.} = object
        bits_per_pixel* {.fieldNumber: 1, pint.}: int32
        size* {.fieldNumber: 2.}: Size2DI
        data* {.fieldNumber: 3, pint.}: seq[int32]

    RectangleI* {.proto3.} = object
        p0* {.fieldNumber: 1.}: PointI
        p1* {.fieldNumber: 2.}: PointI

    PointI* {.proto3.} = object
        x* {.fieldNumber: 1, pint.}: int32
        y* {.fieldNumber: 2, pint.}: int32

    Point2D* {.proto3.} = object
        x* {.fieldNumber: 1.}: float32
        y* {.fieldNumber: 2.}: float32

    Point* {.proto3.} = object
        x* {.fieldNumber: 1.}: float32
        y* {.fieldNumber: 2.}: float32
        z* {.fieldNumber: 3.}: float32

    Size2DI* {.proto3.} = object
        x* {.fieldNumber: 1, pint.}: int32
        y* {.fieldNumber: 2, pint.}: int32
