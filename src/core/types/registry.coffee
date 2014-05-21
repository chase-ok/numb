
_ = require 'underscore'
{throwWithData} = utils = require '../../utils'

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

