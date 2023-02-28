%dw 2.0
output application/json

fun add(lhs, rhs) = { kind: "binop", op: "+", lhs: lhs, rhs: rhs }
fun sub(lhs, rhs) = { kind: "binop", op: "-", lhs: lhs, rhs: rhs }
fun mul(lhs, rhs) = { kind: "binop", op: "*", lhs: lhs, rhs: rhs }
fun div(lhs, rhs) = { kind: "binop", op: "/", lhs: lhs, rhs: rhs }
fun exp(lhs, rhs) = { kind: "binop", op: "**", lhs: lhs, rhs: rhs }
fun neg(value) = { kind: "monop", op: "-", value: value }
fun lit(value) = { kind: "lit", value: value }

var binops = {
    // a + b + c + d = (((a + b) + c) + d)
    "+": { precedence: 100, associates: "left" },
    // a - b - c - d = (((a - b) - c) - d)
    "-": { precedence: 100, associates: "left" },
    // a * b * c * d = (((a * b) * c) * d)
    "*": { precedence: 90, associates: "left" },
    // a / b / c / d = (((a / b) / c) / d)
    "/": { precedence: 90, associates: "left" },
    // a ** b ** c ** d = (a ** (b ** (c ** d)))
    "**": { precedence: 80, associates: "right" },
}

var monops = {
    // a + -b + -c*d = (a + ((-b) + (-(c*d))))
    "-": { precedence: 100 }
}

type Binop = { kind: "binop", op: "+" | "-" | "*" | "/" | "**", lhs: Expr, rhs: Expr }
type Monop = { kind: "monop", op: "-", value: Expr }
type Literal =  { kind: "lit", value: String | Number }

type Expr = Binop | Monop | Literal

// For some reason Expr causes errors here
fun as_str(v: Any) =
    v.kind match {
        case 'binop' -> '($(as_str(v.lhs))) $(v.op) ($(as_str(v.rhs)))'
        case 'monop' -> '$(v.op)($(as_str(v.value))'
        case 'lit' -> v.value as String
    }

fun as_str_less_parens(v) =
    v.kind match {
        case 'binop' -> do {
            var associates_left = binops[v.op].associates == "left"
            var current_level = binops[v.op].precedence
            ---
            '$(maybe_parenthesize(v.lhs, current_level, not associates_left)) $(v.op) $(maybe_parenthesize(v.rhs, current_level, associates_left))'
        }
        case 'monop' -> do {
            var current_level = monops[v.op].precedence
            ---
            '$(v.op)$(maybe_parenthesize(v.value, current_level))'
        }
        case 'lit' -> v.value as String
    }

fun maybe_parenthesize(v, current_level, parenthesize_same_level=true) =
    v.kind match {
        case 'binop' -> do {
            var new_level = binops[v.op].precedence
            var stringified = as_str_less_parens(v)
            ---
            if (parenthesize_same_level and new_level < current_level or (not parenthesize_same_level) and new_level <= current_level)
                stringified
            else
                '($(stringified))'
        }
        case 'monop' -> do {
            var new_level = monops[v.op].precedence
            var stringified = as_str_less_parens(v)
            ---
            if (new_level <= current_level)
                stringified
            else
                '($(stringified))'
        }
        case 'lit' -> as_str_less_parens(v)
    }

var example: Expr = add(add(add(lit(5), neg(neg(lit(9)))), lit(3)), neg(add(lit(6), lit(7))))
var one_plus_one: Expr = add(lit(1), lit(1))
var three_times_two: Expr = mul(lit(3), one_plus_one)
var five_times_six: Expr = mul(lit(5), lit(6))
var example2: Expr = add(five_times_six, three_times_two)
var two_times_three: Expr = mul(one_plus_one, lit(3))
---
[example, example2, two_times_three] map [as_str($), as_str_less_parens($)]
