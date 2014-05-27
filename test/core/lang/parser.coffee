
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

    describe 'identifiers', ->
        it 'accepts all JavaScript identifiers', ->
            accept 'a', '$', 'Az01AFED_de', '$123', '_'

        it 'rejects all non-JavaScript identifiers', ->
            reject '0abc', '0a', '0$'

        it 'produces an Indentifer node with the raw name string', ->
            sample = 'a $ asAsjlhdf$a $1234 aReally_long_identifier$stringWitheveryth1ng'.split ' '
            for ident in sample
                for node in parseWithSpace ident
                    unvalue(node).should.eqlNode new ast.Identifier ident

    describe 'strings', ->
        it 'accepts single and double quoted strings', ->
            accept "'some string'", '"some double string"',
                   "'some \"string\"'", '"some double \'string\'"'

        it 'produces a StringNode with the raw string', ->
            sample = ["'some \\n string'", '"some double \\t string"',
                      "'some \"string\"'", '"some\t \n double \\ \'string\'"']
            for str in sample
                unvalue(parse str).should.eqlNode new ast.StringNode str

    describe 'arrays', ->
        it 'accepts the empty array []', -> accept '[]', '[ ]'
        
        it 'accepts [comma separated Expressions]', ->
            accept '[1]', '[1, 2, 3]', '[[3, 4], [[[5]]]]'

        it 'accepts optional trailing commas', ->
            accept '[1]', '[1,]'

        it 'rejects unbalanced brackets', ->
            reject '[abc,', ' [[abc, def]', '345, sfd, a]'

        it 'produces an ArrayNode with an array of expressions', ->
            arr = unvalue(parse '[1, abc, [2]]')
            arr.should.be.instanceof ast.ArrayNode
            arr.values.length.should.equal 3
            unvalue(arr.values[2]).values.length.should.equal 1

    describe 'property access', ->
        it 'accepts chains of .property and [property] accesses', ->
            accept 'abc.def', 'abc.def.abc.$123', 'abc[def]', 'abc[def].$123[x]'
            accept 'a[[b]]'

        it 'accepts access before and after invocations', ->
            accept 'abc()[0]', 'abc.def().x', 'f().b[0]()'

        it 'rejects extraneous . and unmatched brackets', ->
            reject 'a..b', 'c[0', 'def.a[.b', 'xf]'

        it 'accepts access with numbers and arrays', ->
            accept '1. abc', '[3, 4, 5][0]', '3[0]', '[4].abc'

        it 'produces a Value node with an array of chained properties', ->
            value = new ast.Value new ast.Identifier 'abc'
            value.add new ast.Access new ast.Identifier 'def'
            value.add new ast.Index new ast.Value new ast.Identifier 'ghi'
            value.add new ast.Access new ast.Identifier 'xyz'
            parse('abc.def[ghi].xyz').should.eqlNode value

    describe 'slices', ->
        it 'accepts slices of the form a[start:stop:step]', ->
            accept 'a[1:2:3]', 'a[b[3]:abc:-4]', 'a[1e45:z():[1,2,3]]'

        it 'accepts slices missing one of start, stop, step', ->
            accept 'a[b:1]', 'a[1:2:]', 'a[:2:1]', 'a[1::2]'

        it 'accepts slices missing two of start, stop, step', ->
            accept 'a[b:]', 'a[b::]', 'a[:b]', 'a[:b:]', 'a[::b]'

        it 'accepts the empty slices : and ::', ->
            accept 'a[:]', 'a[::]'

        it 'rejects extraneous : and slices outside of []', ->
            reject 'a[:::]', 'a[]', '4:5:6', 'a[1::4:]'

        it 'produces a Slice node with start, stop, step', ->
            makeSlice = (start, stop, step) ->
                args = []
                for x in [start, stop, step]
                    args.push new ast.Value new ast.Identifier x if x
                new ast.Slice args...
            test = (code, slice) ->
                parse("x[#{code}]").properties[0].index.should.eqlNode slice

            test 'a:b:c', makeSlice 'a', 'b', 'c'
            test 'a:b', makeSlice 'a', 'b'
            test ':a:b', makeSlice null, 'a', 'b'
            test 'a::b', makeSlice 'a', null, 'b'
            test 'a:', makeSlice 'a'
            test ':a', makeSlice 'a'
            test '::a', makeSlice 'a'
            test ':', makeSlice()
                


                   

