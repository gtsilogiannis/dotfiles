// Calculator for the launcher's "=" mode. A small recursive-descent parser:
// nothing is passed to eval(), so only the operators, functions and constants
// below are accepted.
//
//   expr    := term (("+" | "-") term)*
//   term    := unary (("*" | "/" | "%") unary)*
//   unary   := ("-" | "+") unary | power
//   power   := primary ("^" unary)?           right-associative: 2^3^2 = 2^9
//   primary := number | name | name "(" expr ("," expr)* ")" | "(" expr ")"
.pragma library

const functions = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, exp: Math.exp,
    ln: Math.log, log: Math.log10, log2: Math.log2,
    sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan, atan2: Math.atan2,
    floor: Math.floor, ceil: Math.ceil, round: Math.round,
    min: Math.min, max: Math.max, pow: Math.pow, hypot: Math.hypot,
};

const constants = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI };

function tokenize(text) {
    const tokens = [];
    const re = /\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([a-z][a-z0-9]*)|(\*\*|[-+*/%^(),]))/iy;
    let m;
    while (re.lastIndex < text.length) {
        const start = re.lastIndex;
        if ((m = re.exec(text)) === null) {
            const rest = text.slice(start).trim();
            if (rest === "") break;                          // trailing spaces
            throw new Error(`unexpected "${rest[0]}"`);
        }
        if (m[1] !== undefined) tokens.push({ type: "num", value: parseFloat(m[1]) });
        else if (m[2] !== undefined) tokens.push({ type: "name", value: m[2].toLowerCase() });
        else tokens.push({ type: "op", value: m[3] === "**" ? "^" : m[3] });
    }
    return tokens;
}

function parse(tokens) {
    let i = 0;
    const peek = () => tokens[i];
    const isOp = v => peek()?.type === "op" && peek().value === v;
    const expect = v => {
        if (!isOp(v)) throw new Error(`expected "${v}"`);
        i++;
    };

    function expr() {
        let v = term();
        while (isOp("+") || isOp("-")) v = tokens[i++].value === "+" ? v + term() : v - term();
        return v;
    }
    function term() {
        let v = unary();
        while (isOp("*") || isOp("/") || isOp("%")) {
            const op = tokens[i++].value;
            const r = unary();
            v = op === "*" ? v * r : op === "/" ? v / r : v % r;
        }
        return v;
    }
    function unary() {
        if (isOp("-")) { i++; return -unary(); }
        if (isOp("+")) { i++; return unary(); }
        return power();
    }
    function power() {
        const base = primary();
        if (isOp("^")) { i++; return Math.pow(base, unary()); }
        return base;
    }
    function primary() {
        const t = peek();
        if (!t) throw new Error("incomplete expression");
        if (t.type === "num") { i++; return t.value; }
        if (isOp("(")) { i++; const v = expr(); expect(")"); return v; }
        if (t.type === "name") {
            i++;
            if (isOp("(")) {
                const fn = functions[t.value];
                if (!fn) throw new Error(`unknown function "${t.value}"`);
                i++;
                const args = [expr()];
                while (isOp(",")) { i++; args.push(expr()); }
                expect(")");
                return fn(...args);
            }
            if (t.value in constants) return constants[t.value];
            throw new Error(`unknown name "${t.value}"`);
        }
        throw new Error(`unexpected "${t.value}"`);
    }

    const v = expr();
    if (i < tokens.length) throw new Error(`unexpected "${tokens[i].value}"`);
    return v;
}

// Returns { ok, text }: the result rounded to 12 significant digits, or the error.
function evaluate(text) {
    if (text.trim() === "") return { ok: false, text: "" };
    try {
        const v = parse(tokenize(text));
        if (!isFinite(v)) return { ok: false, text: isNaN(v) ? "not a number" : "infinity" };
        return { ok: true, text: String(parseFloat(v.toPrecision(12))) };
    } catch (e) {
        return { ok: false, text: e.message };
    }
}
