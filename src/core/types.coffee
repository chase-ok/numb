
_ = require 'underscore'
{throwWithData} = utils = require '../utils'

allTypes = []
allTypesByName = {}

exports.register = register = (type) ->
    if type not instanceof Type
        throwWithData 'Registered types must be instances of Type', {type}
    if type in allTypes
        throwWithData 'Cannot register a type more than once.', {type}
    for name in type.names when name of allTypesByName
        throwWithData "A type by name #{name} is already registered.", {type}

    allTypesByName[name] = type for name in type.names
    type.id = allTypes.push(type) - 1
    return type

exports.deregister = (type) ->
    if type not in allTypes
        throwWithData 'Type must be registered first', {type}

    delete allTypesByName[name] for name in type.names
    allTypes = _.without allTypes, type
    delete type.id

exports.all = -> allTypes.slice 0

exports.get = (name) ->
    if name not of allTypesByName
        throwWithData "No type by name #{name}", {name}
    allTypesByName[name]

KINDS = {}
KINDS[kind] = kind for kind in 'UNSIGNED SIGNED FLOAT COMPLEX OTHER'.split ' '
exports.KINDS = KINDS

exports.Type = class Type
    constructor: (options) ->
        @name = options.name or options.names[0]
        throw 'Either name or names must be specified' unless @name

        @names = options.names or [@name]
        @names.push @name unless @name in @names
        
        @byteSize = options.byteSize or 1
        if not utils.isInteger(@byteSize) or @byteSize <= 0
            throwWithData 'byteSize must be a positive integer', options

        @precision = options.precision or 1
        if not utils.isInteger(@precision) or @precision <= 0
            throwWithData 'precision must be a positive integer', options
        if @precision > @byteSize
            throwWithData 'precision must be <= byteSize', options
        
        @kind = options.kind or KINDS.FLOAT
        if @kind not of KINDS
            throwWithData 'kind must be one of KINDS', {options, KINDS}
        @unsigned = @kind is KINDS.UNSIGNED
        @integral = @kind in [KINDS.UNSIGNED, KINDS.SIGNED]
        @complex = @kind is KINDS.COMPLEX

exports.Int32 = Int32 = register new Type
    name: 'Int32'
    names: ['Int32', 'int', 'Integer']
    byteSize: 4
    precision: 4
    kind: KINDS.SIGNED
    array: Int32Array
    native: yes
    cast: (x) -> x|0
