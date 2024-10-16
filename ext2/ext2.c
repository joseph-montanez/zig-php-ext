/* ext2 extension for PHP */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "php.h"
#include "ext/standard/info.h"
#include "php_ext2.h"
#include "ext2_arginfo.h"

/* For compatibility with older PHP versions */
#ifndef ZEND_PARSE_PARAMETERS_NONE
#define ZEND_PARSE_PARAMETERS_NONE() \
	ZEND_PARSE_PARAMETERS_START(0, 0) \
	ZEND_PARSE_PARAMETERS_END()
#endif

/* {{{ void test1() */
PHP_FUNCTION(ctest1)
{
	ZEND_PARSE_PARAMETERS_NONE();

	php_printf("The extension %s is loaded and working!\r\n", "ext2");
}
/* }}} */

/* {{{ string test2( [ string $var ] ) */
PHP_FUNCTION(ctest2)
{
	char *var = "World";
	size_t var_len = sizeof("World") - 1;
	zend_string *retval;

	ZEND_PARSE_PARAMETERS_START(0, 1)
		Z_PARAM_OPTIONAL
		Z_PARAM_STRING(var, var_len)
	ZEND_PARSE_PARAMETERS_END();

	retval = strpprintf(0, "Hello %s", var);

	RETURN_STR(retval);
}
/* }}}*/

/* {{{ string ctext_reverse( [ string $var ] ) */
PHP_FUNCTION(ctext_reverse)
{
	char *var = "";
	size_t var_len = 0;
	zend_string *retval;

	ZEND_PARSE_PARAMETERS_START(1, 1)
		Z_PARAM_STRING(var, var_len)
	ZEND_PARSE_PARAMETERS_END();

	// Create a reversed version of the input string
	retval = zend_string_alloc(var_len, 0);
	for (size_t i = 0; i < var_len; i++) {
		ZSTR_VAL(retval)[i] = var[var_len - i - 1];
	}
	ZSTR_VAL(retval)[var_len] = '\0'; // Null-terminate the string

	RETURN_STR(retval);
}
/* }}}*/


/* {{{ PHP_RINIT_FUNCTION */
PHP_RINIT_FUNCTION(ext2)
{
#if defined(ZTS) && defined(COMPILE_DL_EXT2)
	ZEND_TSRMLS_CACHE_UPDATE();
#endif

	return SUCCESS;
}
/* }}} */

/* {{{ PHP_MINFO_FUNCTION */
PHP_MINFO_FUNCTION(ext2)
{
	php_info_print_table_start();
	php_info_print_table_row(2, "ext2 support", "enabled");
	php_info_print_table_end();
}
/* }}} */

/* {{{ ext2_module_entry */
zend_module_entry ext2_module_entry = {
	STANDARD_MODULE_HEADER,
	"ext2",					/* Extension name */
	ext_functions,					/* zend_function_entry */
	NULL,							/* PHP_MINIT - Module initialization */
	NULL,							/* PHP_MSHUTDOWN - Module shutdown */
	PHP_RINIT(ext2),			/* PHP_RINIT - Request initialization */
	NULL,							/* PHP_RSHUTDOWN - Request shutdown */
	PHP_MINFO(ext2),			/* PHP_MINFO - Module info */
	PHP_EXT2_VERSION,		/* Version */
	STANDARD_MODULE_PROPERTIES
};
/* }}} */

#ifdef COMPILE_DL_EXT2
# ifdef ZTS
ZEND_TSRMLS_CACHE_DEFINE()
# endif
ZEND_GET_MODULE(ext2)
#endif
