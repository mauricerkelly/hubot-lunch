expect = require("chai").expect
path = require("path")
Robot = require("hubot/src/robot")
TextMessage = require("hubot/src/message").TextMessage

test_command = (robot, command, expectation, done) ->
  robot.adapter.on "send", (envelope, strings) ->
    try
      regex = new RegExp (expectation)
      expect(strings[0]).match regex
      done()
    catch e
      done e
  robot.adapter.receive new TextMessage(robot.brain.userForId("1"), command)

describe 'lunch script', ->
  beforeEach (done) ->

    # create new robot, without http, using the mock adapter
    @robot = new Robot(null, "mock-adapter", false, "Hubot")
    @user = @robot.brain.userForId("1", name: "human", room: "lunch room")
    @robot.adapter.on "connected", ->

      # only load scripts we absolutely need, like auth.coffee
      process.env.HUBOT_AUTH_ADMIN = "1"
      @robot.loadFile path.resolve(path.join("node_modules/hubot/src/scripts")), "auth.coffee"

      # load the module under test and configure it for the
      # robot.  This is in place of external-scripts
      require("../index") @robot

      setTimeout done, 250

    @robot.run()

  afterEach ->
    @robot.shutdown()

  context 'when no orders have been placed', ->
    describe 'sending message "show my order"', ->
      it 'responds with "You have no order"', (done) ->
        test_command @robot, "show my order", "You have no order", done

    describe 'sending message "show all orders"', ->
      it 'responds with "There are no orders yet"', (done) ->
        test_command @robot, "show all orders", "There are no orders yet", done

    describe 'sending message "clear orders"', ->
      it 'responds with "POOF! All gone!"', (done) ->
        test_command @robot, "clear orders", "POOF! All gone!", done

    describe 'sending message "order me a sandwich"', ->
      it 'responds with "Ordering a sandwich for human"', (done) ->
        test_command @robot, "order me a sandwich", "Ordering a sandwich for human", done

    describe 'sending message "order for hubot: a sandwich"', ->
      it 'responds with "Ordering a sandwich for hubot"', (done) ->
        test_command @robot, "order for hubot: a sandwich", "Ordering a sandwich for hubot", done

  context 'when an order has been placed for the current user', ->
    beforeEach (done) ->
      @robot.adapter.receive new TextMessage(@user, "order me a sandwich")
      done()

    describe 'sending message "show all orders"', ->
      it 'displays the order in the order list', (done) ->
        test_command @robot, "show all orders", "1. a sandwich \\(by human\\)", done

    describe 'sending message "show my order"', ->
      it 'responds with "You (human) ordered: a sandwich"', (done) ->
        test_command @robot, "show my order", 'You \\(human\\) ordered: a sandwich', done

    describe 'sending message "cancel my order"', ->
      it 'responds with "Done. But you\'ll be hungry!"', (done) ->
        test_command @robot, "cancel my order", "Done. But you'll be hungry!", done

    context 'and the order is cancelled', ->
      beforeEach (done) ->
        @robot.adapter.receive new TextMessage(@user, "cancel my order")
        done()

      describe 'sending message "show my order"', ->
        it 'responds with "You have no order"', (done) ->
          test_command @robot, "show my order", 'You have no order', done

  context 'when an order has been placed for a named user', ->
    beforeEach (done) ->
      @robot.adapter.receive new TextMessage(@user, "order for Someone Else: a big sandwich")
      done()

    describe 'sending message "show all orders"', ->
      it 'displays the order in the order list', (done) ->
        test_command @robot, "show all orders", "1. a big sandwich \\(by Someone Else\\)", done

    describe 'sending message "cancel my order"', ->
      it 'responds with "You have no order"', (done) ->
        test_command @robot, "cancel my order", "You have no order", done

    describe 'sending message "cancel order for Another Person"', ->
      it 'responds with "There is no order for Another Person"', (done) ->
        test_command @robot, "cancel order for Another Person", "There is no order for Another Person", done

    describe 'sending message "cancel order for Someone Else"', ->
      it 'responds with "But Someone Else will be hungry! On your head be it!"', (done) ->
        test_command @robot, "cancel order for Someone Else", "But Someone Else will be hungry! On your head be it!", done

    context 'and the order is cancelled', ->
      beforeEach (done) ->
        @robot.adapter.receive new TextMessage(@user, "cancel order for Someone Else")
        done()

      describe 'sending message "show all orders"', ->
        it 'responds with "There are no orders yet"', (done) ->
          test_command @robot, "show all orders", "There are no orders yet", done

  context 'when an order has been placed for multiple users', ->
    beforeEach (done) ->
      @robot.adapter.receive new TextMessage(@user, "order me a small sandwich")
      @robot.adapter.receive new TextMessage(@user, "order for hubot: a medium sandwich")
      @robot.adapter.receive new TextMessage(@user, "order for hubot's friend: a big sandwich")
      done()

    describe 'sending message "show all orders"', ->
      it 'displays "a small sandwich" for the first order', (done) ->
        test_command @robot, "show all orders", "1. a small sandwich \\(by human\\)", done

    describe 'sending message "show all orders"', ->
      it 'displays "a medium sandwich" for the second order', (done) ->
        test_command @robot, "show all orders", "2. a medium sandwich \\(by hubot\\)", done

    describe 'sending message "show all orders"', ->
      it 'displays "a big sandwich" for the third order', (done) ->
        test_command @robot, "show all orders", "3. a big sandwich \\(by hubot's friend\\)", done

    describe 'sending message "clear orders"', ->
      it 'displays "POOF! All gone!"', (done) ->
        test_command @robot, "clear orders", "POOF! All gone!", done
