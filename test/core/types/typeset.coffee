
should = require('chai').should()
{create} = require '../../../src/core/types/registry'
{Type, KINDS} = require '../../../src/core/types/type'

createSomeType = (aliases=['SomeType', 'st']) -> new Type
    byteSize: 4
    precision: 4
    kind: KINDS.SIGNED
    jsNative: yes
    aliases: aliases
    array: Int32Array


describe 'Registry', ->
    reg = null
    beforeEach -> reg = create()

    describe 'register(type)', ->
        it 'takes instances of Type', ->
            should.throw -> reg.register {a: 1, b: 2}
            should.not.throw -> reg.register createSomeType()
        it 'is idempotent', ->
            type = reg.register createSomeType()
            type.should.be.equal reg.register type
        it 'throws an error if a type with the same name is already registered', ->
            type1 = createSomeType ['name1']
            type2 = createSomeType ['another', 'name1']
            reg.register type1
            should.throw -> reg.register type2
        it 'assigns a unique integer id and returns type', ->
            type1 = createSomeType ['t1']
            type2 = createSomeType ['t2']
            reg.register(type1).should.be.equal type1
            reg.register(type2).should.be.equal type2
            type1.id.should.not.be.equal type2.id

    describe 'deregister(type)', ->
        it 'does nothing if the type is not registered', ->
            should.not.throw -> reg.deregister createSomeType()
        it 'resets the id of type', ->
            type = createSomeType()
            reg.register type
            reg.deregister type
            should.not.exist(type.id)

    describe 'all', ->
        it 'returns an array of all registered types', ->
            types = for i in [0...4] 
                reg.register createSomeType ["type#{i}"]
            console.log types






###
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
###
