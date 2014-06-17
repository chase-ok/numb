
{isString} = _ = require 'underscore'
{TreePrinter, reduceHashes} = require './utils'
{makeEnum, enumSet, throwWithData} = require '../../utils'

[TYPES, TYPE_TO_INT, INT_TO_TYPE] =
    makeEnum 'VOID INT FLOAT INT_ARRAY FLOAT_ARRAY UNKNOWN'
{UNKNOWN} = exports.TYPES = TYPES

SCALAR = enumSet TYPES, 'INT FLOAT'
ARRAY = enumSet TYPES, 'INT_ARRAY FLOAT_ARRAY'


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
        console.log @code
        wrapper = ''
        for ident in @usedIncludes
            wrapper += "var #{ident} = includes.#{ident};"

        wrapper += 'return function ('
        offset = @func.signature.length
        wrapper += ("r#{i}" for i in [0...offset]).join ','
        wrapper += '){'
        wrapper += "var r#{i+offset};" for i in [0...@func.numInternalRegs]
        wrapper += @code
        wrapper += '};'

        console.log wrapper
        new Function('includes', wrapper)(@includes)


exports.ReducedFunction = class ReducedFunction

    constructor: (@body, @signature, @numInternalRegs) ->
        @hash = reduceHashes (s.hash for s in @body)

    compile: (includes, options={}) ->
        compiler = new Compiler includes, this
        stmt.compile compiler for stmt in @body
        compiler.finalize()


nextNodeId = do ->
    current = 1
    -> current++

exports.Statement = class Statement
    children: []

    toString: ->
        printer = new TreePrinter()
        @printToTree printer
        printer.toString()
       
    equals: (other) ->
        other.nodeId is @nodeId and other.hash is @hash

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

bodyEquals = (body1, body2) ->
    return no unless body1.length is body2.length
    return no unless body1[i].equals body2[i] for i in [0...body1.length]
    yes

exports.Expression = class Expression extends Statement


exports.RegAssign = class RegAssign extends Statement
    nodeId: nextNodeId()
    children: ['expr']

    constructor: (@reg, @expr) ->
        @hash = reduceHashes [@nodeId, @reg, @expr.hash]

    equals: (other) ->
        super(other) and other.reg is @reg and other.expr.equals(@expr)

    compile: (compiler) ->
        compiler.print @reg, '=', @expr, ';'

exports.ArrayAssign = class ArrayAssign extends Statement
    nodeId: nextNodeId()
    children: ['index', 'expr']

    constructor: (@reg, @index, @expr) ->
        @hash = reduceHashes [@nodeId, @reg, @index.hash, @expr.hash]

    equals: (other) ->
        super(other) and other.reg is @reg and other.index.equals(@index) and \
            other.expr.equals(@expr)

    compile: (compiler) ->
        compiler.print @reg, '[', @index, ']=', @expr, ';'

exports.RangeLoop = class RangeLoop extends Statement
    nodeId: nextNodeId()
    children: ['start', 'stop', 'incr', 'body']

    constructor: (@reg, @start, @stop, @incr, @body) ->
        hashes = [@nodeId, @reg, @start.hash, @stop.hash, @incr.hash]
        hashes.push stmt.hash for stmt in @body
        @hash = reduceHashes hashes

    equals: (other) ->
        super(other) and other.reg is @reg and other.start.equals(@start) and \
            other.stop.equals(@stop) and other.incr.equals(@incr) and \
            bodyEquals other.body, body

    compile: (compiler) ->
        compiler.print 'for(', @reg, '=', @start, ';', @reg, '<', @stop, ';',
                               @reg, '+=', @incr, ')'
        compiler.block @body

exports.WhileLoop = class WhileLoop extends Statement
    nodeId: nextNodeId()
    children: ['test', 'body']

    constructor: (@test, @body) ->
        hashes = [@nodeId, @test]
        hashes.push stmt.hash for stmt in @body
        @hash = reduceHashes hashes

    equals: (other) ->
        super(other) and other.test.equals(@test) and \
            bodyEquals other.body, @body

    compile: (compiler) ->
        compiler.print 'while(', @test, ')'
        compiler.block @body

exports.If = class If extends Statement
    nodeId: nextNodeId()
    children: ['test', 'conseqBody', 'altBody']

    constructor: (@test, @conseqBody, @altBody) ->
        hashes = [@nodeId, @test.hash]
        hashes.push stmt.hash for stmt in @conseqBody
        hashes.push stmt.hash for stmt in @altBody

    equals: (other) ->
        super(other) and other.test.equals(@test) and \
            bodyEquals(other.conseqBody, @conseqBody) and \
            bodyEquals(other.altBody, @altBody)

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
    nodeId: nextNodeId()

    constructor: -> @hash = @nodeId

    compile: (compiler) ->

