//
//  Wrapper.hpp
//  SwiftLevelDB
//
//  Created by Cherish on 2021/11/30.
//

#ifndef Wrapper_hpp
#define Wrapper_hpp

// LevelDB  Options
typedef struct c_leveldb_options_t c_leveldb_options_t;

// Open
typedef struct c_leveldb_t c_leveldb_t;

// read
typedef struct c_leveldb_readoptions_t c_leveldb_readoptions_t;

// write
typedef struct c_leveldb_writeoptions_t c_leveldb_writeoptions_t;

// key Iterator
typedef struct c_leveldb_iterator_t c_leveldb_iterator_t;

#ifdef __cplusplus
extern "C" {
#endif
//#include <stdarg.h>
#include <stddef.h>
//#include <stdint.h>

/**
 LevelDB Options
 */
c_leveldb_options_t* c_leveldb_options_create();
void c_leveldb_options_destroy(c_leveldb_options_t*);
void c_leveldb_options_set_create_if_missing(c_leveldb_options_t*,unsigned char);
void c_leveldb_options_set_error_if_exists(c_leveldb_options_t*,unsigned char);
void c_leveldb_options_set_paranoid_checks(c_leveldb_options_t*,unsigned char);
void c_leveldb_options_set_write_buffer_size(c_leveldb_options_t*, size_t);
void c_leveldb_options_set_max_open_files(c_leveldb_options_t*, int);
void c_leveldb_options_set_block_size(c_leveldb_options_t*, size_t);
void c_leveldb_options_set_block_restart_interval(c_leveldb_options_t*, int);
void c_leveldb_options_set_compression(c_leveldb_options_t*, int);

/**
 LevelDB  Open
 */
c_leveldb_t* c_leveldb_open(const c_leveldb_options_t* options,const char* name, char** errptr);

/**
 LevelDB Close
 */
void c_leveldb_close(c_leveldb_t* db);

/**
 LevelDB Read Options
 */
c_leveldb_readoptions_t* c_leveldb_readoptions_create();
void c_leveldb_readoptions_destroy(c_leveldb_readoptions_t*);
void c_leveldb_readoptions_set_fill_cache(c_leveldb_readoptions_t*,unsigned char);
void c_leveldb_readoptions_set_verify_checksums(c_leveldb_readoptions_t*, unsigned char);

/**
 LevelDB Read
 */
char* c_leveldb_get(c_leveldb_t* db,const c_leveldb_readoptions_t* options,const char* key, size_t keylen, size_t* vallen,char** errptr);


/**
 LevelDB Write Options
 */
c_leveldb_writeoptions_t* c_leveldb_writeoptions_create();
void c_leveldb_writeoptions_destroy(c_leveldb_writeoptions_t*);
void c_leveldb_writeoptions_set_sync(c_leveldb_writeoptions_t*,unsigned char);


/**
 levelDB Write
 */
void c_leveldb_put(c_leveldb_t* db,
                                const c_leveldb_writeoptions_t* options,
                                const char* key, size_t keylen, const char* val,
                                size_t vallen, char** errptr);


/**
 LevelDB Delete
 */
void c_leveldb_delete(c_leveldb_t* db,
                                   const c_leveldb_writeoptions_t* options,
                                   const char* key, size_t keylen,
                                   char** errptr);


/**
 LevelDB Iterator
 */
c_leveldb_iterator_t* c_leveldb_create_iterator(c_leveldb_t* db, const c_leveldb_readoptions_t* options);
void c_leveldb_iter_destroy(c_leveldb_iterator_t*);
void c_leveldb_iter_seek_to_first(c_leveldb_iterator_t*);
unsigned char c_leveldb_iter_valid(const c_leveldb_iterator_t*);
const char* c_leveldb_iter_key(const c_leveldb_iterator_t*,size_t* klen);
void c_leveldb_iter_next(c_leveldb_iterator_t*);


#ifdef __cplusplus
} /* end extern "C" */
#endif



#endif /* Wrapper_hpp */
