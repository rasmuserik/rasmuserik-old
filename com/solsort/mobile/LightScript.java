/* Copyright, 2009-2010, Rasmus Jensen, rasmus@solsort.com */
package com.solsort.mobile;

import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.util.Hashtable;
import java.util.Stack;

/*`\subsection{Variables}'*/
/** Instances of the LightScript object, is an execution context,
 * where code can be parsed, compiled, and executed.
 *
 * @author Rasmus Jensen, rasmus@lightscript.net
 * @version 1.2
 */
// </editor-fold>
public final class LightScript {

    static final boolean DEBUG_ENABLED = true;
    // <editor-fold desc="TRUE NULL FALSE UNDEFINED">
    /** The true truth value of results
     * of tests/comparisons within LightScript */
    public static final Object TRUE = new StringBuffer("true");
    /** The null value within LightScript */
    public static final Object NULL = new StringBuffer("null");
    /** The undefined value within LightScript */
    public static final Object UNDEFINED = new StringBuffer("undefined");
    /** The false truth value of results
     * of tests/comparisons within LightScript */
    public static final Object FALSE = new StringBuffer("false");

    private LightScriptType getType(Class c) {
        LightScriptType t;
        Object o = types.get(c);
        if (o == null) {
            t = new LightScriptType(this);
            types.put(c, t);
        } else {
            t = (LightScriptType) o;
        }
        return t;
    }

    LightScriptFunction getDefaultGetter(Class cls) {
        return (LightScriptFunction)getType(cls);
    }
    // </editor-fold>
    // <editor-fold desc="types">

    private Hashtable types = new Hashtable();
    LightScriptType defaultType = new LightScriptType(this);

    LightScriptFunction getGetter(Class c) {
        Object o = types.get(c);
        if (o != null) {
            o = ((LightScriptType) o).getter;
        } else {
            o = defaultType.getter;
        }
        return (LightScriptFunction) o;
    }

    LightScriptFunction getSetter(Class c) {
        Object o = types.get(c);
        if (o != null) {
            o = ((LightScriptType) o).setter;
        } else {
            o = defaultType.setter;
        }
        return (LightScriptFunction) o;
    }

    public LightScriptFunction getMethod(Class c, String methodName) {
        Object o = null;
        if (c != null) {
            o = types.get(c);
        }
        if (o == null) {
            o = new LightScriptType(this);
            types.put(c, o);
        }
        o = ((LightScriptType) o).methods.get(methodName);

        if (o == null) {
            o = defaultType.methods.get(methodName);
        }
        return o == null ? null : (LightScriptFunction) o;
    }

    /**
     * Set a named method on a given class. Special methodnames are
     * "__setter__", "__getter__", "__iter__", "toInt", "toBool", "-", "+", "*", "/", "!", "&lt;", "&lt;="
     * @param c the class on which to set the method. If c is null, the default class is used instead.
     * @param methodName the name of the method to set
     * @param function
     */
    public void setMethod(Class c, String methodName, LightScriptFunction function) {
        LightScriptType t;
        if (c == null) {
            t = defaultType;
        } else {
            t = getType(c);
        }
        if ("__setter__".equals(methodName)) {
            t.setter = function;
        } else if ("__getter__".equals(methodName)) {
            t.getter = function;
        }
        t.methods.put(methodName, function);
    }
    // </editor-fold>
    //<editor-fold desc="globals">
    /** Hashtable containing boxed global values */
    private Hashtable globals = new Hashtable();

    /**
     * Retrieve a boxed global.
     * @param key the name of the global
     * @return an array of length one, containing the global value.
     */
    Object[] getBox(Object key) {
        Object box[] = (Object[]) globals.get(key);
        if (box == null) {
            box = new Object[1];
            box[0] = UNDEFINED;
            globals.put(key, box);
        }
        return box;
    }
    Object[] newObjectFunctionBoxed = getBox("Object");
    Object[] newArrayFunctionBoxed = getBox("Array");

    /** Set a global value */
    public void set(Object key, Object value) {
        getBox(key)[0] = value;
    }

    /** Retrieve a global value */
    public Object get(Object key) {
        return getBox(key)[0];
    }
    // </editor-fold>

    /** Constructor, loading standard library */
    public LightScript() {
        StdLib.register(this);
    }

