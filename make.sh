#!/bin/sh
# tré – Copyright (c) 2005–2015 Sven Michael Klose <pixel@hugbox.org>

ARGS="$2 $3 $4 $5 $6 $7 $8 $9"

FILES="
    alien.c
    alloc.c
    array.c
    atom.c
    backtrace.c

	builtin.c
	builtin_apply.c
	builtin_arith.c
    builtin_array.c
    builtin_atom.c
	builtin_error.c
	builtin_fs.c
	builtin_function.c
	builtin_list.c
	builtin_memory.c
	builtin_net.c
	builtin_number.c
	builtin_sequence.c
	builtin_stream.c
	builtin_string.c
	builtin_symbol.c
	builtin_terminal.c
	builtin_time.c

	bytecode.c
	cons.c
	error.c
	exception.c
	funcall.c
	function.c
	gc.c
	image.c
	linenoise.c
	list.c
	main.c
	number.c
	ptr.c
	queue.c
	special_exception.c
	stream.c
	stream_file.c
	stream_string.c
	string.c
	symtab.c
	symbol.c
	thread.c
	type.c
	util.c"

CC=gcc
LD=gcc

LIBC_PATH=`find /lib64 /lib/x86_64-linux-gnu/ /lib -name libc.so.* | head -n 1`
LIBDL_PATH=`find /lib64 /lib -name libdl.so.* | head -n 1`
KERNEL_IDENT=`uname -i`
CPU_TYPE=`uname -m`
OS_RELEASE=`uname -r`
OS_VERSION="unknown" #`uname -v`
BUILD_MACHINE_INFO="-DTRE_BIG_ENDIAN -DLIBC_PATH=\"$LIBC_PATH\" -DTRE_KERNEL_IDENT=\"$KERNEL_IDENT\" -DTRE_CPU_TYPE=\"$CPU_TYPE\" -DTRE_OS_RELEASE=\"$OS_RELEASE\" -DTRE_OS_VERSION=\"$OS_VERSION\""

GNU_LIBC_FLAGS="-D_GNU_SOURCE"
C_DIALECT_FLAGS="-ansi -Wall -Wextra"

CFLAGS="-pipe $C_DIALECT_FLAGS $GNU_LIBC_FLAGS $BUILD_MACHINE_INFO $ARGS"

DEBUGOPTS="-O0 -g"
BUILDOPTS="-O2 -march=native"
CRUNSHOPTS="-O2 -march=native -fwhole-program"
CRUNSHFLAGS="-DTRE_COMPILED_CRUNSHED -Ienvironment/transpiler/targets/c/native -Wno-unused-parameter"

LIBFLAGS="-lm -lffi -lrt"

if [ -f /lib/x86_64-linux-gnu/libdl.so* ]; then
	LIBFLAGS="$LIBFLAGS -ldl";
fi

COMPILED_ENV=${COMPILED_ENV:-"_compiled-env.c"}

if [ -f environment/transpiler/targets/c/native/$COMPILED_ENV ]; then
	FILES="$FILES $COMPILED_ENV";
	CFLAGS="$CFLAGS -DTRE_HAVE_COMPILED_ENV";
fi

CRUNSHTMP="tmp.c"
SBCL="sbcl --noinform"
TRE="$SBCL --core image"
BINDIR="/usr/local/bin/"

basic_clean ()
{
	echo "Cleaning..."
	rm -vrf obj compiled
	rm -vf *.core obj compiled environment/transpiler/targets/c/native/$COMPILED_ENV image bytecode-image $CRUNSHTMP __alien.tmp files.lisp
    rm -vf environment/transpiler/targets/c/native/_revision.h environment/_current-version
    rm -vf examples/js/hello-world.js
    rm -vf gmon.out tmp.gcda profile.lisp
	echo "Checking out early reader..."
    git checkout -- cl/generated-from-environment.lisp
}

distclean ()
{
	echo "Cleaning for distribution..."
    basic_clean
	rm -vrf backup make.log boot.log
	rm -vrf _nodejstests.log _phptests.log _bytecode-interpreter-tests.log
}

link ()
{
	echo "Linking..."
	OBJS=`find obj -name \*.o`
	$LD -o tre $OBJS $LIBFLAGS || exit 1
}

make_revision_header ()
{
    REV=`git log --pretty=oneline | wc -l` || exit 1
    REV=`expr 3290 + $REV`
    echo $REV >environment/_current-version
    echo "#ifndef TRE_REVISION" >environment/transpiler/targets/c/native/_revision.h
    echo "#define TRE_REVISION $REV" >>environment/transpiler/targets/c/native/_revision.h
    echo "#define TRE_REVISION_STRING \"$REV\"" >>environment/transpiler/targets/c/native/_revision.h
    echo "#endif" >>environment/transpiler/targets/c/native/_revision.h
}

standard_compile ()
{
    make_revision_header
	mkdir -p obj
	for f in $FILES; do
		echo "Compiling $f"
		$CC $CFLAGS $COPTS -c -o obj/$f.o environment/transpiler/targets/c/native/$f || exit 1
	done
}

