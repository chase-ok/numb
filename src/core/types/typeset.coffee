
_ = require 'underscore'
{throwWithData} = utils = require '../../utils'
{Type, KINDS, INF_PRECISION} = require './type'
{UNSIGNED, SIGNED, FLOAT, COMPLEX, BLOB} = KINDS

exports.TypeSet = class TypeSet
    constructor: ->
        @_byPrecision = []
        @_blobs = []
        @_byName = {}

    add: (type) ->
        if @_differentTypeSameName type
            throwWithData "Set already contains a type with the same name", {type}
        @_byName[type.name] = type

        if type.isBlob
            @_blobs.push type unless type in @_blobs
            return this

        prec = @_byPrecision[type.precision] ?= {}
        if prec[type.kind]?
            throwWithData "A type of the same kind and precision is already in 
                           this type set", {type}
        prec[type.kind] = type

        return this

    remove: (type) ->
        return if @_differentTypeSameName type
        delete @_byName[type.name]

        if type.isBlob
            @_blobs.remove type
        else if @_byPrecision[type.precision][type.kind] is type
            delete @_byPrecision[type.precision][type.kind]
        return this
    
    _differentTypeSameName: (type) ->
        @_byName[type.name] and @_byName[type.name] isnt type

    all: -> _.values @_byName

    has: (type) ->
        if type.isBlob then type in @_blobs
        else @_byPrecision[type.precision][type.kind] is type

    get: (name) -> @_byName[name]

    makeUnifyFunc: (baseType) ->
        if not @has baseType
            throwWithData "baseType must be in type set", {baseType}

        kindOrder = [UNSIGNED, SIGNED, FLOAT, COMPLEX]
        getKindIndex = ({kind}) -> kindOrder.indexOf kind

        precOrder = _.chain @_byPrecision
            .keys()
            .sortBy (p) -> if p is INF_PRECISION then Infinity else p
            .map (p) -> +p
            .value()
        getPrecIndex = ({precision}) -> precOrder.indexOf precision
        
        unifications = {}
        for other in @all()
            if baseType is other
                result = baseType
            else if baseType.isBlob or other.isBlob
                result = baseType.getUnifiedType(other) or
                         other.getUnifiedType(baseType)
            else
                p = Math.max getPrecIndex(baseType), getPrecIndex(other)
                if baseType.precision is other.precision then p++
                p = Math.min(p, precOrder.length-1)

                k = Math.max getKindIndex(baseType), getKindIndex(other)

                startP = p
                startK = k
                while not (result = @_byPrecision[precOrder[p]][kindOrder[k]])
                    if ++p >= precOrder.length
                        p = startP
                        break unless ++k < kindOrder.length

            unifications[other.name] = result

        return (other) -> unifications[other.name]

    clone: ->
        cloned = new TypeSet()
        for types, precision in @_byPrecision
            cloned._byPrecision[precision] = _.clone types
        cloned._byName = _.clone @_byName
        cloned._blobs = @_blobs.slice 0
        cloned

