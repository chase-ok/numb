import operators from '../../src/lang/operators'

describe('lang/operators', () => {
    describe('+', () => {
        it('adds numbers', () => {
            expect(operators['+'](1, 2)).to.equal(3)
            expect(operators['unary+'](1)).to.equal(1)
        })
    })
})