crunsh_compile ()
{
    make_revision_header
	rm -f $CRUNSHTMP
	echo "Compiling as one file for best optimisation..."
	echo -n "Concatenating sources:"
	for f in $FILES; do
		echo -n " $f"
		cat environment/transpiler/targets/c/native/$f >>$CRUNSHTMP
	done
	echo
	echo "Compiling..."
	$CC $CFLAGS $COPTS -o tre $CRUNSHTMP $LIBFLAGS || exit 1
	rm $CRUNSHTMP
}

install_it ()
{
	sudo cp -v tre $BINDIR || exit 1
    sudo mkdir -p /usr/local/lib/tre
    sudo cp -v image /usr/local/lib/tre || exit 1
    sudo cp -rv environment /usr/local/lib/tre || exit 1
}

case $1 in
crunsh)
	CFLAGS="$CFLAGS $CRUNSHFLAGS"
	COPTS="$COPTS $CRUNSHOPTS"
	crunsh_compile
	;;

reload)
    echo "Reloading environment from source..."
    echo | ./tre -n || exit 1
	;;

reloadnoassert)
    echo "Reloading environment from source..."
    echo | ./tre -n -e "(setq *assert* nil)(setq *targets* '(c))" || exit 1
	;;

debug)
    echo "Making debuggable version..."
	COPTS="$COPTS $DEBUGOPTS"
	standard_compile
	link
	;;

build)
    echo "Making regular build file by file..."
	COPTS="$COPTS $BUILDOPTS"
	standard_compile
	link
	;;

precompile)
    echo "Precompiling target core functions..."
	echo "(precompile-environments)" | $TRE || exit 1
	;;


compiler)
    echo "Compiling the compiler only..."
	(echo "(compile-c-compiler)" | $TRE) || exit 1
    ;;

bcompiler)
    echo "Compiling the bytecode compiler only..."
	(echo "(compile-c-environment '(compile-bytecode-environment))" | $TRE) || exit 1
	./make.sh crunsh $ARGS || exit 1
    ;;

environment)
    echo "Compiling environment..."
	(echo "(compile-c-environment)" | $TRE | tee boot.log) || exit 1
	;;

core)
    echo "(load \"cl/main.lisp\")" | $SBCL --noinform
	;;

oldgenboot)
    echo
    echo "#######################################################"
    echo "### GENERATING 'cl/generated-from-environment.lisp' ###"
    echo "#######################################################"
    echo
    $SBCL --core image makefiles/old-boot-common.lisp 2>&1 || exit 1
	;;

genboot)
    echo
    echo "#####################################"
    echo "### GENERATING 'boot-common.lisp' ###"
    echo "#####################################"
    echo
    $SBCL --core image makefiles/boot-common-lisp.lisp 2>&1 || exit 1
	;;

oldboot)
    echo
    echo "########################"
    echo "### BOOTING WITH CL/ ###"
    echo "########################"
    echo
    git checkout -- cl/generated-from-environment.lisp
	./make.sh core $ARGS || exit 1
	./make.sh oldgenboot $ARGS || exit 1
	./make.sh ctests $ARGS || exit 1
	./make.sh core $ARGS || exit 1
	./make.sh ctests $ARGS || exit 1
	;;

nboot)
    echo
    echo "#######################################"
    echo "### BOOTING WITH 'boot-common.lisp' ###"
    echo "#######################################"
    echo
    ./make.sh genboot 2>&1 || exit 1
    (echo "(load \"boot-common.lisp\")" | $SBCL 2>&1) || exit 1
	;;


qboot)
    ./make.sh oldboot 2>&1 || exit 1
    ./make.sh nboot 2>&1 || exit 1
	;;

boot)
    ./make.sh qboot 2>&1 || exit 1
    ./make.sh nboot 2>&1 || exit 1
	;;

pgo)
    echo "Profile-guided optimization..."
	./make.sh crunsh -pg -fprofile-generate $ARGS || exit 1
    mv environment/transpiler/targets/c/native/_compiled-env.c _ce.c
	./make.sh environment $ARGS || exit 1
    mv _ce.c environment/transpiler/targets/c/native/_compiled-env.c
	./make.sh crunsh -fprofile-use $ARGS || exit 1
	;;

ctests)
    echo
    echo "#########################"
    echo "### ENVIRONMENT TESTS ###"
    echo "#########################"
    echo
    (echo "(do-tests)" | $TRE) || exit 1
    echo "Environment tests passed."
	;;

phptests)
    echo "PHP target tests..."
    mkdir compiled
    $TRE tests/php.lisp || exit 1
    php compiled/test.php >_phptests.log || exit 1
    cmp tests/php.correct-output _phptests.log || (diff tests/php.correct-output _phptests.log; exit 1)
    echo "PHP target tests passed."
	;;

