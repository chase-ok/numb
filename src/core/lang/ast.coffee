
_ = require 'underscore'
{addLocationDataFn, locationDataToString, throwSyntaxError} = require './utils'

exports.addLocationDataFn = addLocationDataFn

exports.Node = class Node

    # For this node and all descendents, set the location data to `locationData`
    # if the location data is not already set.
    updateLocationDataIfMissing: (locationData) ->
        return this if @locationData
        @locationData = locationData

    # Throw a SyntaxError associated with this node's location.
    error: (message) ->
        throwSyntaxError message, @locationData

    toString: -> '<Node>'


exports.Container = class Container extends Node

    children: []

    eachChild: (fn) ->
        for child in @children when this[child]
            for node in _.flatten [this[child]]
                return this if fn(node) is no
        this

    updateLocationDataIfMissing: (locationData) ->
        super locationData
        @eachChild (child) ->
            child.updateLocationDataIfMissing locationData


exports.Literal = class Literal extends Node

    type: 'Literal'

    constructor: (@raw) ->

    toString: -> "<#{@type} [raw=#{@raw}]>"


exports.NumberNode = class NumberNode extends Literal
    type: 'Number'

exports.StringNode = class StringNode extends Literal
    type: 'String'

exports.Identifier = class Identifier extends Literal
    type: 'Identifier'


exports.ArrayNode = class ArrayNode extends Container

    constructor: (@values) ->

    children: ['values']

    toString: -> "<Array [values=#{@values}]>"


exports.Value = class Value extends Container

    constructor: (@value, @properties=[]) ->

    children: ['value', 'properties']

    add: (property) ->
        @properties = @properties.concat property
        this

    toString: -> "<Value [value=#{@value}, properties=#{@properties}]>"


exports.Access = class Access extends Container

    constructor: (@field) ->

    children: ['field']

    toString: -> "<Access [field=#{@field}]>"


exports.Call = class Call extends Container

    constructor: (@func, @args) ->

    children: ['func', 'args']

    toString: -> "<Call [func=#{@func}, args=#{@args}]>"


exports.Index = class Index extends Container

    constructor: (@index) ->

    children: ['index']

    toString: -> "<Index [index=#{@index}]>"


exports.Parens = class Parens extends Container
    
    constructor: (@expr) ->

    children: ['expr']

    toString: -> "( #{@expr} )"


exports.UnaryOp = class UnaryOp extends Container

    constructor: (@op, @expr) ->

    children: ['expr']

    toString: "<UnaryOp [op=#{@op}, expr=#{@expr}]>"


exports.BinaryOp = class BinaryOp extends Container

    constructor: (@op, @left, @right) ->

    children: ['left', 'right']

    toString: -> "<BinaryOp [op=#{@op}, left=#{@left}, right=#{@right}]>"
        