exports.Return = class Return extends Statement
    nodeId: nextNodeId()
    children: ['expr']

    constructor: (@expr) ->
        @hash = reduceHashes [@nodeId, @expr.hash]

    compile: (compiler) ->
        compiler.print 'return ', @expr, ';'

    equals: (other) ->
        super(other) and other.expr is @expr

exports.RegAccess = class RegAccess extends Expression
    nodeId: nextNodeId()

    constructor: (@reg) ->
        @hash = reduceHashes [@nodeId, @reg]

    compile: (compiler) ->
        compiler.print @reg

    equals: (other) ->
        other.nodeId is @nodeId and other.reg is @reg

exports.ArrayAccess = class ArrayAccess extends Expression
    nodeId: nextNodeId()
    children: ['index']

    constructor: (@reg, @index) ->
        @hash = reduceHashes [@nodeId, @reg, @index.hash]

    compile: (compiler) ->
        compiler.print @reg, '[', @index, ']'

    equals: (other) ->
        super(other) and other.reg is @reg and other.index.equals @index

exports.Call = class Call extends Expression
    nodeId: nextNodeId()
    children: ['args']

    constructor: (@ident, @args) ->
        hashes = [@nodeId]
        hashes.push @ident.charCodeAt i for i in [0...@ident.length]
        hashes.push arg.hash for arg in @args

    compile: (compiler) ->
        compiler.include @ident
        compiler.print @ident, '('
        for arg, i in @args
            if i is 0 then compiler.print arg
            else compiler.print ',', arg
        compiler.print ')'

    equals: (other) ->
        super(other) and other.ident is @ident and \
            bodyEquals other.args, @args

exports.IntConst = class IntConst extends Expression
    nodeId: nextNodeId()

    constructor: (@value) ->
        @hash = reduceHashes [@nodeId, @value]

    printToTree: (printer) ->
        printer.node "IntConst #{@value}"

    equals: (other) -> other.nodeId is @nodeId and other.value is @value

    compile: (compiler) ->
        compiler.print "#{@value}"

{sin} = Math
exports.FloatConst = class FloatConst extends Expression
    nodeId: nextNodeId()

    constructor: (@value) ->
        @hash = reduceHashes [@nodeId, (sin(@value)*0x7FFFFFFF)|0]

    printToTree: (printer) ->
        printer.node "FloatConst #{@value}"

    equals: (other) -> other.nodeId is @nodeId and other.value is @value

    compile: (compiler) ->
        compiler.print "#{@value}"
    
[BINARY_OPS, BINARY_OP_TO_INT] = makeEnum '+ - * / % ^ & | && || == < > <= >='
exports.BINARY_OPS = BINARY_OPS

COMMUTATIVE = enumSet BINARY_OPS, '+ * ^ & | =='

exports.BinaryOp = class BinaryOp extends Expression
    nodeId: nextNodeId()
    children: ['left', 'right']

    constructor: (@op, @left, @right) ->
        if COMMUTATIVE[@op] and @left.hash > @right.hash
            [@left, @right] = [@right, @left]
        @hash = reduceHashes [@nodeId, BINARY_OP_TO_INT[@op], @left.hash,
                              @right.hash]

    printToTree: (printer) ->
        printer.node "BinaryOp #{@op}"
        printer.children =>
            @left.printToTree printer
            @right.printToTree printer

    equals: (other) ->
        super(other) and other.op is @op and other.left.equals(@left) and \
            other.right.equals(@right)

    compile: (compiler) ->
        compiler.print '(', @left, ')', @op, '(', @right, ')'

[UNARY_OPS, UNARY_OP_TO_INT] = makeEnum '- ! ~'
exports.UnaryOp = class UnaryOp extends Expression
    nodeId: nextNodeId()
    children: ['expr']

    constructor: (@op, @expr) ->
        @hash = reduceHashes [@nodeId, UNARY_OP_TO_INT[@op], @expr.hash]

    printToTree: (printer) ->
        printer.node "UnaryOp #{@op}"
        printer.children =>
            @expr.printToTree printer

    equals: (other) ->
        super(other) and other.op is @op and other.expr.equals @expr

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
        [TYPES.INT, TYPES.FLOAT, TYPES.FLOAT_ARRAY], 2)
    compiled = func.compile({sin})
    array = [0...10]
    console.log compiled(3, 0.2, array)
    console.log array
###
