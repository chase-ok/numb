
_ = require 'underscore'
{Type, KINDS, VARIABLE_SIZE, INF_PRECISION} = require './type'
{TypeSet} = require './typeset'

exports.typeSet = typeSet = new TypeSet()

create = (name, options) ->
    exports[name] = new Type _.defaults options, {name}
    typeSet.add exports[name]

ints =
    8: Int8Array
    16: Int16Array
    32: Int32Array

for bits, array of ints
    create "int#{bits}",
        kind: KINDS.SIGNED
        byteSize: +bits/8
        precision: +bits/8
        array: array
        jsNative: +bits is 32

uints  =
    8: Uint8Array
    16: Uint16Array
    32: Uint32Array

for bits, array of uints
    create "uint#{bits}",
        kind: KINDS.UNSIGNED
        byteSize: +bits/8
        precision: +bits/8
        array: array
        jsNative: no

floats =
    32: Float32Array
    64: Float64Array

for bits, array of floats
    create "float#{bits}",
        kind: KINDS.FLOAT
        byteSize: +bits/8
        precision: +bits/8
        array: array
        jsNative: +bits is 64
        
complexes =
    64: Float32Array
    128: Float64Array

for bits, array of complexes
    create "complex#{bits}", 
        kind: KINDS.COMPLEX
        byteSize: +bits/8
        precision: +bits/16
        array: array
        jsNative: no

if false
    bigs =
        Int: KINDS.SIGNED
        Float: KINDS.FLOAT
        Complex: KINDS.COMPLEX

    for name, kind of bigs
        create "big#{name}",
            kind: kind
            byteSize: VARIABLE_SIZE
            precision: INF_PRECISION
            array: Array
            jsNative: no

blobs =
    8: Uint8Array
    16: Uint16Array
    32: Uint32Array

for bits, array of blobs
    create "blob#{bits}",
        kind: KINDS.BLOB
        byteSize: +bits/8
        array: array

create 'string',
    kind: KINDS.BLOB
    byteSize: VARIABLE_SIZE
    array: Array
    getUnifiedType: (other) -> this

