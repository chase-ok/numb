
should = require('chai').should()
_ = require 'underscore'
{ast, parse} = require '../../../src/core/lang/parser'


parseWithSpace = (code) ->
    parts = code.split ' '
    results = []
    for i in [0..parts.length]
        for spacing in [' ', '  ', '\t', '\n', ' \t \n ']
            newParts = parts.slice()
            newParts.splice i, 0, spacing
            results.push parse newParts.join ' '
    results

accept = (codes...) ->
    should.not.throw -> parseWithSpace code for code in codes
reject = (codes...) ->
    should.throw -> parseWithSpace code for code in codes

# unwrap a value contained node
unvalue = (node) -> node.value

require('chai').use (chai, utils) ->
    chai.Assertion.addMethod 'eqlNode', (node) ->
        @assert @_obj.equals(node),
                "Expected\n#{@_obj.toString()}\nto equal \n#{node.toString()}",
                "Expected\n#{@_obj.toString()}\nnot to equal\n#{node.toString()}",
                node

describe 'parse(code)', ->
    describe 'numbers', ->
        it 'accepts integers of any length', ->
            accept '123', '1234567891234567890123456'
        it 'rejects integers starting with 0', ->
            reject '0123'
        it 'accepts decimal numbers of any length', ->
            accept '102.345682', '0.0', '123456789.123456789123456789'
        it 'rejects decimal numbers starting or ending with .', ->
            reject '.1234', '1234.'
        it 'rejects decimal numbers with more than one .', ->
            reject '123..0', '12.3.23', '0.123.45334.345'
        it 'accepts exponent notation', ->
            cases = '0e1 0e-1 0e+1 1.23e1 123.42e-1 435.34e-123'.split ' '
            accept cases...
            accept (c.toLowerCase() for c in cases)...
        it 'produces an NumberNode with the raw number string', ->
            sample = '123 102.345 0.0 0e1 0e-3 345e+454'.split ' '
            for num in sample
                for node in parseWithSpace num
                    unvalue(node).should.eqlNode new ast.NumberNode num
