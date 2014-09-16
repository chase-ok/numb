
_ = require 'underscore'
utils = require '../../utils'

class FlatLooper extends utils.CsFunctionBuilder

  events: 'beforeLoop beforeDimension step afterDimension afterLoop'.split ' '

  constructor: (@nd) ->
    @_listeners = {}
    @_listeners[event] = [] for event in @events
    super [@shapeVar()]

  on: (event, listener) ->
    @_listeners[event].push listener
    return this

  indexVar: (dimension) -> "$index#{dimension}"
  lengthVar: (dimension) -> "$length#{dimension}"
  shapeVar: -> "$shape"

  _emit: (event, listenerArgs...) ->
    for listener in @_listeners[event]
      listener listenerArgs..., this

  build: ->
    for dim in [0...@nd]
      @line "#{@lengthVar dim} = #{@shapeVar()}[#{dim}]"
    @_emit "beforeLoop"

    for dim in [0...@nd]
      @line "for #{@indexVar dim} in [0...#{@lengthVar dim}] by 1"
      @indent()
      @_emit "beforeDimension", dim

    @_emit "step"

    for dim in [@nd-1..0] by -1
      @_emit "afterDimension", dim
      @dedent()

    @_emit "afterLoop"
    @line "return"
    return super()

exports.flatLoop = (nd, callback) ->
  looper = new FlatLooper nd
  callback looper
  return looper.build()