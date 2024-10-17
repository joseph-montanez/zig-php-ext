// wrapper.c
#include <stdarg.h>
#include "php.h"
#include "zend_API.h"

zend_string* zend_string_init_wrapper(const char *str, size_t len, int persistent) {
    return zend_string_init(str, len, persistent);
}

zend_execute_data* get_execute_data() {
	zend_execute_data *ex = EG(current_execute_data);
    return ex;
}

#ifndef ZTS
zend_executor_globals* get_executor_globals() {
    return &executor_globals;
}
zend_compiler_globals* get_compiler_globals() {
    return &compiler_globals;
}
#endif

#ifdef ZTS
size_t get_executor_globals_offset() {
    return executor_globals_offset;
}
size_t get_compiler_globals_offset() {
    return compiler_globals_offset;
}
#endif