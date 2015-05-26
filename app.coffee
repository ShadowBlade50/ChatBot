fs = require "fs"
irc = require "./irc"

admins = JSON.parse fs.readFileSync __dirname + "/admins.json",
  encoding: "utf8"
admins = JSON.parse fs.readFileSync __dirname + "/commands.json",
  encoding: "utf8"

isAdmin = (nick, callback) ->
  if nick in admins
    console.log ""

PREFIX = "?"

client = new irc.IRCClient "TestBot", "testbot", "Test Bot"
client.connect "irc.esper.net", "6667"

client.on "data", (data...) ->
  parsed = true
  switch parseInt(data[1])
    when irc.RPL_WELCOME then client.raw "NICKSERV IDENTIFY q$pa?~lp}@gro#fr"
    when irc.RPL_MOTDSTART then console.log "MOTD blocked."
    when irc.RPL_MOTD, irc.RPL_ENDOFMOTD
    else parsed = false
  if data[1] is "NOTICE" and /You are now identified for.+/i.test data[3]
    client.join "#ShadowBlade"
  if data[1] is "PRIVMSG" and data[3].slice(0, 1) is PREFIX
    switch data[3].slice(1)
      when "quit" then client.raw "QUIT"
      else parsed = false
  console.log "RECV #{data}" if not parsed

client.on "sent", (data) ->
  console.log "SENT #{data}"

client.on 'message', (msg, chan, nick, user, host) ->
  client.raw "PRIVMSG NICKSERV :ACC ShadowBlade"
  client.raw "PRIVMSG #ShadowBlade :#{msg}"
  if msg is "quit" then client.raw "QUIT"
  if msg.slice(0, PREFIX.length) != PREFIX then return
  msg = msg.slice PREFIX.length