    // <editor-fold desc="eval(...)">
    /** Parse and execute LightScript code read from an input stream */
    public Object eval(InputStream is) throws LightScriptException {
        Object result = UNDEFINED, t = UNDEFINED;
        LightScriptCompiler c = new LightScriptCompiler(is, this);
        LightScriptFunction stmt = c.compileNextStatement();
        while (stmt != null) {
            result = call(stmt);
            stmt = c.compileNextStatement();
        }
        return result;
    }

    /** Shorthand for evaluating a string that contains LightScript code */
    public Object eval(String s) throws LightScriptException {
        return eval(new ByteArrayInputStream(s.getBytes()));
    }
    // </editor-fold>
    // <editor-fold desc="type conversion">

    public int toInt(Object obj) throws LightScriptException {
        return ((Integer) callMethod(obj, "toInt")).intValue();
    }

    public String toString(Object obj) throws LightScriptException {
        return (String) callMethod(obj, "toString");
    }

    public Object[] toTuple(Object obj) throws LightScriptException {
        return (Object[]) callMethod(obj, "toTuple");
    }

    public Stack toArray(Object obj) throws LightScriptException {
        return (Stack) callMethod(obj, "toArray");
    }

    public boolean toBool(Object obj) throws LightScriptException {
        if (obj == LightScript.TRUE) {
            return true;
        }
        if (obj == LightScript.FALSE || obj == LightScript.NULL || obj == LightScript.UNDEFINED) {
            return false;
        }
        return callMethod(obj, "toBool") == LightScript.TRUE;
    }
    // </editor-fold>
    //<editor-fold desc="apply(...)">

    private Object apply(String fn, Object args[]) throws LightScriptException {
        return getMethod(args[0].getClass(), fn).apply(args, 0, args.length - 1);
    }

    private Object apply(LightScriptFunction fn, Object args[]) throws LightScriptException {
        return fn.apply(args, 0, args.length - 1);
    }

    public Object call(LightScriptFunction fn) throws LightScriptException {
        Object args[] = {this};
        return apply(fn, args);
    }

    public Object call(LightScriptFunction fn, Object arg1) throws LightScriptException {
        Object args[] = {this, arg1};
        return apply(fn, args);
    }

    public Object call(LightScriptFunction fn, Object arg1, Object arg2) throws LightScriptException {
        Object args[] = {this, arg1, arg2};
        return apply(fn, args);
    }

    public Object call(LightScriptFunction fn, Object arg1, Object arg2, Object arg3) throws LightScriptException {
        Object args[] = {this, arg1, arg2, arg3};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, LightScriptFunction fn) throws LightScriptException {
        Object args[] = {thisPtr};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, LightScriptFunction fn, Object arg1) throws LightScriptException {
        Object args[] = {thisPtr, arg1};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, LightScriptFunction fn, Object arg1, Object arg2) throws LightScriptException {
        Object args[] = {thisPtr, arg1, arg2};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, LightScriptFunction fn, Object arg1, Object arg2, Object arg3) throws LightScriptException {
        Object args[] = {thisPtr, arg1, arg2, arg3};
        return apply(fn, args);
    }

    public Object call(String fn) throws LightScriptException {
        Object args[] = {this};
        return apply((LightScriptFunction) get(fn), args);
    }

    public Object call(String fn, Object arg1) throws LightScriptException {
        Object args[] = {this, arg1};
        return apply((LightScriptFunction) get(fn), args);
    }

    public Object call(String fn, Object arg1, Object arg2) throws LightScriptException {
        Object args[] = {this, arg1, arg2};
        return apply((LightScriptFunction) get(fn), args);
    }

    public Object call(String fn, Object arg1, Object arg2, Object arg3) throws LightScriptException {
        Object args[] = {this, arg1, arg2, arg3};
        return apply((LightScriptFunction) get(fn), args);
    }

    public Object callMethod(Object thisPtr, String fn) throws LightScriptException {
        Object args[] = {thisPtr};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, String fn, Object arg1) throws LightScriptException {
        Object args[] = {thisPtr, arg1};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, String fn, Object arg1, Object arg2) throws LightScriptException {
        Object args[] = {thisPtr, arg1, arg2};
        return apply(fn, args);
    }

    public Object callMethod(Object thisPtr, String fn, Object arg1, Object arg2, Object arg3) throws LightScriptException {
        Object args[] = {thisPtr, arg1, arg2, arg3};
        return apply(fn, args);
    }
    // </editor-fold>
}
