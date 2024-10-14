/* ext2 extension for PHP */

#ifndef PHP_EXT2_H
# define PHP_EXT2_H

extern zend_module_entry ext2_module_entry;
# define phpext_ext2_ptr &ext2_module_entry

# define PHP_EXT2_VERSION "0.1.0"

# if defined(ZTS) && defined(COMPILE_DL_EXT2)
ZEND_TSRMLS_CACHE_EXTERN()
# endif

#endif	/* PHP_EXT2_H */
