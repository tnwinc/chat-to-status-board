express = require 'express'
bodyParser = require 'body-parser'
Pusher = require 'pusher'
_ = require 'lodash'
commands = require './commands'

app = express()
pusher = new Pusher
  appId: process.env.PUSHER_APP_ID
  key: process.env.PUSHER_KEY
  secret: process.env.PUSHER_SECRET

app.use bodyParser()

getCommand = (text)->
  [ignore, type, argText] = text.match /board\s+(\w+)\s*(.*)/
  command = commands[type]?.response
  unless typeof command is 'function'
    command = commands.unknown.response
  command (argText.trim() or undefined)

app.post '/board', (req, res)->
  if req.body.token isnt process.env.SLACK_BOARD_TOKEN
    return res.send 403

  command = getCommand req.body.text
  if command.event
    pusher.trigger req.body.channel_name, command.event, (command.data || {})
  response =
    text: command.message
    username: req.body.user_name
  res.send 200, response

port = process.env.PORT || 5000
app.listen port, ->
  console.log "listening on #{port}..."
