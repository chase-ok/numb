

{Parser} = require 'jison'

rules = []

rule = (match, result) -> rules.push [match, result]

symRule = (symbol, regex) ->
    asString = regex.toString()
    rule asString[1...asString.length-1], "return '#{symbol}';"

rule /\s+/, '/* whitespace */'

symRule 'NUMBER',     /(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?/
symRule 'IDENTIFIER', /[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*/
symRule 'STRING',     /"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/

symRule '.', /\./
symRule ',', /\,/

symRule '(', /\(/
symRule ')', /\)/

symRule '[', /\[/
symRule ']', /\]/

symRule 'UNARY_MATH', /[!|~]/
symRule 'LOGIC', /&&|\|\||&|\||\^/
symRule 'SHIFT', />>>|>>|<</

symRule 'COMPARE', /\=\=|!\=|<|>|<\=|>\=/
symRule 'MATH', /\*|\/|%/


# Jison DSL
# ---------

# Since we're going to be wrapped in a function by Jison in any case, if our
# action immediately returns a value, we can optimize by removing the function
# wrapper and just returning the value directly.
unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

# Our handy DSL for Jison grammar generation, thanks to
# [Tim Caswell](http://github.com/creationix). For every rule in the grammar,
# we pass the pattern-defining string, the action to run, and extra options,
# optionally. If no action is specified, we simply pass the value of the
# previous nonterminal.
o = (patternString, action, options) ->
  patternString = patternString.replace /\s{2,}/g, ' '
  patternCount = patternString.split(' ').length
  return [patternString, '$$ = $1;', options] unless action
  action = if match = unwrap.exec action then match[1] else "(#{action}())"

  # All runtime functions we need are defined on "yy"
  action = action.replace /\bnew /g, '$&yy.'
  action = action.replace /\b(?:Block\.wrap|extend)\b/g, 'yy.$&'

  # Returns a function which adds location data to the first parameter passed
  # in, and returns the parameter.  If the parameter is not a node, it will
  # just be passed through unaffected.
  addLocationDataFn = (first, last) ->
    if not last
      "yy.addLocationDataFn(@#{first})"
    else
      "yy.addLocationDataFn(@#{first}, @#{last})"

  action = action.replace /LOC\(([0-9]*)\)/g, addLocationDataFn('$1')
  action = action.replace /LOC\(([0-9]*),\s*([0-9]*)\)/g, addLocationDataFn('$1', '$2')

  [patternString, "$$ = #{addLocationDataFn(1, patternCount)}(#{action});", options]

# Grammatical Rules
# -----------------

# In all of the rules that follow, you'll see the name of the nonterminal as
# the key to a list of alternative matches. With each match's action, the
# dollar-sign variables are provided by Jison as references to the value of
# their numeric position, so in this rule:
#
#     "Expression UNLESS Expression"
#
# `$1` would be the value of the first `Expression`, `$2` would be the token
# for the `UNLESS` terminal, and `$3` would be the value of the second
# `Expression`.
grammar =

  Expression: [
    o 'Value'
    o 'Invocation'
    o 'Operation'
  ]

  # A literal identifier, a variable name or property.
  Identifier: [
    o 'IDENTIFIER',                             -> new Literal $1
  ]

  Literal: [
    o 'Identifier'
    o 'Array'
    o 'NUMBER',                                 -> new Literal $1
    o 'STRING',                                 -> new Literal $1
  ]

  Value: [
    o 'Parenthetical',                          -> new Value $1
    o 'Literal',                                -> new Value $1
    o 'Value Access',                           -> $1.add $2
    o 'Invocation Access',                      -> new Value $1, [].concat $2
  ]

  # The general group of accessors into an object, by property, by prototype
  # or by array index or slice.
  Access: [
    o '. Identifier',                          -> new Access $2
    o 'Index',
  ]

  # Indexing into an object or array using bracket notation.
  Index: [
    o '[ Expression ]',       -> $2
  ]

  # Ordinary function invocation, or a chained series of calls.
  Invocation: [
    o 'Value Arguments',                   -> new Call $1, $2
    o 'Invocation Arguments',                   -> new Call $1, $2
  ]

  # The list of arguments to a function call.
  Arguments: [
    o '( )',                    -> []
    o '( ArgList OptComma )',   -> $2
  ]

  # The array literal.
  Array: [
    o '[ ]',                                    -> new Arr []
    o '[ ArgList OptComma ]',                   -> new Arr $2
  ]

  # The **ArgList** is both the list of objects passed into a function call,
  # as well as the contents of an array literal
  # (i.e. comma-separated expressions). Newlines work as well.
  ArgList: [
    o 'Expression',                                              -> [$1]
    o 'ArgList , Expression',                                    -> $1.concat $3
  ]

  Parenthetical: [
    o '( Expression )',                               -> new Parens $2
  ]

  # Arithmetic and logical operators, working on one or more operands.
  # Here they are grouped by order of precedence. The actual precedence rules
  # are defined at the bottom of the page. It would be shorter if we could
  # combine most of these rules into a single generic *Operand OpSymbol Operand*
  # -type rule, but in order to make the precedence binding possible, separate
  # rules are necessary.
  Operation: [
    o 'UNARY_MATH Expression',                  -> new Op $1 , $2
    o '- Expression',                      (-> new Op '-', $2), prec: 'UNARY_MATH'
    o '+ Expression',                      (-> new Op '+', $2), prec: 'UNARY_MATH'

    o 'Expression + Expression',               -> new Op '+' , $1, $3
    o 'Expression - Expression',               -> new Op '-' , $1, $3

    o 'Expression MATH    Expression',         -> new Op $2, $1, $3
    o 'Expression **      Expression',         -> new Op $2, $1, $3
    o 'Expression SHIFT   Expression',         -> new Op $2, $1, $3
    o 'Expression COMPARE Expression',         -> new Op $2, $1, $3
    o 'Expression LOGIC   Expression',         -> new Op $2, $1, $3
  ]


# Precedence
# ----------

# Operators at the top of this list have higher precedence than the ones lower
# down. Following these rules is what makes `2 + 3 * 4` parse as:
#
#     2 + (3 * 4)
#
# And not:
#
#     (2 + 3) * 4
operators = [
  ['left',      '.']
  ['left',      '(', ')']
  ['right',     '**']
  ['right',     'UNARY_MATH']
  ['left',      'MATH']
  ['left',      '+', '-']
  ['left',      'SHIFT']
  ['left',      'COMPARE']
  ['left',      'LOGIC']
]

# Wrapping Up
# -----------

# Finally, now that we have our **grammar** and our **operators**, we can create
# our **Jison.Parser**. We do this by processing all of our rules, recording all
# terminals (every symbol which does not appear as the name of a rule above)
# as "tokens".
tokens = []
for name, alternatives of grammar
  grammar[name] = for alt in alternatives
    for token in alt[0].split ' '
      tokens.push token unless grammar[token]
    alt[1] = "return #{alt[1]}" if name is 'Expression'
    alt

# Initialize the **Parser** with our list of terminal **tokens**, our **grammar**
# rules, and the name of the root. Reverse the operators because Jison orders
# precedence from low to high, and we have it high to low
# (as in [Yacc](http://dinosaur.compilertools.net/yacc/index.html)).
parser = new Parser
  tokens      : tokens.join ' '
  bnf         : grammar
  operators   : operators.reverse()
  startSymbol : 'Expression'

console.log parser.generate()
