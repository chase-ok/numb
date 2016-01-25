import { OPERATORS } from './supported'
import { memoize, uniqueId, set, map, forEach, includes, fromPairs } from 'lodash'
import { baseN } from 'js-combinatorics'

export class OperatorNotSupportedError extends TypeError {
    constructor(operator, operands) {
        super(`Operator ${operator.name} is not supported for ${operands}`)
        this.operator = operator
        this.operands = operands
    }
}

const operatorNotSupported = memoize(operator => (...operands) => { 
    throw new OperatorNotSupportedError(operator, operands)
})

export class UnknownOperandType extends TypeError {
    constructor(value) {
        super(`Unknown operand type for value ${value}`)
        this.value = value
    }
}

export class Registry {
    constructor() {
        this.idProperty = uniqueId('__operatorRegistryId')
        this.types = []
        this.operations = fromPairs(map(OPERATORS, ({ name }) => [name, []]))
    }

    getId(value) {
        const id = value[this.idProperty]
        if (+id !== id) throw new UnknownOperandType(value)
        return id
    }

    getIdFromType(type) {
        const { prototype } = type
        if (this.types[prototype[this.idProperty]] != type) {
            this.addType(type)
        }
        return prototype[this.idProperty]
    }

    addType(type) { 
        type.prototype[this.idProperty] = this.types.push(type) - 1
        forEach(OPERATORS, operator => { 
            // TODO: baseN could lead to an expensive number of calls
            baseN(this.types, operator.arity).forEach(types => {
                if (includes(types, type)) {
                    this.registerNotSupported(operator, types)
                }
            })
        })
    }

    register(operator, types, handler) {
        const typeIds = map(types, t => this.getIdFromType(t))
        set(this.operations, [operator.name].concat(typeIds), handler)
    }

    registerNotSupported(operator, types) {
        this.register(operator, types, operatorNotSupported(operator))
    }

    makeUnaryCaller(opName) {
        const map = this.operations[opName]
        return (a) => map[this.getId(a)](a)
    }

    makeBinaryCaller(opName) {
        const map = this.operations[opName]
        return (a, b) => map[this.getId(a)][this.getId(b)](a, b)
    }

    makeTernaryCaller(opName) {
        const map = this.operations[opName]
        return (a, b, c) => 
            map[this.getId(a)][this.getId(b)][this.getId(c)](a, b, c)
    }

    makeCallers(operators = OPERATORS) {
        return fromPairs(map(operators, ({ name, arity }) => {
            switch(arity) {
                case 1: return [name, this.makeUnaryCaller(name)]
                case 2: return [name, this.makeBinaryCaller(name)]
                case 3: return [name, this.makeTernaryCaller(name)]
            }
        }))
    }
}
