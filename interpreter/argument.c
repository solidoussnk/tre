/*
 * tré – Copyright (c) 2005–2008,2012–2014 Sven Michael Klose <pixel@copei.de>
 */

#include "config.h"

#ifdef INTERPRETER

#include <stdio.h>

#include "atom.h"
#include "cons.h"
#include "list.h"
#include "eval.h"
#include "builtin.h"
#include "number.h"
#include "error.h"
#include "special.h"
#include "gc.h"
#include "print.h"
#include "debug.h"
#include "thread.h"
#include "xxx.h"
#include "symtab.h"
#include "symbol.h"

treptr tre_atom_rest;
treptr tre_atom_body;
treptr tre_atom_optional;
treptr tre_atom_key;

treptr
trearg_get (treptr list)
{
#ifndef TRE_NO_ASSERTIONS
   	if (NOT(list))
       	return treerror (treptr_invalid, "Argument expected.");
   	if (ATOMP(list))
       	return treerror (list, "Atom instead of list - need 1 argument.");
    if (NOT_NIL(CDR(list)))
        trewarn (list, "Single argument expected.");
#endif

    return CAR(list);
}

void
trearg_get2 (treptr *a, treptr *b, treptr list)
{
#ifndef TRE_NO_ASSERTIONS
    treptr  second = treptr_nil;

    *a = treptr_nil;
    *b = treptr_nil;

	do {
   		while (NOT(list))
        	list = treerror (treptr_invalid, "Two arguments expected.");
   		if (CONSP(list))
			break;
       	list = treerror (list, "Atom instead of list - need two arguments.");
	} while (TRUE);

    if (NOT(CDR(list))) {
    	while (NOT(second))
        	second = treerror (treptr_invalid, "Second argument missing.");
	} else {
    	if (CDR(list) && NOT_NIL(CDDR(list)))
        	trewarn (list, "no more than two args required - ignoring rest");
		second = CADR(list);
	}

    *a = CAR(list);
    *b = second;
#else
    *a = CAR(list);
    *b = CADR(list);
#endif
}

treptr
trearg_correct (tre_size argnum, unsigned type, treptr x, const char * descr)
{
	char buf[4096];

	if (descr == NULL)
		descr = "";

	snprintf (buf, 4096, "Argument %ld to %s: %s expected instead of %s.",
			  (long) argnum, descr,
			  treerror_typename (type),
			  treerror_typename (TREPTR_TYPE(x)));

	return treerror (x, buf);
}

treptr
trearg_typed (tre_size argnum, unsigned type, treptr x, const char * descr)
{
#ifdef TRE_NO_ASSERTIONS
    (void) argnum;
    (void) type;
    (void) descr;
#else
	if (type == TRETYPE_FUNCTION && (FUNCTIONP(x) || MACROP(x)))
        return x;

	while (TREPTR_TYPE(x) != type)
		x = trearg_correct (argnum, type, x, descr);
#endif

	return x;
}

#define _ADDF(to, what) \
    { treptr _tmp = what;  \
      RPLACD(to, _tmp);	  \
      to = _tmp; }

