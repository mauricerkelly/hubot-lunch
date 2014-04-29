# Description:
#   Manage the ordering of lunches primarily, but anything really.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   order me <your order> - to place an order
#   order for <name>: <their order> - to place an order for someone else
#   show my order - to refresh your memory
#   cancel my order - to go on hunger strike
#   cancel order for <name> - to cancel someone else's order
#   show all orders - to see who wants what
#   clear orders - reset the order list
#   lunch help - show all the commands
#
# Notes:
#   None
#
# Author:
#   mauricerkelly

log = require('winston')
level = process.env.LOG_LEVEL || 'warning'
log.level = level.toLowerCase()

module.exports = (robot) ->

  robot.brain.data.lunches =
    orders: {}
    last: []

  lunches =
    get: (name) ->
      log.debug "Fetching order for #{name}"
      robot.brain.data.lunches.orders[name]

    add: (name, order) ->
      log.debug "Adding order of #{order} for #{name}"
      robot.brain.data.lunches.orders[name] = order
      if name not in robot.brain.data.lunches.last
        log.debug("Putting #{name} to the end of the order list")
        robot.brain.data.lunches.last.push(name)

    all_orders: () ->
      log.debug "Returning all orders"
      return robot.brain.data.lunches.orders

    cancel: (name) ->
      log.debug "Cancelling order for #{name}"
      delete robot.brain.data.lunches.orders[name]
      user_index = robot.brain.data.lunches.last.indexOf name
      if user_index isnt -1
        robot.brain.data.lunches.last.splice(user_index, 1)

    clear: () ->
      log.debug "Clearing the entire order list"
      robot.brain.data.lunches.orders = {}
      robot.brain.data.lunches.last = []

    last_order: () ->
      log.debug "Fetching the last order"
      robot.brain.data.lunches.last[robot.brain.data.lunches.last.length - 1]

    order_count: () ->
      Object.keys(robot.brain.data.lunches.orders).length

  robot.hear /order me (.*)/i, (msg) ->
    username = msg.message.user.name
    msg.send "Ordering " + msg.match[1] + " for " + username
    lunches.add(username, msg.match[1])
    return

  robot.hear /order for (.*): (.*)/i, (msg) ->
    username = msg.match[1]
    msg.send "Ordering " + msg.match[2] + " for " + username
    lunches.add(username, msg.match[2])
    return

  robot.hear /show my order/i, (msg) ->
    username = msg.message.user.name
    order = lunches.get(username)
    if order == undefined
      msg.send "You have no order"
    else
      msg.send "You (#{username}) ordered: " + lunches.get(username)
    return

  robot.hear /show all orders/i, (msg) ->
    order_list = ""
    running_count = 1
    for own user, order of lunches.all_orders()
      order_list += running_count + ". " + order + " (by " + user + ")\n"
      running_count++

    if order_list isnt ""
      msg.send order_list
    else
      msg.send "There are no orders yet"
    return

  robot.hear /clear orders/i, (msg) ->
    lunches.clear()
    msg.send "POOF! All gone!"
    return

  robot.hear /cancel my order/i, (msg) ->
    username = msg.message.user.name
    order = lunches.get(username)
    if order == undefined
      msg.send "You have no order"
    else
      lunches.cancel(username)
      msg.send "Done. But you'll be hungry!"
    return

  robot.hear /cancel order for (.*)/i, (msg) ->
    username = msg.match[1]
    order = lunches.get(username)
    if order == undefined
      msg.send "There is no order for " + username
    else
      lunches.cancel(username)
      msg.send "But " + username + " will be hungry! On your head be it!"
    return

  robot.hear /^lunch help$/i, (msg) ->
    msg.send "order me <your order> - to place an order\n" +
      "order for <name>: <their order> - to place an order for someone else\n" +
      "show my order - to refresh your memory\n" +
      "cancel my order - to go on hunger strike\n" +
      "cancel order for <name> - to cancel someone else's order\n" +
      "show all orders - to see who wants what\n" +
      "clear orders - reset the order list\n"
    return
