
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

    _linkPrecisions: ->
        prev = null
        for precision in _.keys(@_byPrecision).sort()
            types = @_byPrecision[precision]
            types.precision = precision
            continue if precision is INF_PRECISION

            prev?.next = types
            types.prev = prev
            prev = types

        @_byPrecision[INF_PRECISION].prev = prev

    makeUnifyFunc: (baseType) ->
        @_linkPrecisions()

        searchDown = (kind, prec) ->
            prec[kind] or (prec.prev and searchDown kind, prec.prev)
        searchUp = (kind, prec) ->
            prec[kind] or (prec.next and searchUp kind, prec.next)
        search = (kind, prec) ->
            searchUp(kind, prec) or searchDown(kind, prec)
        searchUpNext = (kind, prec) ->
            if prec.precision is INF_PRECISION
                prec[kind]
            else if prec.next? then searchUp kind, prec.next

        unifications = {}
        for other in @all()
            if baseType is other
                result = baseType
            else if baseType.isBlob or other.isBlob
                result = baseType.getUnifiedType(other) or
                         other.getUnifiedType(baseType)
            else if baseType.precision is other.precision
                prec = @_byPrecision[baseType.precision]

                if baseType.isIntegral and other.isIntegral
                    result = searchUpNext(SIGNED, prec) or search(FLOAT, prec)
                else if baseType.isComplex or other.isComplex
                    result = searchUpNext(COMPLEX, prec) or search(COMPLEX, prec)
                else
                    result = searchUpNext(FLOAT, prec) or search(FLOAT, prec)
            else
                [low, high] = [baseType, other]
                if low.precision > high.precision
                    [low, high] = [high, low]

                highPrec = @_byPrecision[high.precision]

                if high.isComplex or low.isComplex
                    result = search COMPLEX, highPrec
                else if not high.isIntegral or not low.isIntegral
                    result = search FLOAT, highPrec
                else if high.isUnsigned and not low.isUnsigned
                    result = searchUpNext(SIGNED, highPrec) or
                             search(FLOAT, highPrec)
                else
                    result = high

            unifications[other.name] = result

        return (other) -> unifications[other.name]

