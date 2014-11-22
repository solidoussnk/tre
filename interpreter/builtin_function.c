/*
 * tré – Copyright (c) 2005–2014 Sven Michael Klose <pixel@copei.de>
 */

#include <string.h>

#include "config.h"
#include "atom.h"
#include "cons.h"
#include "list.h"
#include "number.h"
#include "eval.h"
#include "error.h"
#include "argument.h"
#include "builtin_function.h"
#include "string2.h"
#include "thread.h"
#include "xxx.h"
#include "function.h"
#include "symtab.h"
#include "assert.h"
#include "builtin.h"
#include "special.h"
#include "symbol.h"

treptr
trefunction_native (treptr fun)
{
    ASSERT_CALLABLE(fun);
	return FUNCTION_NATIVE(fun) ? number_get_float ((double) (long) FUNCTION_NATIVE(fun)) : NIL;
}

treptr
trefunction_bytecode (treptr fun)
{
    ASSERT_CALLABLE(fun);
	return FUNCTION_BYTECODE(fun) ? FUNCTION_BYTECODE(fun) : NIL;
}

treptr
trefunction_set_bytecode (treptr array, treptr fun)
{
    ASSERT_ARRAY(array);
    ASSERT_CALLABLE(fun);
    return FUNCTION_BYTECODE(fun) = array;
}

treptr
trefunction_core_name (char ** map, treptr fun)
{
        return symbol_get (map[(size_t) ATOM(fun)]);
}

treptr
trefunction_name (treptr fun)
{
    if (BUILTINP(fun))
        return trefunction_core_name (tre_builtin_names, fun);
    if (SPECIALP(fun))
        return trefunction_core_name (tre_special_names, fun);
    ASSERT_CALLABLE(fun);
	return FUNCTION_NAME(fun);
}

treptr
trefunction_source (treptr fun)
{
    ASSERT_CALLABLE(fun);
	return FUNCTION_SOURCE(fun);
}

treptr
trefunction_set_source (treptr list, treptr fun)
{
    ASSERT_CALLABLE(fun);
    return FUNCTION_SOURCE(fun) = list;
}

treptr
trefunction_make_function (treptr source)
{
    return trefunction_make (TRETYPE_FUNCTION, source);
}
