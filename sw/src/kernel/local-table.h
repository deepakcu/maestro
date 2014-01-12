#ifndef LOCALTABLE_H_
#define LOCALTABLE_H_

#include "table.h"
#include "util/file.h"
#include "util/rpc.h"

namespace dsm {

static const double kLoadFactor = 0.8;

// Represents a single shard of a partitioned global table.
class LocalTable :
  public TableBase,
  virtual public UntypedTable,
  public Checkpointable,
  public Serializable,
  public Transmittable,
  public Snapshottable {
public:
  LocalTable() : delta_file_(NULL) {}
  bool empty() { return size() == 0; }

  void start_checkpoint(const string& f);
  void finish_checkpoint();
  void restore(const string& f);
  void write_delta(const KVPairData& put);
  
  void termcheck(const string& f, int *updates, double *totalF2);

  virtual int64_t size() = 0;
  virtual void clear() = 0;
  virtual void reset() = 0;
  virtual void resize(int64_t size) = 0;

  virtual TableIterator* get_iterator(TableHelper* helper, bool bfilter) = 0;
  virtual TableIterator* schedule_iterator(TableHelper* helper, bool bfilter) = 0;
  virtual TableIterator* entirepass_iterator(TableHelper* helper) = 0;

  virtual bool isTerminated(TableHelper* helper) = 0;
  virtual bool sendFPGAAsstUpdates(TableHelper* helper) = 0;
  int shard() { return info_.shard; }

protected:
  friend class GlobalTable;
  TableCoder *delta_file_;
};

}

#endif /* LOCALTABLE_H_ */
