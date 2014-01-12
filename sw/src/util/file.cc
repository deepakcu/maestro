#include "util/file.h"
#include "util/common.h"
#include "google/protobuf/message.h"
#include <stdio.h>
#include <glob.h>

namespace dsm {

static const int kFileBufferSize = 4 * 1024 * 1024;

vector<string> File::MatchingFilenames(StringPiece pattern) {
  glob_t globbuf;
  globbuf.gl_offs = 0;
  glob(pattern.AsString().c_str(), 0, NULL, &globbuf);
  vector<string> out;
  for (int i = 0; i < globbuf.gl_pathc; ++i) {
    out.push_back(globbuf.gl_pathv[i]);
  }
  globfree(&globbuf);
  return out;
}

vector<File::Info> File::MatchingFileinfo(StringPiece glob) {
  vector<string> names = MatchingFilenames(glob);
  vector<File::Info> out(names.size());
  for (int i = 0; i < names.size(); ++i) {
    out[i].name = names[i];
    stat(names[i].c_str(), &out[i].stat);
  }

  return out;
}

void File::Mkdirs(string path) {
  if (path[0] != '/') {
    char cur[PATH_MAX];
    getcwd(cur, PATH_MAX);
    path = string(cur) + "/" + path;
  }

  vector<StringPiece> pbits = StringPiece::split(path, "/");
  string prefix;
  for (int i = 0; i < pbits.size(); ++i) {
    pbits[i].strip();
    if (pbits[i].size() == 0) { continue; }

    prefix += "/" + pbits[i].AsString();
    int result = mkdir(prefix.c_str(), 0777);
    PCHECK(result == 0 || errno == EEXIST) << "Failed to create directory " << path;
  }
}

string File::Slurp(const string& f) {
  FILE* fp = fopen(f.c_str(), "r");
  CHECK(fp != NULL) << "Failed to read input file " << f;

  string out;
  char buffer[32768];

  while (!feof(fp) && !ferror(fp)) {
    int read = fread(buffer, 1, 32768, fp);
    if (read > 0) {
      out.append(buffer, read);
    } else {
      break;
    }
  }

  return out;
}

bool File::Exists(const string& f) {
  FILE* fp = fopen(f.c_str(), "r");
  if (fp) {
    fclose(fp);
    return true;
  }
  return false;
}

void File::Dump(const string& f, StringPiece data) {
  FILE* fp = fopen(f.c_str(), "w+");
  if (!fp) { LOG(FATAL) << "Failed to open output file " << f.c_str(); }
  fwrite(data.data, 1, data.len, fp);
  fflush(fp);
  fclose(fp);
}

void File::Move(const string& src, const string&dst) {
  PCHECK(rename(src.c_str(), dst.c_str()) == 0);
}

bool LocalFile::read_line(string *out) {
  out->clear();
  out->resize(8192);
  char* res = fgets(&(*out)[0], out->size(), fp);
  out->resize(strlen(out->data()));
  return res != NULL;
}

int LocalFile::read(char *buffer, int len) {
  return fread(buffer, 1, len, fp);
}

int LocalFile::write(const char *buffer, int len) {
  return fwrite(buffer, 1, len, fp);
}

void LocalFile::Printf(const char* p, ...) {
  va_list args;
  va_start(args, p);
  write_string(VStringPrintf(p, args));
  va_end(args);
}

bool LocalFile::eof() {
  return feof(fp);
}

LocalFile::LocalFile(FILE* stream) {
  CHECK(stream != NULL);
  fp = stream;
  path = "<EXTERNAL FILE>";
  close_on_delete = false;
}

LocalFile::LocalFile(const string &name, const string& mode) {
  fp = fopen(name.c_str(), mode.c_str());
  PCHECK(fp != NULL) << "; failed to open file " << name << " with mode " << mode;
  path = name;
  close_on_delete = true;
  setvbuf(fp, NULL, _IOFBF, kFileBufferSize);
}

template <class T>
void Encoder::write(const T& v) {
  if (out_) {
    out_->append((const char*)&v, (size_t)sizeof(v));
  } else {
    out_f_->write((const char*)&v, (size_t)sizeof(v));
  }
}

#define INSTANTIATE(T) template void Encoder::write<T>(const T& t)
INSTANTIATE(int32_t);
INSTANTIATE(int64_t);
INSTANTIATE(double);
INSTANTIATE(uint64_t);
INSTANTIATE(uint32_t);
INSTANTIATE(float);
#undef INSTANTIATE

template <>
void Encoder::write(const string& v) { write_string(v); }

template <>
void Encoder::write(const StringPiece& v) { write_string(v); }


void Encoder::write_string(StringPiece v) {
  write((uint32_t)v.size());
  write_bytes(v);
}

void Encoder::write_bytes(StringPiece s) {
  if (out_) { out_->append(s.data, s.len); }
  else { out_f_->write(s.data, s.len); }
}

void Encoder::write_bytes(const char* a, int len) {
  if (out_) { out_->append(a, len); }
  else { out_f_->write(a, len); }
}

int LZOFile::write(const char* data, int len) {
  int left = len;
  do {
    if (block.len + left > kBlockSize) {
      write_block();
    }

    int bytes_to_write = min(kBlockSize - block.len, left);
    memcpy(block.raw + block.len, data, bytes_to_write);
    block.len += bytes_to_write;
    left -= bytes_to_write;
    data += bytes_to_write;
  } while (left > 0);

  return len;
}

int LZOFile::read(char* data, int len) {
  int left = len;
  do {
//    LOG_EVERY_N(INFO, 1000) << MP(left, block.pos, block.len);
    if (block.pos == block.len) {
      if (!read_block()) {
        return 0;
      }
    }

    int bytes_to_read = min(left, block.len - block.pos);
    memcpy(data, block.raw + block.pos, bytes_to_read);
    block.pos += bytes_to_read;
    pos_ += bytes_to_read;
    left -= bytes_to_read;
    data += bytes_to_read;
  } while (left > 0);

  return len;
}

void LZOFile::write_block() {
  if (block.len == 0)
    return;

//  LOG(INFO) << "Writing... " << block.len << " : " << f_->tell();

  lzo_uint comp_size = kCompressedBlockSize;
  CHECK_EQ(0, lzo1x_1_15_compress((unsigned char*)block.raw, block.len,
                                  (unsigned char*)block.comp, (lzo_uint*)&comp_size,
                                  (unsigned char*)block.scratch));

  f_->write((char*)&comp_size, sizeof(int));
  f_->write(block.comp, comp_size);
  block.len = 0;
}

bool LZOFile::read_block() {
  block.len = kBlockSize;
  int comp_size;
  if (f_->read((char*)&comp_size, sizeof(int)) != sizeof(int)) {
    block.len = 0;
    block.pos = 0;
    return false;
  }

  CHECK_EQ(f_->read(block.comp, comp_size), comp_size);
  CHECK_GT(comp_size, 0);
  CHECK_EQ(0, lzo1x_decompress_safe((unsigned char*)block.comp, comp_size,
                                    (unsigned char*)block.raw, (lzo_uint*)&block.len,
                                    (unsigned char*)block.scratch));

//  LOG(INFO) << "Read block of size: " << MP(block.len, comp_size);
  block.pos = 0;
  return true;
}

RecordFile::RecordFile(const string& path, const string& mode, int compression) {
  path_ = path;
  mode_ = mode;

  if (mode == "r") {
    fp = new LocalFile(path_, mode);
  } else {
    fp = new LocalFile(path_ + ".tmp", mode);
  }

  if (compression == LZO) {
    fp = new LZOFile((LocalFile*)fp, mode);
  }
}

RecordFile::~RecordFile() {
  if (!fp) { return; }

  if (mode_ != "r") {
    fp->sync();
    VLOG(1) << "Renaming: " << path_;
    File::Move(StringPrintf("%s.tmp", path_.c_str()), path_);
  }
  delete fp;
}

void RecordFile::write(const google::protobuf::Message & m) {
  //LOG_EVERY_N(DEBUG, 1000) << "Writing... " << m.ByteSize() << " bytes at pos " << ftell(fp->filePointer());
  writeChunk(m.SerializeAsString());
  //LOG_EVERY_N(DEBUG, 1000) << "New pos: " <<  ftell(fp->filePointer());
}

void RecordFile::writeChunk(StringPiece data) {
  int len = data.size();
  fp->write((char*)&len, sizeof(int));
  fp->write(data.data, data.size());
}

bool RecordFile::readChunk(string *s) {
  s->clear();

  int len;
  int bytes_read = fp->read((char*)&len, sizeof(len));

  if (bytes_read < sizeof(int)) {
    return false;
  }

  s->resize(len);
  fp->read(&(*s)[0], len);
  return true;
}

bool RecordFile::read(google::protobuf::Message *m) {
  if (!readChunk(&buf_)) {
    return false; 
  }

  if (!m)
    return true;

  CHECK(m->ParseFromString(buf_));
  return true;
}

void RecordFile::seek(uint64_t pos) {
  while (fp->tell() < pos && read(NULL));
}

}
