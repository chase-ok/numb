
_ = require 'underscore'
{addLocationDataFn, locationDataToString, throwSyntaxError} = require './utils'

exports.addLocationDataFn = addLocationDataFn


class TreePrinter
    constructor: (@indentIncr=4) ->
        @lines = []
        @indentLevel = 0

    node: (line) ->
        @lines.push (' ' for x in [0...@indentLevel]).join(' ') + line

    children: (childrenFunc) ->
        old = @indentLevel
        @indentLevel += @indentIncr
        childrenFunc()
        @indentLevel = old

    toString: ->
        @lines.join '\n'


exports.Node = class Node

    # For this node and all descendents, set the location data to `locationData`
    # if the location data is not already set.
    updateLocationDataIfMissing: (locationData) ->
        return this if @locationData
        @locationData = locationData

    error: (message) ->
        throwSyntaxError message, @locationData

    toString: ->
        printer = new TreePrinter()
        @printToTree printer
        printer.toString()
       
    printToTree: (printer) ->
        printer.node @constructor.name


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

    printToTree: (printer) ->
        super printer
        printer.children => @eachChild (child) ->
            child.printToTree printer


exports.Literal = class Literal extends Node

    constructor: (@raw) ->

    printToTree: (printer) ->
        printer.node "#{@constructor.name} #{@raw}"


exports.NumberNode = class NumberNode extends Literal

exports.StringNode = class StringNode extends Literal

exports.Identifier = class Identifier extends Literal


exports.ArrayNode = class ArrayNode extends Container

    constructor: (@values) ->

    children: ['values']


exports.Value = class Value extends Container

    constructor: (@value, @properties=[]) ->

    children: ['value', 'properties']

    add: (property) ->
        @properties = @properties.concat property
        this


exports.Access = class Access extends Container

    constructor: (@property) ->

    children: ['property']


exports.Call = class Call extends Container

    constructor: (@func, @args) ->

    children: ['func', 'args']


exports.Index = class Index extends Container

    constructor: (@index) ->

    children: ['index']


exports.Parens = class Parens extends Container
    
    constructor: (@expr) ->

    children: ['expr']


exports.UnaryOp = class UnaryOp extends Container

    constructor: (@op, @expr) ->

    children: ['expr']

    printToTree: (printer) ->
        printer.node "UnaryOp #{@op}"
        printer.children => @expr.printToTree printer


exports.BinaryOp = class BinaryOp extends Container

    constructor: (@op, @left, @right) ->

    children: ['left', 'right']

    printToTree: (printer) ->
        printer.node "BinaryOp #{@op}"
        printer.children =>
            @left.printToTree printer
            @right.printToTree printer

