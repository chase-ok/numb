import operators from '../../src/lang/operators'

describe('lang/operators', () => {
    describe('+', () => {
        it('adds numbers', () => {
            expect(operators.__add__(1, 2)).to.equal(3)
        })
    })
})
