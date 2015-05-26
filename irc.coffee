events = require "events"
net = require "net"

splitAndEmitData = (client, data) ->
  if data.slice(-2) is "\r\n"
    for line in (client.buffer + data).split "\r\n"
      continue if not line
      args = ["data"]
      line = line.slice 1 if line.slice(0, 1) is ":"
      index = line.indexOf ":"
      index = line.length if index is -1
      for element in line.slice(0, index).split " "
        args.push element if element
      args.push line.slice(index + 1) if index isnt line.length
      client.emit args...
    client.buffer = ""
  else client.buffer += data

parseData = (client, data) ->
  if data[0] is "PING"
    client.raw "PONG :#{data[1]}"
  else if parseInt(data[1]) is 433
    num = client.nick.match(/_(\d)$/)?[1] ? 0
    client.nick = client.nick.replace(/_\d$/, "") + "_#{parseInt(num) + 1}"
    console.log "Nick in use, retrying with #{client.nick}"
    client.raw "NICK #{client.nick}"

class IRCClient extends events.EventEmitter
  constructor: (@nick, @user, @real) ->
    super()
    @client = null
    @buffer = ""

  connect: (host, port) ->
    that = this
    setImmediate ->
      that.client = net.connect
        host: host
        port: port
      that.client.setEncoding "utf8"

      that.client.on "connect", ->
        that.emit "connect"
        that.raw "USER #{that.user} 8 * :#{that.real}"
        that.raw "NICK #{that.nick}"

      that.client.on "data", (data) ->
        splitAndEmitData that, data

      that.on "data", (data...) ->
        parseData that, data

  raw: (data) ->
    that = this
    @client.write data + "\r\n", "utf8", ->
      that.emit "sent", data

  join: (channel) ->
    @raw "JOIN #{channel}"

module.exports =
  IRCClient: IRCClient
  RPL_WELCOME: 1
  RPL_YOURHOST: 2
  RPL_CREATED: 3
  RPL_MYINFO: 4
  RPL_ISUPPORT: 5
  RPL_STATSCONN: 250
  RPL_LUSERCLIENT: 251
  RPL_LUSEROP: 252
  RPL_LUSERUNKNOWN: 253
  RPL_LUSERCHANNELS: 254
  RPL_LUSERME: 255
  RPL_LOCALUSERS: 265
  RPL_GLOBALUSERS: 266
  RPL_NOTOPIC: 331
  RPL_TOPIC: 332
  RPL_NAMEREPLY: 353
  RPL_ENDOFNAMES: 366
  RPL_MOTD: 372
  RPL_MOTDSTART: 375
  RPL_ENDOFMOTD: 376
  ERR_NICKNAMEINUSE: 433