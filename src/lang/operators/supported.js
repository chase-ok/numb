class Operator {
    constructor(options) {
        const {
            name, 
            arity,
            assignment = false,
            index = false,
            nativeOperator = options.name,
        } = options

        this.name = name
        this.arity = arity
        this.assignment = assignment
        this.index = index
        this.nativeOperator = nativeOperator

        this.unary = this.arity == 1
        this.binary = this.arity == 2
        this.ternary = this.arity == 3
    }
}

export const OPERATORS = [
    new Operator({ name: '[]', arity: 2, index: true }),
    new Operator({ name: '[]=', arity: 3, index: true, assignment: true }),

    new Operator({ name: '+', arity: 2 }),
    new Operator({ name: '-', arity: 2 }),
    new Operator({ name: '*', arity: 2 }),
    new Operator({ name: '/', arity: 2 }),
    new Operator({ name: '%', arity: 2 }),
    new Operator({ name: '&', arity: 2 }),
    new Operator({ name: '|', arity: 2 }),
    new Operator({ name: '^', arity: 2 }),

    new Operator({ name: '+=', arity: 2, assignment: true }),
    new Operator({ name: '-=', arity: 2, assignment: true }),
    new Operator({ name: '*=', arity: 2, assignment: true }),
    new Operator({ name: '/=', arity: 2, assignment: true }),
    new Operator({ name: '%=', arity: 2, assignment: true }),
    new Operator({ name: '&=', arity: 2, assignment: true }),
    new Operator({ name: '|=', arity: 2, assignment: true }),
    new Operator({ name: '^=', arity: 2, assignment: true }),

    new Operator({ name: 'unary+', arity: 1, nativeOperator: '+' }),
    new Operator({ name: 'unary-', arity: 1, nativeOperator: '-' }),
    new Operator({ name: '~', arity: 1 }),
    new Operator({ name: '!', arity: 1 }),
]
