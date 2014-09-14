
_ = require 'underscore'
utils = require '../../utils'

class exports.Looper extends utils.CsFunctionBuilder

  events: 'beforeLoop beforeDimension innerFunc afterDimension
           afterLoop'.split ' '

  constructor: (@nd) ->
    @_listeners = {}
    @_listeners[event] = [] for event in @events
    super [@innerFuncVar(), @shapeVar()]

  on: (event, listener) ->
    @_listeners[event].push listener
    return this

  indexVar: (dimension) -> "$index#{dimension}"
  lengthVar: (dimension) -> "$length#{dimension}"
  shapeVar: -> "$shape"
  innerFuncVar: -> "$f"

  _listen: (event, listenerArgs...) ->
    for listener in @_listeners[event]
      listener listenerArgs..., this

  build: ->
    for dim in [0...@nd] by 1
      @line "#{@lengthVar dim} = #{@shapeVar()}[#{dim}]"
    @_listen "beforeLoop"

    for dim in [0...@nd] by 1
      @line "for #{@indexVar dim} in [0...#{@lengthVar dim}] by 1"
      @indent()
      @_listen "beforeDimension", dim

    innerFuncArgs = []
    @_listen "innerFunc", (arg) -> innerFuncArgs.push "(#{arg})"
    @line "#{@innerFuncVar()}(#{innerFuncArgs.join ','})"

    for dim in [@nd-1..0] by -1
      @_listen "afterDimension", dim
      @dedent()

    @_listen "afterLoop"
    @line "return"
    super()
