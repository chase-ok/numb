const NOT_IMPLEMENTED = { 
    toString() {
        return 'Operation is not implemented'
    }
}

class OperatorNotSupportedError extends TypeError {
    constructor(operator, left, right) {
        super(`Operator ${operator} is not supported for ${left} and ` + 
              `${right}.`)
        this.operator = operator
        this.left = left
        this.right = right
    }
}

Number.prototype.__add__ = function __add__(right) {
    return typeof right == 'number' ? this + right : NOT_IMPLEMENTED
}

Number.prototype.__addRight__ = function __addRight__(left) {
    return typeof left == 'number' ? left + this : NOT_IMPLEMENTED
}

export default {
    NOT_IMPLEMENTED,

    __add__(left, right) {
        if (left != null && left.__add__ != null) {
            const result = left.__add__(right)
            if (result != NOT_IMPLEMENTED) return result
        } 
        if (right != null && right.__addRight__ != null) {
            const result = right.__addRight__(left)
            if (result != NOT_IMPLEMENTED) return result
        }
        throw new OperatorNotSupportedError('+', left, right)
    }
}
