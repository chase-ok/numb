
_ = require 'underscore'

{Type, KINDS} = require './type'
_.extend exports, require './type'

{register} = require './registry'
_.extend exports, require './registry'

console.log "shit"
exports.Int32 = register new Type
    name: 'Int32'
    names: ['Int32', 'int', 'Integer']
    byteSize: 4
    precision: 4
    kind: KINDS.SIGNED
    array: Int32Array
    jsNative: yes
