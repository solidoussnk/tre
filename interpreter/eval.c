/*
 * tré – Copyright (c) 2005–2009,2011–2014 Sven Michael Klose <pixel@copei.de>
 */

#include "config.h"

#ifdef INTERPRETER

#include <stdio.h>

#include "atom.h"
#include "cons.h"
#include "list.h"
#include "number.h"
#include "error.h"
#include "eval.h"
#include "builtin.h"
#include "special.h"
#include "gc.h"
#include "print.h"
#include "debug.h"
#include "argument.h"
#include "string2.h"
#include "xxx.h"
#include "apply.h"
#include "symbol.h"
#include "function.h"
#include "backtrace.h"
#include "thread.h"

treptr treopt_verbose_eval;
treptr treeval_slot_value;
treptr treeval_function_symbol;

unsigned treeval_recursions;

treptr
treeval_bind (treptr la, treptr lv)
{
    treptr  sym;
    treptr  old = treptr_nil;

    while (NOT_NIL(la) && NOT_NIL(lv)) {
        tregc_push (old);
        sym = CAR(la);
        old = CONS(CONS(sym, TRESYMBOL_VALUE(sym)), old);
		TRESYMBOL_VALUE(sym) = CAR(lv);
        tregc_pop ();

        la = CDR(la);
        lv = CDR(lv);
    }

    if (NOT_NIL(la))
        treerror (la, "Arguments missing.");
    if (NOT_NIL(lv))
        treerror (lv, "Too many arguments.");

    return old;
}

void
treeval_unbind (treptr old)
{
    treptr  v;

    while (NOT_NIL(old)) {
        v = CAR(old);
        TRESYMBOL_VALUE(CAR(v)) = CDR(v);
        old = CDR(old);
    }
}

treptr
treeval_funcall_raw (treptr funcdef, treptr args, bool do_argeval)
{
    treptr  expforms;
    treptr  expvals;
    treptr  ret;
    treptr  argdef;
    treptr  body;
    treptr  old_bindings;

    argdef = CAR(funcdef);
    body = CDR(funcdef);

    trearg_expand (&expforms, &expvals, argdef, args, do_argeval);
    tregc_push (expforms);
    tregc_push (expvals);

    old_bindings = treeval_bind (expforms, expvals);
    tregc_push (old_bindings);

    ret = treeval_list (body);

    tregc_pop ();
    treeval_unbind (old_bindings);

    tregc_pop ();
    tregc_pop ();

    return ret;
}


treptr
treeval_funcall (treptr func, treptr args, bool do_argeval)
{
    return treeval_funcall_raw (TREFUNCTION_SOURCE(func), args, do_argeval);
}

treptr
treeval_xlat_function (treevalfunc_t *xlat, treptr func, treptr args, bool do_argeval)
{
    treptr  evaldargs;
    treptr  ret;

    evaldargs = (do_argeval) ? treeval_args (args) : trelist_copy (args);
    tregc_push (evaldargs);

    ret = xlat[(size_t) TREATOM(func)] (evaldargs);

    tregc_pop ();

    return ret;
}

#define FUNCTIONEXPRP(x) \
    (CONSP(x) && CONSP(_CDR(x)) && CONSP(_CADR(x)) && _CAR(x) == treatom_function)

treptr
treeval_expr (treptr x)
{
    treptr  first;
    treptr  args;
    treptr  fun;
    treptr  v = treptr_invalid;

    first = CAR(x);
    args = CDR(x);

    if (SYMBOLP(first))
        fun = TRESYMBOL_FUN(first);
    else if (FUNCTIONEXPRP(first))
        return treeval_funcall_raw (_CADR(first), args, TRUE);
    else
        fun = treeval (first);

	if (COMPILED_FUNCTIONP(fun) || ARRAYP(fun)) {
		return trefuncall_compiled (fun, args, TRUE);
    }

    trebacktrace_push ((BUILTINP(fun) || SPECIALP(fun)) ? fun : TREFUNCTION_NAME(fun));

    switch (TREPTR_TYPE(fun)) {
        case TRETYPE_FUNCTION:    v = treeval_funcall (fun, args, TRUE); break;
        case TRETYPE_USERSPECIAL: v = treeval_funcall (fun, args, FALSE); break;
        case TRETYPE_BUILTIN:     v = trebuiltin (fun, args); break;
        case TRETYPE_SPECIAL:     v = trespecial (fun, args); break;
        default:                  treerror_norecover (CAR(x), "Function expected instead of %s.", treerror_typename (TREPTR_TYPE(CAR(x))));
    }

    trebacktrace_pop ();

    return v;
}

treptr
treeval (treptr x)
{
    treptr val = x;

    RETURN_NIL(x);

#ifdef TRE_VERBOSE_EVAL
	treprint (x);
    fflush (stdout);
#endif

    tregc_push (x);

    switch (TREPTR_TYPE(x)) {
        case TRETYPE_CONS:   val = treeval_expr (x); break;
        case TRETYPE_SYMBOL: val = TRESYMBOL_VALUE(x); break;
    }

    tregc_pop ();

    return val;
}

treptr
treeval_list (treptr x)
{
    treptr res = treptr_nil;

    DOLIST (x, x) {
        res = treeval (CAR(x));
        TREEVAL_RETURN_JUMP(res);
    }

    return res;
}

treptr
treeval_args (treptr x)
{
    treptr  car;
    treptr  cdr;
    treptr  val;

    RETURN_NIL(x);

    if (x == tre_atom_rest || x == tre_atom_body)
		return x;

    tregc_push (x);
    car = treeval (CAR(x));
    tregc_push (car);
    cdr = treeval_args (CDR(x));
    val = CONS(car, cdr);
    tregc_pop ();
    tregc_pop ();

    return val;
}

void
treeval_init ()
{
	treeval_recursions = 0;

    treeval_slot_value = treatom_get ("%SLOT-VALUE", TRECONTEXT_PACKAGE());
	EXPAND_UNIVERSE(treeval_slot_value);
    treeval_function_symbol = treatom_get ("FUNCTION", TRECONTEXT_PACKAGE());
	EXPAND_UNIVERSE(treeval_function_symbol);

    treopt_verbose_eval = treatom_get ("*VERBOSE-EVAL*", TRECONTEXT_PACKAGE());
    TRESYMBOL_VALUE(treopt_verbose_eval) = treptr_nil;
	EXPAND_UNIVERSE(treopt_verbose_eval);
}

#endif /* #ifdef INTERPRETER */
