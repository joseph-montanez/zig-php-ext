dnl config.m4 for extension ext2

dnl Comments in this file start with the string 'dnl'.
dnl Remove where necessary.

dnl If your extension references something external, use 'with':

dnl PHP_ARG_WITH([ext2],
dnl   [for ext2 support],
dnl   [AS_HELP_STRING([--with-ext2],
dnl     [Include ext2 support])])

dnl Otherwise use 'enable':

PHP_ARG_ENABLE([ext2],
  [whether to enable ext2 support],
  [AS_HELP_STRING([--enable-ext2],
    [Enable ext2 support])],
  [no])

if test "$PHP_EXT2" != "no"; then
  dnl Write more examples of tests here...

  dnl Remove this code block if the library does not support pkg-config.
  dnl PKG_CHECK_MODULES([LIBFOO], [foo])
  dnl PHP_EVAL_INCLINE($LIBFOO_CFLAGS)
  dnl PHP_EVAL_LIBLINE($LIBFOO_LIBS, EXT2_SHARED_LIBADD)

  dnl If you need to check for a particular library version using PKG_CHECK_MODULES,
  dnl you can use comparison operators. For example:
  dnl PKG_CHECK_MODULES([LIBFOO], [foo >= 1.2.3])
  dnl PKG_CHECK_MODULES([LIBFOO], [foo < 3.4])
  dnl PKG_CHECK_MODULES([LIBFOO], [foo = 1.2.3])

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-ext2 -> check with-path
  dnl SEARCH_PATH="/usr/local /usr"     # you might want to change this
  dnl SEARCH_FOR="/include/ext2.h"  # you most likely want to change this
  dnl if test -r $PHP_EXT2/$SEARCH_FOR; then # path given as parameter
  dnl   EXT2_DIR=$PHP_EXT2
  dnl else # search default path list
  dnl   AC_MSG_CHECKING([for ext2 files in default path])
  dnl   for i in $SEARCH_PATH ; do
  dnl     if test -r $i/$SEARCH_FOR; then
  dnl       EXT2_DIR=$i
  dnl       AC_MSG_RESULT(found in $i)
  dnl     fi
  dnl   done
  dnl fi
  dnl
  dnl if test -z "$EXT2_DIR"; then
  dnl   AC_MSG_RESULT([not found])
  dnl   AC_MSG_ERROR([Please reinstall the ext2 distribution])
  dnl fi

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-ext2 -> add include path
  dnl PHP_ADD_INCLUDE($EXT2_DIR/include)

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-ext2 -> check for lib and symbol presence
  dnl LIBNAME=EXT2 # you may want to change this
  dnl LIBSYMBOL=EXT2 # you most likely want to change this

  dnl If you need to check for a particular library function (e.g. a conditional
  dnl or version-dependent feature) and you are using pkg-config:
  dnl PHP_CHECK_LIBRARY($LIBNAME, $LIBSYMBOL,
  dnl [
  dnl   AC_DEFINE(HAVE_EXT2_FEATURE, 1, [ ])
  dnl ],[
  dnl   AC_MSG_ERROR([FEATURE not supported by your ext2 library.])
  dnl ], [
  dnl   $LIBFOO_LIBS
  dnl ])

  dnl If you need to check for a particular library function (e.g. a conditional
  dnl or version-dependent feature) and you are not using pkg-config:
  dnl PHP_CHECK_LIBRARY($LIBNAME, $LIBSYMBOL,
  dnl [
  dnl   PHP_ADD_LIBRARY_WITH_PATH($LIBNAME, $EXT2_DIR/$PHP_LIBDIR, EXT2_SHARED_LIBADD)
  dnl   AC_DEFINE(HAVE_EXT2_FEATURE, 1, [ ])
  dnl ],[
  dnl   AC_MSG_ERROR([FEATURE not supported by your ext2 library.])
  dnl ],[
  dnl   -L$EXT2_DIR/$PHP_LIBDIR -lm
  dnl ])
  dnl
  dnl PHP_SUBST(EXT2_SHARED_LIBADD)

  dnl In case of no dependencies
  AC_DEFINE(HAVE_EXT2, 1, [ Have ext2 support ])

  PHP_NEW_EXTENSION(ext2, ext2.c, $ext_shared)
fi
