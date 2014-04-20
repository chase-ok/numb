
should = require('chai').should()
types = require '../../src/core/types'

someTypeDescription =
    name: 'SomeType'
    names: ['some', 'some-type', 'some32']
    byteSize: 4
    precision: 4
    kind: types.KINDS.SIGNED
    array: Int32Array
    native: yes
    cast: (x) -> x|0

describe 'all()', ->
    {all} = types
    it 'return an array of Type', ->
        all().should.be.an('array')
        type.should.be.an.instanceof(types.Type) for type in all()
    it 'returns a fresh array on every call', ->
        all().should.not.be.equal all()

describe 'get(name)', ->
    {get, register, deregister, Type} = types
    someType = new Type someTypeDescription
    beforeEach -> register someType
    afterEach -> deregister someType

    it 'throws when given an unrecognized type name', ->
        should.throw -> get 'ThisIsntAType'
    it 'returns the type with @name', ->
        get(someType.name).should.be.equal someType
    it 'returns the type with one of @names', ->
        for name in someType.names
            get(name).should.be.equal someType

