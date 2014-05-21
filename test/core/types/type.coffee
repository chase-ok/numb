
should = require('chai').should()
_ = require 'underscore'
{Type, KINDS} = require '../../../src/core/types/type'


options =
    name: 'SomeType'
    names: ['Some', 'stype']
    byteSize: 4
    precision: 4
    kind: KINDS.SIGNED
    jsNative: no
    array: Array
    castFromNative: (x) -> x|0
    

describe 'Type', ->
    describe 'new Type(options)', ->
        it 'requires name or names to be specified', ->
            should.throw -> new Type _.omit options, ['name', 'names']
        it 'sets @name to name, defaulting to names[0]', ->
            new Type(options).name.should.be.equal options.name
            new Type(_.omit options, 'name').name
                .should.be.equal options.names[0]
        it 'sets @names to names, defaulting to [name]', ->
            new Type(options).names.should.be.eql options.names
            new Type _.omit options, 'names'
                .names.should.be.eql [options.name]
        it 'automatically includes name in @names', ->
            names = _.without options.names, options.name
            new Type _.defaults {names}, options
                .names.should.include options.name
        it 'sets @byteSize to byteSize, defaulting to 1', ->
            new Type(options).byteSize.should.be.equal options.byteSize
            new Type(_.omit options, 'byteSize', 'precision')
                .byteSize.should.be.equal 1
        it 'requires byteSize to be an integer >= 1', ->
            should.throw -> new Type(_.defaults {byteSize: 5.2}, options)
            should.throw -> new Type(_.defaults {byteSize: 0}, options)
            should.not.throw -> new Type(_.defaults {byteSize: 100}, options)
        it 'sets @precision to precision, defaulting to 1', ->
            new Type(options).precision.should.be.equal options.precision
            new Type(_.omit options, 'precision').precision.should.be.equal 1
        it 'requires precision to be an integer >= 1', ->
            should.throw ->
                new Type(_.defaults {byteSize: 10, precision: 5.2}, options)
            should.throw -> new Type(_.defaults {precision: 0}, options)
            should.not.throw ->
                new Type(_.defaults {byteSize: 100, precision: 100}, options)
        it 'requires precision to be <= byteSize', ->
            should.throw -> new Type(_.defaults {precision: 100}, options)
        it 'sets @kind to kind, throwing an error if not specified', ->
            should.throw -> new Type(_.omit options, 'kind')
        it 'requires @kind to be one of the keys of KINDS', ->
            for kind of KINDS
                should.not.throw -> new Type(_.defaults {kind}, options)
            should.throw -> new Type(_.defaults {kind: 'NOTAKIND'}, options)
        it 'sets @unsigned to true iff kind is UNSIGNED', ->
            for kind of KINDS
                new Type _.defaults {kind}, options
                    .unsigned.should.be.equal kind is KINDS.UNSIGNED
        it 'sets @integral to true iff kind is UNSIGNED or SIGNED', ->
            for kind of KINDS
                signed = kind is KINDS.UNSIGNED or kind is KINDS.SIGNED
                new Type _.defaults {kind}, options
                    .integral.should.be.equal signed
        it 'sets @complex to be true iff kind is COMPLEX', ->
            for kind of KINDS
                new Type _.defaults {kind}, options
                    .complex.should.be.equal kind is KINDS.COMPLEX
        it 'sets @jsNative to jsNative, defaulting to no', ->
            new Type(options).jsNative.should.be.equal options.jsNative
            new Type(_.omit options, 'jsNative').jsNative.should.be.false
        it 'sets @array to array, defaulting to Array', ->
            new Type(_.defaults {array: Int32Array, precision: 4}, options)
                .array.should.be.equal Int32Array
            new Type(_.omit options, 'array').array.should.be.equal Array
        it 'requires @array.BYTES_PER_ELEMENT, if present, to be @precision', ->
            withArray = {array: Int32Array}
            withArray.byteSize = withArray.precision =
                2*withArray.array.BYTES_PER_ELEMENT
            should.throw -> new Type _.defaults withArray, options
            withArray.precision = withArray.array.BYTES_PER_ELEMENT
            should.not.throw -> new Type _.defaults withArray, options




