#include "table.h"
#include "local-table.h"

namespace dsm {

// Encodes or decodes table entries, reading and writing from the
// specified file.
struct LocalTableCoder : public TableCoder {
  LocalTableCoder(const string &f, const string& mode);
  virtual ~LocalTableCoder();

  virtual void WriteEntryToFile(StringPiece k, StringPiece v1, StringPiece v2, StringPiece v3);
  virtual bool ReadEntryFromFile(string* k, string *v1, string *v2, string *v3);

  RecordFile *f_;
};

void LocalTable::start_checkpoint(const string& f) {
  VLOG(1) << "Start checkpoint " << f;
  Timer t;

  LocalTableCoder c(f, "w");
  serializeToFile(&c);

  delta_file_ = new LocalTableCoder(f + ".delta", "w");
  VLOG(1) << "End.";
  //  LOG(INFO) << "Flushed " << file << " to disk in: " << t.elapsed();
}

void LocalTable::finish_checkpoint() {
  VLOG(1) << "FStart.";
  if (delta_file_) {
    delete delta_file_;
    delta_file_ = NULL;
  }
  VLOG(1) << "FEnd.";
}

void LocalTable::restore(const string& f) {
  if (!File::Exists(f)) {
    VLOG(1) << "Skipping restore of non-existent shard " << f;
    return;
  }

  TableData p;

  LocalTableCoder rf(f, "r");
  string k, v1, v2, v3;
  while (rf.ReadEntryFromFile(&k, &v1, &v2, &v3)) {
   update_str(k, v1, v2, v3);
  }

  // Replay delta log.
  LocalTableCoder df(f + ".delta", "r");
  while (df.ReadEntryFromFile(&k, &v1, &v2, &v3)) {
    update_str(k, v1, v2, v3);
  } 
}

//Dummy stub
//void LocalTable::DecodeUpdates(TableCoder *in, DecodeIteratorBase *itbase) { return; }

void LocalTable::write_delta(const KVPairData& put) {
  for (int i = 0; i < put.kv_data_size(); ++i) {
    delta_file_->WriteEntryToFile(put.kv_data(i).key(), put.kv_data(i).value(), "0", "0");
  }
}

//snapshot
void LocalTable::termcheck(const string& f, int* updates, double* currF2) {
  VLOG(1) << "Start snapshot " << f;
  Timer t;

  serializeToSnapshot(f, updates, currF2);

  VLOG(1) << "Flushed " << f << " to disk in: " << t.elapsed();
}

LocalTableCoder::LocalTableCoder(const string& f, const string &mode) :
    f_(new RecordFile(f, mode, RecordFile::LZO)) {
}

LocalTableCoder::~LocalTableCoder() {
  delete f_;
}

bool LocalTableCoder::ReadEntryFromFile(string* k, string *v1, string *v2, string *v3) {
  if (f_->readChunk(k)) {
    f_->readChunk(v1);
    f_->readChunk(v2);
    f_->readChunk(v3);
    return true;
  }

  return false;
}

void LocalTableCoder::WriteEntryToFile(StringPiece k, StringPiece v1, StringPiece v2, StringPiece v3) {
  f_->writeChunk(k);
  f_->writeChunk(v1);
  f_->writeChunk(v2);
  f_->writeChunk(v3);
}

}
