var GLOBAL = (function () {
    return this;
})();
if (! GLOBAL . readline) {
    readline = (function () {
        importPackage(java . io);
        importPackage(java . lang);
        stream = BufferedReader(InputStreamReader(System["in"]));
        return function () {
            var line = stream . readLine();
            if (line !== null) {
                return "" + line;
            } else {
                return "";
            };
        };
    })();
};
var getch = (function () {
    var line = "";
    var pos;
    var newl = 0;
    return function () {
        pos = pos + 1;
        if (line[pos] !== undefined) {
            newl = 0;
            return line[pos];
        } else {
            pos = -1;
            line = readline();
            newl = newl + 1;
            if (newl > 10) {
                return "]";
            } else {
                return "\n";
            };
        };
    };
})();

function tail(list, n) {
    n = n || 1;
    return list.slice(n);
}

function map(fn, list) {
    return list.map(fn);
}
function array_join(list, sep) {
    return list.join(sep);
}
function array_push(list, elem) {
    return list.push(elem);
}
function string_contains(str, c) {
    return str.indexOf(c) != -1;
}
function array() {
    var result = [];
    var i;
    for(i=0;i<arguments.length;++i) {
        result[i] = arguments[i];
    }
    return result;
}
function listpp(list, acc, indent) {
    if (! acc) {
        acc = [];
        listpp(list, acc, 4);
        return acc . join("");
    };
    if (list . constructor !== Array) {
        var str = list;
        var escape = { '\n': '\\n', ' ': '\\ ', '\t': '\\t', '[': '\\[', ']': '\\]', '\\': '\\\\', '\r': '\\r' };
        var i = 0;
        while(i<str.length) {
            acc . push(escape[str[i]]||str[i] );
            i = i + 1;
        }
        return str . length;
    };
    var len = 1;
    acc . push("[");
    var seppos = [];
    var first = true;
    var i = 0;
    while (i < list . length) {
        if (! first) {
            seppos . push(acc . length);
            acc . push("");
        };
        len = len + 1 + listpp(list[i], acc, indent + 4);
        first = false;
        i = i + 1;
    };
    var nspace = function (n) {
        var result = "";
        while (n > 0) {
            result = result + " ";
            n = n - 1;
        };
        return result;
    };
    var sep;
    if (len > 72 - indent) {
        sep = "\n" + nspace(indent);
    } else {
        sep = " ";
    };
    i = 0;
    while (i < seppos . length) {
        acc[seppos[i]] = sep;
        i = i + 1;
    };
    acc . push("]");
    return len;
};
