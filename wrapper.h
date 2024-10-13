// wrapper.c
#include <stdarg.h>
#include "php.h"
#include "zend_API.h"

zend_string* zend_string_init_wrapper(const char *str, size_t len, int persistent);