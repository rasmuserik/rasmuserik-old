test('(["a", "b", "c"])[1]', "b");
test('["a", "b", "c"][1]', "b");
test('["a", "b", "c"].length', 3);
test('var i; var j = 0; for(i in ["a", "b", "c", "d"]) j += i; j;',  6);
test(' var arr = ["a", "b", "c"]; var s = "x"; var i; for(i in arr) { s += arr[i]; } return s; ', "xabc");
test('arr = []; arr.push("x"); arr[0]', "x");
test('arr = []; arr.push("x"); arr.length', 1);
test('arr = []; arr[1000] = 17; arr[1000]', 17);
test('arr = []; arr[1000] = 17; arr[500]', undefined);
test('arr = []; arr[1000] = 17; arr[1500]', undefined);
test('arr = []; arr[1000] = 17; arr[-1]', undefined);
test('["a", "b", "c"].join()', "a,b,c");
test('["a", "b", "c"].join("")', "abc");
test('["a", "b", "c"].join("ZZ")', "aZZbZZc");
test('Array.concat("foo", ["bar", "baz"], "quux").toString()', "[foo, bar, baz, quux]");
test('perm = []; for (var i = 0; i < 5; ++i) perm[i] = i; perm.join("")', "01234");
test('["a", "b", "c", "d", "e"].slice(1,4).join("")', "bcd");
test('["a", "b", "c", "d", "e"].slice(-2).join("")', "de");

