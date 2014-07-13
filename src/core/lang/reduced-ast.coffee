
{isString} = _ = require 'underscore'
{TreePrinter} = require './utils'
{throwWithData} = require '../../utils'


class Compiler
    
    constructor: (@includes, @func) ->
        @code = ''
        @usedIncludes = []

    include: (ident) ->
        if ident not of @includes
            throwWithData "Reference #{indent} is missing.", @includes
        @usedIncludes.push ident unless ident in @usedIncludes

    print: (parts...) ->
        for part in parts
            if isString part
                @code += part
            else if (part|0) is part
                @code += "r#{part}"
            else
                part.compile this

    block: (stmts) ->
        @code += '{'
        stmt.compile this for stmt in stmts
        @code += '}'

    finalize: ->
        wrapper = ''
        for ident in @usedIncludes
            wrapper += "var #{ident} = includes.#{ident};"

        wrapper += 'return function ('
        offset = @func.numArgs
        wrapper += ("r#{i}" for i in [0...offset]).join ','
        wrapper += '){'
        wrapper += "var r#{i+offset};" for i in [0...@func.numInternalRegs]
        wrapper += @code
        wrapper += '};'

        new Function('includes', wrapper)(@includes)


exports.ReducedFunction = class ReducedFunction

    constructor: (@body, @numArgs, @numInternalRegs) ->

    compile: (includes, options={}) ->
        compiler = new Compiler includes, this
        stmt.compile compiler for stmt in @body
        compiler.finalize()


exports.Statement = class Statement
    children: []

    toString: ->
        printer = new TreePrinter()
        @printToTree printer
        printer.toString()
       
    eachChild: (fn) ->
        for child in @children when this[child]
            for node in _.flatten [this[child]]
                return this if fn(node) is no
        this

    getChildren: ->
        children = []
        @eachChild (child) -> children.push child
        children

    printToTree: (printer) ->
        name = @constructor.name
        name += " register #{@reg}" if @reg?
        printer.node name
        printer.children => @eachChild (child) ->
            child.printToTree printer

    compile: (compiler) -> throw 'Implement compile'


exports.Expression = class Expression extends Statement


exports.RegAssign = class RegAssign extends Statement
    children: ['expr']
    constructor: (@reg, @expr) ->

    compile: (compiler) ->
        compiler.print @reg, '=', @expr, ';'

exports.ArrayAssign = class ArrayAssign extends Statement
    children: ['index', 'expr']
    constructor: (@reg, @index, @expr) ->

    compile: (compiler) ->
        compiler.print @reg, '[', @index, ']=', @expr, ';'

exports.RangeLoop = class RangeLoop extends Statement
    children: ['start', 'stop', 'incr', 'body']
    constructor: (@reg, @start, @stop, @incr, @body) ->

    compile: (compiler) ->
        compiler.print 'for(', @reg, '=', @start, ';', @reg, '<', @stop, ';',
                               @reg, '+=', @incr, ')'
        compiler.block @body

exports.WhileLoop = class WhileLoop extends Statement
    children: ['test', 'body']
    constructor: (@test, @body) ->

    compile: (compiler) ->
        compiler.print 'while(', @test, ')'
        compiler.block @body

exports.If = class If extends Statement
    children: ['test', 'conseqBody', 'altBody']
    constructor: (@test, @conseqBody, @altBody) ->

    printToTree: (printer) ->
        printer.node 'If'
        printer.children =>
            @test.printToTree printer
            printer.node 'then'
            printer.children =>
                stmt.printToTree printer for stmt in @conseqBody
            printer.node 'else'
            printer.children =>
                stmt.printToTree printer for stmt in @altBody

    compile: (compiler) ->
        compiler.print 'if(', @test, ')'
        compiler.block @conseqBody
        if @altBody
            compiler.print 'else'
            compiler.block @altBody
                
exports.NoOp = class NoOp extends Statement
    constructor: ->
    compile: (compiler) ->

exports.Return = class Return extends Statement
    children: ['expr']
    constructor: (@expr) ->

    compile: (compiler) ->
        compiler.print 'return ', @expr, ';'

exports.RegAccess = class RegAccess extends Expression
    constructor: (@reg) ->

    compile: (compiler) ->
        compiler.print @reg

exports.ArrayAccess = class ArrayAccess extends Expression
    children: ['index']
    constructor: (@reg, @index) ->

    compile: (compiler) ->
        compiler.print @reg, '[', @index, ']'

exports.Call = class Call extends Expression
    children: ['args']
    constructor: (@ident, @args) ->

    compile: (compiler) ->
        compiler.include @ident
        compiler.print @ident, '('
        for arg, i in @args
            if i is 0 then compiler.print arg
            else compiler.print ',', arg
        compiler.print ')'

exports.IntConst = class IntConst extends Expression
    constructor: (@value) ->

    printToTree: (printer) ->
        printer.node "IntConst #{@value}"

    compile: (compiler) ->
        compiler.print "#{@value}"

exports.FloatConst = class FloatConst extends Expression
    constructor: (@value) ->

    printToTree: (printer) ->
        printer.node "FloatConst #{@value}"

    compile: (compiler) ->
        compiler.print "#{@value}"
    
exports.BinaryOp = class BinaryOp extends Expression
    children: ['left', 'right']
    constructor: (@op, @left, @right) ->

    printToTree: (printer) ->
        printer.node "BinaryOp #{@op}"
        printer.children =>
            @left.printToTree printer
            @right.printToTree printer

    compile: (compiler) ->
        compiler.print '(', @left, ')', @op, '(', @right, ')'

exports.UnaryOp = class UnaryOp extends Expression
    children: ['expr']
    constructor: (@op, @expr) ->

    printToTree: (printer) ->
        printer.node "UnaryOp #{@op}"
        printer.children =>
            @expr.printToTree printer

    compile: (compiler) ->
        compiler.print @op, '(', @expr, ')'

###
if require.main is module
    console.log 'ok'
    i = new RegAccess 3
    j = new RegAccess 4
    func = new ReducedFunction([
            new RegAssign(4, new FloatConst(0)),
            new RangeLoop(3, new IntConst(0), new RegAccess(0), new IntConst(1), [
                new ArrayAssign(2, i, new BinaryOp('*', new RegAccess(1), new ArrayAccess(2, i))),
                new RegAssign(4, new Call('sin', [new BinaryOp('+', j, new ArrayAccess(2, i))])),
            ]),
            new Return(j),
        ],
        3, 2)
    compiled = func.compile(Math)
    array = [0...10]
    console.log compiled(3, 0.2, array)
    console.log array
###
