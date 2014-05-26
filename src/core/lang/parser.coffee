
{Parser} = require 'jison'

# Derived mostly from the CoffeeScript parser

rules = []
rule = (match, result) -> rules.push [match, result]

rule '\\s+', '/* whitespace */'
rule '$', 'return "EOF"'

symRule = (symbol, regex) ->
    asString = regex.toString()
    rule asString[1...asString.length-1], "return '#{symbol}';"

symRule 'NUMBER',     /(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?\b/
symRule 'IDENTIFIER', /[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*/
symRule 'STRING',     /"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/

symRule '.', /\./
symRule ',', /\,/

symRule '(', /\(/
symRule ')', /\)/

symRule '[', /\[/
symRule ']', /\]/

symRule '+', /\+/
symRule '-', /-/

symRule 'UNARY', /[!|~]/
symRule 'LOGIC', /&&|\|\||&|\||\^/
symRule 'SHIFT', />>>|>>|<</

symRule 'COMPARE', /\=\=|!\=|<|>|<\=|>\=/
symRule 'MATH', /\*|\/|%/


unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

o = (patternString, action, options) ->
    patternString = patternString.replace /\s{2,}/g, ' '
    patternCount = patternString.split(' ').length
    return [patternString, '$$ = $1;', options] unless action
    action = if match = unwrap.exec action then match[1] else "(#{action}())"

    # All runtime functions we need are defined on "yy"
    action = action.replace /\bnew /g, '$&yy.'
    action = action.replace /\b(?:Block\.wrap|extend)\b/g, 'yy.$&'

    # Returns a function which adds location data to the first parameter passed
    # in, and returns the parameter.  If the parameter is not a node, it will
    # just be passed through unaffected.
    addLocationDataFn = (first, last) ->
        if not last
            "yy.addLocationDataFn(@#{first})"
        else
            "yy.addLocationDataFn(@#{first}, @#{last})"

    action = action.replace /LOC\(([0-9]*)\)/g, addLocationDataFn('$1')
    action = action.replace /LOC\(([0-9]*),\s*([0-9]*)\)/g, addLocationDataFn('$1', '$2')

    [patternString, "$$ = #{addLocationDataFn(1, patternCount)}(#{action});", options]

grammar =
    Root: [
        o 'Expression EOF', -> $1
    ]

    Expression: [
        o 'Value'
        o 'Invocation'
        o 'Operation'
    ]

    Identifier: [
        o 'IDENTIFIER', -> new Identifier $1
    ]

    Literal: [
        o 'Identifier'
        o 'Array'
        o 'NUMBER', -> new NumberNode $1
        o 'STRING', -> new StringNode $1
    ]

    Value: [
        o 'Parenthetical', -> new Value $1
        o 'Literal', -> new Value $1
        o 'Value Access', -> $1.add $2
        o 'Invocation Access', -> new Value $1, [].concat $2
    ]

    Access: [
        o '. Identifier', -> new Access $2
        o 'Index'
    ]

    Index: [
        o '[ Expression ]', -> new Index $2
    ]

    Invocation: [
        o 'Value Arguments', -> new Call $1, $2
        o 'Invocation Arguments', -> new Call $1, $2
    ]

    Arguments: [
        o '( )', -> []
        o '( ArgList OptComma )', -> $2
    ]

    Array: [
        o '[ ]', -> new ArrayNode []
        o '[ ArgList OptComma ]', -> new ArrayNode $2
    ]

    ArgList: [
        o 'Expression', -> [$1]
        o 'ArgList , Expression', -> $1.concat $3
    ]

    Parenthetical: [
        o '( Expression )', -> new Parens $2
    ]

    Operation: [
        o 'UNARY Expression', -> new UnaryOp $1 , $2
        o '- Expression', (-> new UnaryOp '-', $2), prec: 'UNARY'
        o '+ Expression', (-> new UnaryOp '+', $2), prec: 'UNARY'

        o 'Expression + Expression', -> new BinaryOp '+', $1, $3
        o 'Expression - Expression', -> new BinaryOp '-', $1, $3

        o 'Expression MATH Expression', -> new BinaryOp $2, $1, $3
        o 'Expression ** Expression', -> new BinaryOp $2, $1, $3
        o 'Expression SHIFT Expression', -> new BinaryOp $2, $1, $3
        o 'Expression COMPARE Expression', -> new BinaryOp $2, $1, $3
        o 'Expression LOGIC Expression', -> new BinaryOp $2, $1, $3
    ]

operators = [
    ['left', '.']
    ['left', '(', ')']
    ['right', '**']
    ['right', 'UNARY']
    ['left', 'MATH']
    ['left', '+', '-']
    ['left', 'SHIFT']
    ['left', 'COMPARE']
    ['left', 'LOGIC']
]

tokens = []
for name, alternatives of grammar
    grammar[name] = for alt in alternatives
        for token in alt[0].split ' '
            tokens.push token unless grammar[token]
        alt[1] = "return #{alt[1]}" if name is 'Root'
        alt

parser = new Parser
    lex: {rules}
    tokens: tokens.join ' '
    bnf: grammar
    operators: operators.reverse()
    startSymbol: 'Root'

generate = ->
    fs = require 'fs'
    code = parser.generateCommonJSModule()
    path = "#{__dirname}/parser.generated.js"
    fs.writeFileSync path, code

if require.main is module
    generate()
else
    {parser, parse} = require './parser.generated'
    exports.ast = parser.yy = require './ast'
    exports.parse = parse

