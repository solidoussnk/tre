/*
 * tré – Copyright (c) 2005–2010,2012–2014 Sven Michael Klose <pixel@copei.de>
 */

#include <ctype.h>
#include <stdlib.h>

#include "config.h"
#include "atom.h"
#include "list.h"
#include "number.h"
#include "error.h"
#include "eval.h"
#include "gc.h"
#include "argument.h"

treptr
trenumber_numberp (treptr object)
{
    return TREPTR_TRUTH(NUMBERP(object));
}

treptr
trenumber_builtin_numberp (treptr list)
{
    return trenumber_numberp (trearg_get (list));
}

treptr
trenumber_arg_get (treptr args)
{
	return trearg_typed (1, TRETYPE_NUMBER, trearg_get (args), NULL);
}

void
trenumber_arg_get2 (treptr * first, treptr * second, treptr args)
{
	trearg_get2 (first, second, args);
	*first = trearg_typed (1, TRETYPE_NUMBER, *first, NULL);
	*second = trearg_typed (2, TRETYPE_NUMBER, *second, NULL);
}

treptr
trenumber_characterp (treptr object)
{
    return TREPTR_TRUTH(NUMBERP(object) && (TRENUMBER_TYPE(object) == TRENUMTYPE_CHAR));
}

treptr
trenumber_builtin_characterp (treptr args)
{
    return trenumber_characterp (trearg_get (args));
}

treptr
trenumber_code_char (treptr number)
{
    char tmp = (char) TRENUMBER_VAL(number);
    return number_get_char ((double) tmp);
}

treptr
trenumber_builtin_code_char (treptr args)
{
    return trenumber_code_char (trenumber_arg_get (args));
}

treptr
trenumber_builtin_integer (treptr args)
{
    treptr  arg = trenumber_arg_get (args);
    long    tmp = (long) TRENUMBER_VAL(arg);

    return number_get_integer ((double) tmp);
}

treptr
trenumber_builtin_float (treptr args)
{
    treptr  arg = trenumber_arg_get (args);

    return number_get_float (TRENUMBER_VAL(arg));
}

void
trenumber_arg_bit_op (size_t * ix, size_t * iy, treptr args)
{
	treptr  x;
	treptr  y;

    trenumber_arg_get2 (&x, &y, args);
    *ix = (size_t) TRENUMBER_VAL(x);
	*iy = (size_t) TRENUMBER_VAL(y);
}

#define TRENUMBER_DEF_BITOP(name, op) \
	treptr	\
	name (treptr args)	\
	{	\
		size_t	ix;	\
		size_t	iy;	\
	\
    	trenumber_arg_bit_op (&ix, &iy, args);	\
    	return number_get_integer ((double) (ix op iy)); \
	}

TRENUMBER_DEF_BITOP(trenumber_builtin_bit_or, |);
TRENUMBER_DEF_BITOP(trenumber_builtin_bit_and, &);
TRENUMBER_DEF_BITOP(trenumber_builtin_bit_shift_left, <<);
TRENUMBER_DEF_BITOP(trenumber_builtin_bit_shift_right, >>);
