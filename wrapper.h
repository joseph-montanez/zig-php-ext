// wrapper.c
#include <stdarg.h>
#include "php.h"
#include "zend_API.h"

zend_string* zend_string_init_wrapper(const char *str, size_t len, int persistent);
zend_execute_data* get_execute_data();

#ifndef ZTS
zend_executor_globals* get_executor_globals();
zend_compiler_globals* get_compiler_globals();
#endif

#ifdef ZTS
extern size_t compiler_globals_offset;
extern size_t executor_globals_offset;
size_t get_compiler_globals_offset();
size_t get_executor_globals_offset();
size_t get_executor_globals_offset();
#endif

