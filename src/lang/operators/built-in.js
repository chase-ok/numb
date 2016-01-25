import { forEach } from 'lodash'
import { OPERATORS } from './supported'

function addNumberBinaryOperators(registry) {
    forEach(BINARY_OPERATORS, op => {
        registry.set(op, [Number, Number], new Function(['left', 'right'], `
            return left ${op} right
        `))
    })
}

function addNumberUnaryOperators(registry) {
    forEach(UNARY_OPERATORS, op => {
        registry.set(op, [Number], new Function(['value'], `
            return ${op}value
        `))
    })
}

function unaryOp(op) {
    return new Function(['value'], 
       `return ${op.nativeOperator}value`)
}

function binaryOp(op) {
    return new Function(['left', 'right'], 
       `return left ${op.nativeOperator} right`)
}

export function addNumberBuiltIns(registry) {
    forEach(OPERATORS, op => {
        if (op.unary) {
            registry.register(op, [Number], unaryOp(op))
        } else if (op.binary && !op.assignment && !op.index) {
            registry.register(op, [Number, Number], binaryOp(op))
        }
    })
}
