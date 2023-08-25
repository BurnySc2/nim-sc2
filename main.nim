# Converted protobufs
import s2clientprotocol/sc2api_pb
import s2clientprotocol/raw_pb
import s2clientprotocol/common_pb
import s2clientprotocol/data_pb

import asyncdispatch
import logging
import os
import strformat
import sugar
import system

import sc2/bot
import sc2/client
import sc2/newType
import sc2/sc2process

var logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")

# Start game
# https://github.com/BurnySc2/python-sc2/blob/76e4a435732d4359e5bd9e15b6283a0498e212ca/sc2/sc2process.py#L139
const ip = "127.0.0.1"
const port = "38941"
const cwd = "/media/ssd480/Games/starcraft3/drive_c/Program Files (x86)/StarCraft II/"

proc main() {.async.} =
    let process: ref SC2Process = (ref SC2Process)(ip: ip, port: port, cwd: cwd)
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

        let bot: ref Bot = await newBot(client = client)

        # Run till game completed
        await bot.botLoop

        # Wait a bit
        sleep(1000)

        # Close when done
        client.disconnect
waitFor main()

# Run with
# nim c -r main.nim
# nim c -r -d:release main.nim
