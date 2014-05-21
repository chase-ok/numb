

{Type, KINDS} = require './type'
exports.Type = Type
exports.KINDS = KINDS


exports.Int32 = Int32 = register new Type
    name: 'Int32'
    names: ['Int32', 'int', 'Integer']
    byteSize: 4
    precision: 4
    kind: KINDS.SIGNED
    array: Int32Array
    jsNative: yes
    cast: (x) -> x|0