void
trearg_expand (treptr * rvars, treptr * rvals, treptr iargdef, treptr args, bool do_argeval)
{
    treptr argdef = iargdef;
    treptr svars;
    treptr svals;
    treptr var;
    treptr val;
    treptr dvars;
    treptr dvals;
    treptr vars;
    treptr vals;
    treptr form;
    treptr init;
    treptr key;
    treptr kw;
#ifndef TRE_NO_ASSERTIONS
    treptr original_argdef = argdef;
    treptr original_args = args;
#endif
    tre_size kpos;

    dvars = vars = CONS(treptr_nil, treptr_nil);
    tregc_push (dvars);
    dvals = vals = CONS(treptr_nil, treptr_nil);
    tregc_push (dvals);
    args = list_copy (args);
    tregc_push (args);

    while (1) {
        if (NOT(argdef))
	    	break;

#ifndef TRE_NO_ASSERTIONS
        while (ATOMP(argdef)) {
            treprint (original_argdef);
            treprint (original_args);
	    	argdef = treerror (iargdef, "Argument definition must be a list.");
        }
#endif

		/* Fetch next form and argument. */
        var = CAR(argdef);
		val = (NOT_NIL(args)) ? CAR(args) : treptr_nil;

		/* Process sub-level argument list. */
        if (CONSP(var)) {
#ifndef TRE_NO_ASSERTIONS
            while (ATOMP(val)) {
                treprint (original_argdef);
                treprint (original_args);
	        	val = treerror (val, "List type argument expected.");
            }
#endif

	    	trearg_expand (&svars, &svals, var, val, do_argeval);
            RPLACD(dvars, svars);
            RPLACD(dvals, svals);
	    	dvars = last (dvars);
	    	dvals = last (dvals);
	    	goto next;
        }

        /* Process &REST argument. */
		if (var == tre_atom_rest || var == tre_atom_body) {
	    	/* Get form after keyword. */
	    	_ADDF(dvars, list_copy (CDR(argdef)));

	    	/* Evaluate following arguments if so desired. */
	    	svals = (do_argeval) ? eval_args (args) : args;

	    	/* Add arguments as a list. */
	    	_ADDF(dvals, CONS(svals, treptr_nil));
	    	args = treptr_nil;
	    	break;
        }

        /* Process &OPTIONAL argument. */
		if (var == tre_atom_optional) {
            argdef = CDR(argdef);
	    	while (1) {
                if (NOT(argdef)) {
#ifndef TRE_NO_ASSERTIONS
		    		if (NOT_NIL(args)) {
                        treprint (original_argdef);
                        treprint (original_args);
						treerror_norecover (args, "stale &OPTIONAL keyword in argument definition");
                    }
#endif
		    		break;
				}

	        	/* Get form. */
				form = CAR(argdef);

				/* Get init value. */
				init = treptr_nil;
				if (CONSP(form)) {
		    		init = CADR(form);
		    		form = CAR(form);
				}

	        	_ADDF(dvars, CONS(form, treptr_nil));

				svals = NOT_NIL(args) ?
                            (do_argeval ? eval (CAR(args)) : CAR(args)) :
                            eval (init);

	        	/* Add argument as a list. */
	        	_ADDF(dvals, CONS(svals, treptr_nil));

	        	argdef = CDR(argdef);
				if (NOT_NIL(args))
	            	args = CDR(args);
	    	}
	    	args = treptr_nil;
	    	break;
        }

        /* Process &KEY argument. */
		if (var == tre_atom_key) {
            argdef = CDR(argdef);
#ifndef TRE_NO_ASSERTIONS
            if (NOT(argdef) && NOT_NIL(args)) {
                treprint (original_argdef);
                treprint (original_args);
				treerror_norecover (args, "stale &KEY keyword in argument definition");
			}
#endif
	    	while (NOT_NIL(argdef)) {
	        	key = CAR(argdef);
				init = treptr_nil;
                if (CONSP(key)) {
		    		init = CADR(key);
		    		key = CAR(key);
 				}

                /* Get position of key in argument list. */
                kw = symbol_get_packaged (SYMBOL_NAME(key), tre_package_keyword);
				kpos = (tre_size) list_position (kw, args);
	 			if (kpos != (tre_size) -1) {
		    		/* Get argument after key. */
		    		svals = nth (kpos + 1, args);

		    		/* Remove keyword and value from argument list. */
#ifndef TRE_NO_ASSERTIONS
        	    	while (NOT(CDR(args))) {
                        treprint (original_argdef);
                        treprint (original_args);
	    	        	RPLACD(args, CONS(treerror (args, "Missing argument after keyword."), treptr_nil));
                    }
#endif
		    		args = list_delete (kpos, args);
		    		args = list_delete (kpos, args);

					/* Evaluate value. */
  					if (do_argeval)
		    			svals = eval (svals);
				} else
		    		svals = eval (init);

				tregc_push (svals);
				_ADDF(dvars, CONS(key, treptr_nil));
				_ADDF(dvals, CONS(svals, treptr_nil));
				tregc_pop ();

	        	argdef = CDR(argdef);
	    	}
	    	break;
        }

#ifndef TRE_NO_ASSERTIONS
        if (NOT(args)) {
            treprint (original_argdef);
            treprint (original_args);
	    	val = treerror (argdef, "Missing argument.");
        }
#endif

		/* Evaluate single argument if so desired. */
        if (do_argeval)
	    	val = eval (CAR(args));

        tregc_push (val);
        _ADDF(dvars, CONS(var, treptr_nil));
        _ADDF(dvals, CONS(val, treptr_nil));
        tregc_pop ();

next:
		argdef = CDR(argdef);
		args = CDR(args);
    }

#ifndef TRE_NO_ASSERTIONS
    if (NOT_NIL(args)) {
        treprint (original_argdef);
        treprint (original_args);
		trewarn (args, "too many arguments (continue to ignore)");
    }
#endif

    *rvars = CDR(vars);
    *rvals = CDR(vals);

    tregc_pop ();
    tregc_pop ();
    tregc_pop ();
}

treptr
trearg_get_keyword (treptr a)
{
    return symbol_get_packaged (SYMBOL_NAME(a), tre_package_keyword);
}

void
trearg_init (void)
{
    tre_atom_rest = symbol_get ("&REST");
    tre_atom_body = symbol_get ("&BODY");
    tre_atom_optional = symbol_get ("&OPTIONAL");
    tre_atom_key = symbol_get ("&KEY");
    EXPAND_UNIVERSE(tre_atom_rest);
    EXPAND_UNIVERSE(tre_atom_body);
    EXPAND_UNIVERSE(tre_atom_optional);
    EXPAND_UNIVERSE(tre_atom_key);

    trethread_make ();
}

#endif /* #ifdef INTERPRETER */