jstests)
    echo "JavaScript target tests..."
    mkdir compiled
    $TRE tests/js.lisp || exit 1
    (nodejs compiled/test.js >_nodejstests.log || node compiled/test.js >_nodejstests.log) || exit 1
    cmp tests/js.correct-output _nodejstests.log || (diff tests/js.correct-output _nodejstests.log; exit 1)
    echo "JavaScript target tests passed in node.js."
    chromium-browser compiled/test.html &
	;;

updatetests)
    $TRE tests/php.lisp || exit 1
    $TRE tests/js.lisp || exit 1
    echo "Updating PHP target test data..."
    php compiled/test.php >tests/php.correct-output || exit 1
    echo "Updating JavaScript target test data (node.js only)..."
    (nodejs compiled/test.js >tests/js.correct-output || node compiled/test.js >tests/js.correct-output) || exit 1
    ;;

tests)
    echo "Making tests..."
	./make.sh ctests || exit 1
	./make.sh phptests || exit 1
	./make.sh jstests || exit 1
	;;

bytecode)
    echo "Making bytecodes for everything..."
	(echo "(load-bytecode (compile-bytecode-environment))(dump-system \"image\")" | $TRE) || exit 1
	;;

bytecode-image)
    echo "Making bytecodes for everything..."
	(echo "(with-output-file o \"bytecode-image\" (adolist ((compile-bytecode-environment)) (late-print ! o)))" | $TRE) || exit 1
	;;

jsdebugger)
    $TRE makefiles/debugger-js.lisp || exit 1
    ;;

all)
    echo "Making all..." >>make.log
    echo "Regular boot." >>make.log
	./make.sh boot $ARGS || exit 1
    echo "Transpile environment with booted version." >>make.log
	./make.sh environment $ARGS || exit 1
    echo "Compiling the transpiled." >>make.log
	./make.sh crunsh $ARGS || exit 1
    echo "Testing it." >>make.log
	./make.sh tests || exit 1
#	./make.sh bytecode-image || exit 1
#   ./make.sh jsdebugger || exit 1
#    $TRE makefiles/webconsole.lisp || exit 1
    echo "All done." >>make.log
    ;;

profile)
    echo "(= (transpiler-profile? *c-transpiler*) t)(compile-c-environment)" | $TRE || exit -1
    ./make.sh crunsh || exit 1
    echo "(with-profile (compile-c-environment))(with-output-file o \"profile.log\" (adolist ((profile)) (late-print ! o)))" | $TRE || exit -1
    ;;

releasetests)
    echo "Making release tests..." | tee make.log
    echo "Checking regular build." >>make.log
	./make.sh distclean || exit 1
	./make.sh build $ARGS || exit 1
    echo "Checking regular build's reload." >>make.log
	./make.sh reload || exit 1
	./make.sh clean || exit 1
    ./make.sh all $ARGS || exit 1
    echo "Release tests done." >>make.log
	;;

install)
	install_it
	;;

clean)
	basic_clean
	;;

distclean)
	distclean
	;;

backup)
    echo "Making backup..."
    mkdir -p backup
    cp -v tre backup
    cp -v environment/transpiler/targets/c/native/_compiled-env.c backup
    cp -v image backup
    echo "Backed up to backup/. Use 'restore' on occasion."
    ;;

restore)
    cp -v backup/tre .
    cp -v backup/_compiled-env.c environment/transpiler/targets/c/native
    cp -v backup/image .
    ;;

*)
	echo "Usage: make.sh [target]"
	echo "Targets:"
	echo "  boot            Build compiled environment from scratch."
	echo "  compiler        Compile compiler and C target to C."
	echo "  bcompiler       Compile compiler and bytecode target to C."
    echo "  environment     Compile environment to C."
    echo "  bytecode        Compile environment to bytecode, replacing the functions."
    echo "  bytecode-image  Compile environment to PRINTed bytecode image."
    echo "  all             Compile everything makefiles/ has to offer."
    echo "  build           Do a regular build file by file."
    echo "  debug           Compile C sources for gdb. May the source be with you."
    echo "  crunsh          Compile C sources as one big file for best optimization."
    echo "  pgo             Compile C sources with profile-guided optimizations."
    echo "  reload          Reload the environment."
    echo "  backup          Backup installation to local directory 'backup'."
    echo "  restore         Restore the last 'backup'."
    echo "  install         Install compiled executable and environment image."
    echo "  clean           Remove built files but not the backup."
    echo "  distclean       Like 'clean' but also removes backups."
    echo "  precompile      Precompile obligatory target environments (EXPERIMENTAL)."
    echo "  profile         Make a profile of the compiler compiling itself."
    echo "  ctests          Run C environemnt tests."
    echo "  jstests         Compile JavaScript target tests and run them with"
    echo "                  Chromium and node.js."
    echo "  phptests        Compile PHP target tests and run them with the"
    echo "                  command-line version of PHP."
	echo "  tests           Run all tests."
    echo "  updatetests     Generate new test reference files."
    echo "  releasetests    Run 'all' and everything that's hardly used."
    ;;
esac
