
{throwWithData} = utils = require '../../utils'
_ = require 'underscore'

KINDS = {}
KINDS[kind] = kind for kind in 'UNSIGNED SIGNED FLOAT COMPLEX BLOB'.split ' '
exports.KINDS = KINDS

exports.VARIABLE_SIZE = VARIABLE_SIZE = 0
exports.INF_PRECISION = INF_PRECISION = Infinity

exports.Type = class Type
    constructor: (options) ->
        options = _.defaults _.clone(options),
            byteSize: 1
            precision: 1
            jsNative: no
            array: Array
            getUnifiedType: (otherType) -> undefined

        {@name, @byteSize, @precision, @kind, @jsNative, @array, @getUnifiedType} = options
        if not @name
            throwWithData 'Name must be specified', options

        if @kind not of KINDS
            throwWithData 'kind must be one of KINDS', {options, KINDS}
        @isUnsigned = @kind is KINDS.UNSIGNED
        @isIntegral = @kind in [KINDS.UNSIGNED, KINDS.SIGNED]
        @isComplex = @kind is KINDS.COMPLEX
        @isBlob = @kind is KINDS.BLOB

        @isVariableSize = @byteSize is VARIABLE_SIZE
        @isInfPrecision = @precision is INF_PRECISION

        if @isInfPrecision and not @isVariableSize
            throwWithData "Cannot have inf precision without variable size",
                          options

        if @isBlob
            @precision = null
        else if not @isInfPrecision
            if not utils.isInteger(@byteSize) or @byteSize < 1
                throwWithData 'byteSize must be a positive integer', options

            if @precision > @byteSize
                throwWithData 'precision must be <= byteSize', options

            if @array.BYTES_PER_ELEMENT? and
                    @array.BYTES_PER_ELEMENT isnt @precision
                throwWithData 'array.BYTES_PER_ELEMENT must match precision',
                              options

