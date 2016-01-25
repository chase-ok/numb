import { fromPairs, map } from 'lodash'
import { OPERATORS } from './supported'
import { OperatorNotSupportedError, UnknownOperandType, Registry } from './registry'
import { addNumberBuiltIns } from './built-in'

const registry = new Registry()
addNumberBuiltIns(registry)

export default {
    getRegistry() { return registry },
    OperatorNotSupportedError,
    UnknownOperandType,

    ...registry.makeCallers()
}
