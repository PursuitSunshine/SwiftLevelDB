//
//  Wrapper.cpp
//  SwiftLevelDB
//
//  Created by Cherish on 2021/11/30.
//

#include "Wrapper.hpp"
#include "leveldb/options.h"
#include "leveldb/db.h"
#include "leveldb/status.h"
#include "leveldb/slice.h"

using leveldb::Options;
using leveldb::CompressionType;
using leveldb::DB;
using leveldb::Status;
using leveldb::ReadOptions;
using leveldb::Slice;
using leveldb::WriteOptions;
using leveldb::Iterator;

extern "C" {

// LevelDB  Options
struct c_leveldb_options_t {
    Options rep;
};

// LevelDB  OBJECT
struct c_leveldb_t {
    DB* rep;
};

// LevelDB READ
struct c_leveldb_readoptions_t {
  ReadOptions rep;
};

// LevelDB WRITE
struct c_leveldb_writeoptions_t {
  WriteOptions rep;
};

// LevelDB ITERATOR
struct c_leveldb_iterator_t {
  Iterator* rep;
};


// LevelDB Options
c_leveldb_options_t* c_leveldb_options_create() {
    return new c_leveldb_options_t;
}

void c_leveldb_options_destroy(c_leveldb_options_t* options) {
    delete options;
}

void c_leveldb_options_set_create_if_missing(c_leveldb_options_t* opt, unsigned char v) {
  opt->rep.create_if_missing = v;
}

void c_leveldb_options_set_error_if_exists(c_leveldb_options_t* opt,unsigned char v) {
  opt->rep.error_if_exists = v;
}

void c_leveldb_options_set_paranoid_checks(c_leveldb_options_t* opt,unsigned char v) {
  opt->rep.paranoid_checks = v;
}

void c_leveldb_options_set_write_buffer_size(c_leveldb_options_t* opt, size_t s) {
  opt->rep.write_buffer_size = s;
}

void c_leveldb_options_set_max_open_files(c_leveldb_options_t* opt, int n) {
  opt->rep.max_open_files = n;
}

void c_leveldb_options_set_block_size(c_leveldb_options_t* opt, size_t s) {
  opt->rep.block_size = s;
}

void c_leveldb_options_set_block_restart_interval(c_leveldb_options_t* opt, int n) {
  opt->rep.block_restart_interval = n;
}

void c_leveldb_options_set_compression(c_leveldb_options_t* opt, int t) {
  opt->rep.compression = static_cast<CompressionType>(t);
}

// LevelDB Open
static bool c_SaveError(char** errptr, const Status& s) {
  assert(errptr != nullptr);
  if (s.ok()) {
    return false;
  } else if (*errptr == nullptr) {
    *errptr = strdup(s.ToString().c_str());
  } else {
    // TODO(sanjay): Merge with existing error?
    free(*errptr);
    *errptr = strdup(s.ToString().c_str());
  }
  return true;
}

c_leveldb_t* c_leveldb_open(const c_leveldb_options_t* options,const char* name, char** errptr) {
  DB* db;
  if (c_SaveError(errptr, DB::Open(options->rep, std::string(name), &db))) {
    return nullptr;
  }
  c_leveldb_t* result = new c_leveldb_t;
  result->rep = db;
  return result;
}

// LevelDB Close
void c_leveldb_close(c_leveldb_t* db) {
    delete db->rep;
    delete db;
}

// LevelDB Read Option
c_leveldb_readoptions_t* c_leveldb_readoptions_create() {
  return new c_leveldb_readoptions_t;
}

void c_leveldb_readoptions_destroy(c_leveldb_readoptions_t* opt) {
    delete opt;
    
}
void c_leveldb_readoptions_set_fill_cache(c_leveldb_readoptions_t* opt,unsigned char v) {
  opt->rep.fill_cache = v;
}
void c_leveldb_readoptions_set_verify_checksums(c_leveldb_readoptions_t* opt,unsigned char v) {
  opt->rep.verify_checksums = v;
}

// LevelDB READ
static char* c_CopyString(const std::string& str) {
  char* result = reinterpret_cast<char*>(malloc(sizeof(char) * str.size()));
  memcpy(result, str.data(), sizeof(char) * str.size());
  return result;
}

char* c_leveldb_get(c_leveldb_t* db, const c_leveldb_readoptions_t* options,
                  const char* key, size_t keylen, size_t* vallen,
                  char** errptr) {
  char* result = nullptr;
  std::string tmp;
  Status s = db->rep->Get(options->rep, Slice(key, keylen), &tmp);
  if (s.ok()) {
    *vallen = tmp.size();
    result = c_CopyString(tmp);
  } else {
    *vallen = 0;
    if (!s.IsNotFound()) {
      c_SaveError(errptr, s);
    }
  }
  return result;
}


// LevelDB Write Option
c_leveldb_writeoptions_t* c_leveldb_writeoptions_create() {
  return new c_leveldb_writeoptions_t;
}

void c_leveldb_writeoptions_destroy(c_leveldb_writeoptions_t* opt) {
    delete opt;
}

void c_leveldb_writeoptions_set_sync(c_leveldb_writeoptions_t* opt,unsigned char v) {
  opt->rep.sync = v;
}


// LevelDB Write
void c_leveldb_put(c_leveldb_t* db,
                                const c_leveldb_writeoptions_t* options,
                                const char* key, size_t keylen, const char* val,
                   size_t vallen, char** errptr){
    c_SaveError(errptr,
              db->rep->Put(options->rep, Slice(key, keylen), Slice(val, vallen)));
}

// LevelDB Delete
void c_leveldb_delete(c_leveldb_t* db, const c_leveldb_writeoptions_t* options,
                    const char* key, size_t keylen, char** errptr) {
  c_SaveError(errptr, db->rep->Delete(options->rep, Slice(key, keylen)));
}


// LevelDB Iterator
c_leveldb_iterator_t* c_leveldb_create_iterator(c_leveldb_t* db, const c_leveldb_readoptions_t* options) {
  c_leveldb_iterator_t* result = new c_leveldb_iterator_t;
  result->rep = db->rep->NewIterator(options->rep);
  return result;
}

void c_leveldb_iter_destroy(c_leveldb_iterator_t* iter) {
  delete iter->rep;
  delete iter;
}

void c_leveldb_iter_seek_to_first(c_leveldb_iterator_t* iter) {
  iter->rep->SeekToFirst();
}

unsigned char c_leveldb_iter_valid(const c_leveldb_iterator_t* iter) {
  return iter->rep->Valid();
}

const char* c_leveldb_iter_key(const c_leveldb_iterator_t* iter, size_t* klen) {
  Slice s = iter->rep->key();
  *klen = s.size();
  return s.data();
}

void c_leveldb_iter_next(c_leveldb_iterator_t* iter) {
    iter->rep->Next();
    
}



}
