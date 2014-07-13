
{throwWithData} = utils = require '../../utils'
_ = require 'underscore'

KINDS = {}
KINDS[kind] = kind for kind in 'UNSIGNED SIGNED FLOAT COMPLEX OTHER'.split ' '
exports.KINDS = KINDS

exports.Type = class Type
    constructor: (options) ->
        options = _.defaults _.clone(options),
            byteSize: 1
            precision: 1
            jsNative: no
            name: options.names?[0]
            names: [options.name]
            array: Array

        {@name, @names, @byteSize, @precision, @kind, @jsNative, @array} =
                options
        if not @name
            throwWithData 'Either name or names must be specified', options

        @names.push @name unless @name in @names
        
        if not utils.isInteger(@byteSize) or @byteSize < 1
            throwWithData 'byteSize must be a positive integer', options

        if not utils.isInteger(@precision) or @precision < 1
            throwWithData 'precision must be a positive integer', options
        if @precision > @byteSize
            throwWithData 'precision must be <= byteSize', options
        
        if @kind not of KINDS
            throwWithData 'kind must be one of KINDS', {options, KINDS}
        @unsigned = @kind is KINDS.UNSIGNED
        @integral = @kind in [KINDS.UNSIGNED, KINDS.SIGNED]
        @complex = @kind is KINDS.COMPLEX

        if @array.BYTES_PER_ELEMENT? and
                @array.BYTES_PER_ELEMENT isnt @precision
            throwWithData 'array.BYTES_PER_ELEMENT must match precision',
                          options

