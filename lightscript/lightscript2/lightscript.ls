load("stdlib.js");
//
//  Defines
//
var IDENTIFIER = " id ";
var STRING = " string ";
var NUMBER = " num ";
var COMMENT = " comment ";
var PAREN = " paren ";
var CURLY = "dict";
//
//  Tokeniser
//
var c = " ";
var str = "";
function char_is(str) {
    return string_contains(str, c);
};
function skip_char() {
    global c;
    c = getch();
};
function push_char() {
    global str;
    str = str + c;
    skip_char();
};
function pop_string() {
    var result = str;
    str = "";
    return result;
};
var symb = "=!<>&|/*+-%";
var num = "1234567890";
var alphanum = num + "_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";
var EOF = ["(eof)"];
function next_token() {
    global c;
    while (char_is(" \n\r\t")) {
        skip_char();
    };
    if (c === "'" || c === "\"") {
        var quote = c;
        skip_char();
        while (c !== undefined && c !== quote) {
            if (c === "\\") {
                skip_char();
                if (c === "n") {
                    c = "\n";
                } else if (c === "t") {
                    c = "\t";
                } else if (c === "r") {
                    c = "\r";
                };
            };
            push_char();
        };
        skip_char();
        return [STRING, pop_string()];
    } else if (char_is(num)) {
        while (char_is(num)) {
            push_char();
        };
        return [NUMBER, pop_string()];
        // varname
    } else if (char_is(alphanum)) {
        while (char_is(alphanum)) {
            push_char();
        };
        return [pop_string()];
        // read comment or multi character symbol
    } else if (char_is(symb)) {
        if (c === "/") {
            push_char();
            if (c === "/") {
                skip_char();
                pop_string();
                while (c !== undefined && c !== "\n") {
                    push_char();
                };
                return [COMMENT, pop_string()];
            };
        };
        while (char_is(symb)) {
            push_char();
        };
        return [pop_string()];
    } else if (c === undefined) {
        return EOF;
    } else {
        push_char();
        return [pop_string()];
    };
};
//
//  General pretty printing utilities
//
function string_literal(str) {
    var escape = {
        "\n": "\\n",
        "\"": "\\\"",
        "\t": "\\t",
        "\\": "\\\\",
        "\r": "\\r"
    };
    return array_join(push(fold(function(elem, acc) { return push(acc, get(escape, elem, elem)) }, str, ["\""]), "\""), "");
};
function nspace(n) {
    var result = "";
    var i = 0;
    while (i < n) {
        result = result + "    ";
        i = i + 1;
    };
    return result;
};
// print node, with parenthesis if needed
// ie. if the head of the node has lower priority than prio
// then add parenthesis around it.
function pp_prio(prettyprinter, node, indent, prio) {
    if (get(bp, node[0], 1000) < prio) {
        return "(" + prettyprinter(node, indent) + ")";
    } else {
        return prettyprinter(node, indent);
    };
};
function pp_infix(prettyprinter, name) {
    return function(node, indent) { return pp_prio(prettyprinter, node[1], indent, bp[name]) + " " + name + " " + pp_prio(prettyprinter, node[2], indent, bp[name] + 1) };
};
function pp_infixr(prettyprinter, name) {
    return function(node, indent) { return pp_prio(prettyprinter, node[1], indent, bp[name] + 1) + " " + name + " " + pp_prio(prettyprinter, node[2], indent, bp[name]) };
};
function pp_block(prettyprinter, node, indent) {
    function _(elem, acc) {
        acc = acc + "\n" + nspace(indent + 1) + prettyprinter(elem, indent + 1);
        if (elem[0] !== COMMENT) {
            acc = acc + ";";
        };
        return acc;
    };
    return fold(_, tail(node), "{") + "\n" + nspace(indent) + "}";
};
//
//  LightScript pretty printer
//
var ls = {};
function ls_tail(node, indent, str) {
    return array_join(map(lightscript_curried(indent), tail(node)), str);
};
function ls_infix(name) {
    return pp_infix(lightscript, name);
};
function ls_infixr(name) {
    return pp_infixr(lightscript, name);
};
function ls_block(node, indent) {
    return pp_block(lightscript, node, indent);
};
function ls_default(node, indent) {
    if (is_string(node)) {
        return node;
    } else {
        var acc = [];
        var i = 1;
        while (i < len(node)) {
            array_push(acc, lightscript(node[i], indent));
            i = i + 1;
        };
        return lightscript(node[0], indent) + "(" + array_join(acc, ", ") + ")";
    };
};
function lightscript(node, indent) {
    indent = indent || 0;
    return get(ls, node[0], ls_default)(node, indent);
};
function lightscript_curried(indent) {
    return function(node) { return lightscript(node, indent) };
};
//
// JavaScript pretty printer
//
//
var js = {};
function js_tail(node, indent, str) {
    return array_join(map(javascript_curried(indent), tail(node)), str);
};
function js_infix(name) {
    return pp_infix(javascript, name);
};
function js_infixr(name) {
    return pp_infixr(javascript, name);
};
function js_block(node, indent) {
    return pp_block(javascript, node, indent);
};
function js_default(node, indent) {
    if (is_string(node)) {
        return node;
    } else {
        var acc = [];
        var i = 1;
        while (i < len(node)) {
            array_push(acc, javascript(node[i], indent));
            i = i + 1;
        };
        return javascript(node[0], indent) + "(" + array_join(acc, ", ") + ")";
    };
};
function javascript(node, indent) {
    indent = indent || 0;
    return get(js, node[0], js_default)(node, indent);
};
function javascript_curried(indent) {
    return function(node) { return javascript(node, indent) };
};
//
//   Operator constructors
//
var bp = {};
var led = {};
var nud = {};
//
// utility functions
//
function readlist(acc, endsymb) {
    while (token[0] !== endsymb && token !== EOF) {
        var t = parse();
        if (! is_separator(t[0])) {
            array_push(acc, t);
        };
    };
    token = next_token();
    return acc;
};
//
// syntax constructors
//
function infix(id, prio, name) {
    name = name || id;
    bp[id] = prio;
    bp[name] = prio;
    led[id] = function(left, token) { return [name, left, parse(prio)] };
    ls[name] = ls_infix(id);
    js[name] = js_infix(id);
};
function swapinfix(id, prio, name) {
    bp[id] = prio;
    led[id] = function(left, token) { return [name, parse(prio), left] };
};
function infixr(id, prio, name) {
    name = name || id;
    bp[id] = prio;
    bp[name] = prio;
    led[id] = function(left, token) { return [name, left, parse(prio - 1)] };
    ls[name] = ls_infixr(id);
    js[name] = js_infixr(id);
};
function infixlist(id, endsymb, prio, name) {
    bp[id] = prio;
    led[id] = function(left, token) { return readlist([name, left], endsymb) };
    ls[name] = function(node, indent) { return lightscript(node[1], indent) + id + ls_tail(tail(node), indent, ", ") + endsymb };
    js[name] = function(node, indent) { return javascript(node[1], indent) + id + js_tail(tail(node), indent, ", ") + endsymb };
};
function list(id, endsymb, name) {
    nud[id] = function() { return readlist([name], endsymb) };
    ls[name] = function(node, indent) { return id + ls_tail(node, indent, ", ") + endsymb };
    js[name] = function(node, indent) { return id + js_tail(node, indent, ", ") + endsymb };
};
function passthrough(id) {
    nud[id] = function(token) { return token };
    ls[id] = function(node, indent) { return node[len(node) - 1] };
    js[id] = function(node, indent) { return node[len(node) - 1] };
};
function prefix(id) {
    nud[id] = function() { return [id, parse()] };
    ls[id] = function(node, indent) { return node[0] + " " + lightscript(node[1], indent) };
    js[id] = function(node, indent) { return node[0] + " " + javascript(node[1], indent) };
};
function prefix2(id) {
    nud[id] = function() { return [id, parse(), parse()] };
    ls[id] = function(node, indent) { return node[0] + " (" + lightscript(node[1], indent) + ") " + ls_block(node[2], indent) };
    js[id] = function(node, indent) { return node[0] + " (" + javascript(node[1], indent) + ") " + js_block(node[2], indent) };
};
//
//  Parser
//
function default_nud(o) {
    return cons(IDENTIFIER, o);
};
var macros = {};
function identity(o) {
    return o;
};
function apply_macros(obj) {
    return get(macros, obj[0], identity)(obj);
};
function parse(rbp) {
    rbp = rbp || 0;
    var t = token;
    token = next_token();
    var left = get(nud, t[0], default_nud)(t);
    left = apply_macros(left);
    while (rbp < get(bp, token[0], 0) && ! is_separator(t[0])) {
        t = token;
        token = next_token();
        left = led[t[0]](left, t);
        left = apply_macros(left);
    };
    return left;
};
//
//  Syntax definitions
//
//  Definition of operator precedence and type
//
function is_separator(c) {
    return string_contains(";,:", c);
};
//
infixlist("(", ")", 600, "call");
function macros_call(node) {
    return tail(node);
};
macros["call"] = macros_call;
//
// 
infixlist("[", "]", 600, "get");
function ls_get(node, indent) {
    if (len(node) === 3) {
        return lightscript(node[1], indent) + "[" + lightscript(node[2], indent) + "]";
    } else {
        assert(len(node) === 4);
        return lightscript(cons("call", node), indent);
    };
};
ls["get"] = ls_get;
function js_get(node, indent) {
    if (len(node) === 3) {
        return javascript(node[1], indent) + "[" + javascript(node[2], indent) + "]";
    } else {
        assert(len(node) === 4);
        return javascript(cons("call", node), indent);
    };
};
js["get"] = js_get;
//
// Standard binary operators
//
infix("*", 500);
infix("%", 500);
infix("/", 500);
infix("+", 400);
//
// [- a ?b?]
//
infix("-", 400);
prefix("-");
function pp_sub(pp) {
    function sub(node, indent) {
        if (len(node) === 2) {
            return "-" + pp(node[1], indent);
        } else {
            return pp(node[1], indent) + " - " + pp(node[2], indent);
        };
    };
    return sub;
};
ls["-"] = pp_sub(lightscript);
js["-"] = pp_sub(javascript);
//
infix("==", 300, "===");
infix("===", 300, "eq?");
infix("!=", 300, "!==");
infix("!==", 300, "neq?");
infix("<=", 300);
infix("<", 300);
swapinfix(">=", 300, "<=");
swapinfix(">", 300, "<");
infixr("&&", 250, "and");
infixr("||", 200, "or");
//
// [cond [cond1 body1...] [cond2 body2...] ... [else bodyelse...]]
//
prefix2("if");
infixr("else", 200);
function untable(obj) {
    if (obj[0] === CURLY) {
        return tail(obj);
    } else {
        return [obj];
    };
};
function macros_if(obj) {
    var result;
    if (obj[2][0] === CURLY) {
        result = ["cond", obj[2]];
        result[1][0] = obj[1];
    } else if (obj[2][0] === "else") {
        if (obj[2][2][0] === "cond") {
            result = cons("cond", obj[2][2]);
            result[1] = cons(obj[1], untable(obj[2][1]));
        } else {
            result = ["cond", cons(obj[1], untable(obj[2][1])), cons("else", untable(obj[2][2]))];
        };
    } else {
        print("ERROR: " + uneval(obj));
        assert(false);
    };
    return result;
};
macros["if"] = macros_if;
function ls_condcasecurried(indent) {
    function result(node) {
        if (node[0] === "else") {
            return ls_block(node, indent);
        } else {
            return "if (" + lightscript(node[0], indent) + ") " + ls_block(node, indent);
        };
    };
    return result;
};
function ls_cond(node, indent) {
    return array_join(map(ls_condcasecurried(indent), tail(node)), " else ");
};
ls["cond"] = ls_cond;
function js_condcasecurried(indent) {
    function result(node) {
        if (node[0] === "else") {
            return js_block(node, indent);
        } else {
            return "if (" + javascript(node[0], indent) + ") " + js_block(node, indent);
        };
    };
    return result;
};
function js_cond(node, indent) {
    return array_join(map(js_condcasecurried(indent), tail(node)), " else ");
};
js["cond"] = js_cond;
//
//
list("(", ")", PAREN);
function macros_paren(obj) {
    if (len(obj) === 2) {
        return obj[1];
    } else {
        return obj;
    };
};
macros[PAREN] = macros_paren;
//
infix("=", 100, "set");
//
// table
list("{", "}", CURLY);
function ls_table(node, indent) {
    var acc = [];
    var i = 1;
    var ind = indent + 1;
    while (i < len(node)) {
        if (is_string(node[i])) {
            node[i] = [STRING, node[i][0]];
        };
        array_push(acc, lightscript(node[i], ind) + ": " + lightscript(node[i + 1], ind));
        i = i + 2;
    };
    if (len(acc) === 0) {
        return "{}";
    } else {
        return "{\n" + nspace(ind) + array_join(acc, ",\n" + nspace(ind)) + "\n" + nspace(indent) + "}";
    };
};
ls[CURLY] = ls_table;
function js_table(node, indent) {
    var acc = [];
    var i = 1;
    var ind = indent + 1;
    while (i < len(node)) {
        if (is_string(node[i])) {
            node[i] = [STRING, node[i][0]];
        };
        array_push(acc, javascript(node[i], ind) + ": " + javascript(node[i + 1], ind));
        i = i + 2;
    };
    if (len(acc) === 0) {
        return "{}";
    } else {
        return "{\n" + nspace(ind) + array_join(acc, ",\n" + nspace(ind)) + "\n" + nspace(indent) + "}";
    };
};
js[CURLY] = js_table;
// [array arrayelements...]
list("[", "]", "array");
// [return expr]
prefix("return");
prefix("!");
// [while condition body...]
prefix2("while");
function macros_while(node) {
    var result = cons("while", node[2]);
    assert(node[2][0] === CURLY);
    result[1] = node[1];
    return result;
};
macros["while"] = macros_while;
ls["while"] = function(node, indent) { return "while (" + lightscript(node[1], indent) + ") " + ls_block(tail(node), indent) };
js["while"] = function(node, indent) { return "while (" + javascript(node[1], indent) + ") " + js_block(tail(node), indent) };
//
// [var ...]
list("var", ";", "var");
ls["var"] = function(node, indent) { return "var " + array_join(map(lightscript_curried(indent), tail(node)), ", ") };
js["var"] = function(node, indent) { return "var " + array_join(map(javascript_curried(indent), tail(node)), ", ") };
list("global", ";", "global");
ls["global"] = function(node, indent) { return "global " + array_join(map(lightscript_curried(indent), tail(node)), ", ") };
js["global"] = function(node, indent) { return "//global " + array_join(map(javascript_curried(indent), tail(node)), ", ") };
//
// [define [fnname args...] body...]
// [lambda [args...] expr]
prefix2("function");
function macros_function(node) {
    var result = cons("define", node[2]);
    assert(node[2][0] === CURLY);
    result[1] = node[1];
    if (is_string(result[1])) {
        result[1] = [PAREN, result[1]];
    };
    if (result[1][0] === PAREN) {
        assert(len(result) === 3);
        result[0] = "lambda";
        result[1] = tail(result[1]);
        if (result[2][0] === "return") {
            result[2] = result[2][1];
        };
    };
    return result;
};
macros["function"] = macros_function;
ls["define"] = function(node, indent) { return "function " + node[1][0] + "(" + array_join(map(lightscript, tail(node[1])), ", ") + ") " + ls_block(tail(node), indent) };
ls["lambda"] = function(node, indent) { return "function(" + array_join(map(lightscript, node[1]), ", ") + ") { return " + lightscript(node[2], indent) + " }" };
js["define"] = function(node, indent) { return "function " + node[1][0] + "(" + array_join(map(javascript, tail(node[1])), ", ") + ") " + js_block(tail(node), indent) };
js["lambda"] = function(node, indent) { return "function(" + array_join(map(javascript, node[1]), ", ") + ") { return " + javascript(node[2], indent) + " }" };
//
// 
map(passthrough, [";", ":", ",", ")", "}", "(eof)", NUMBER]);
//
// 
passthrough(IDENTIFIER);
macros[IDENTIFIER] = function(obj) { return obj[1] };
//
// String literals
passthrough(STRING);
ls[STRING] = function(node) { return string_literal(node[1]) };
js[STRING] = ls[STRING];
// 
//  Comments
passthrough(COMMENT);
ls[COMMENT] = function(node) { return "//" + node[1] };
js[COMMENT] = ls[COMMENT];
//
//  List pretty printer
//
function yolan(list, acc, indent) {
    var str, i, seppos, first, sep, length;
    if (! acc) {
        acc = [];
        yolan(list, acc, 1);
        return array_join(acc, "");
    } else if (is_string(list)) {
        array_push(acc, list);
        return len(list);
    } else if (list[0] === NUMBER) {
        array_push(acc, list[1]);
        return 1;
    } else if (list[0] === STRING) {
        return len(string_literal(list[1]));
    };
    if (list[0] === COMMENT) {
        array_push(acc, ";" + list[1]);
        return 1000;
    };
    array_push(acc, "(");
    length = 1;
    seppos = [];
    first = true;
    i = 0;
    while (i < len(list)) {
        if (! first) {
            array_push(seppos, len(acc));
            array_push(acc, " ");
        };
        length = length + 1 + yolan(list[i], acc, indent + 1);
        first = false;
        i = i + 1;
    };
    if (80 - indent < length) {
        sep = strjoin("\n", nspace(indent));
    } else {
        sep = " ";
    };
    i = 0;
    while (i < len(seppos)) {
        put(acc, seppos[i], sep);
        i = i + 1;
    };
    if (is_array(list[len(list) - 1]) && list[len(list) - 1][0] === COMMENT) {
        array_push(acc, strjoin("\n", nspace(indent - 1)));
    };
    array_push(acc, ")");
    return length;
};
//
// dump
//
token = next_token();
var prettyprinter;
if (arguments[0] === "lightscript") {
    prettyprinter = lightscript;
} else if (arguments[0] === "yolan") {
    prettyprinter = yolan;
} else if (arguments[0] === "javascript") {
    prettyprinter = javascript;
} else {
    print("expects \"lightscript\", \"yolan\", or \"javascript\" as first argument");
    print("using lightscript as default");
    prettyprinter = lightscript;
};
while ((t = parse()) !== EOF) {
    if (uneval(t) !== uneval([";"])) {
        //print("\n--------------\n" +uneval(t));
        //print("\n" + yolan(t));
        var lineend;
        if (t[0] === COMMENT) {
            lineend = "";
        } else {
            lineend = ";";
        };
        print(prettyprinter(t) + lineend);
    };
};
var a, b, c;
//global a, b, c;