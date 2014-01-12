#ifndef WORKER_H_
#define WORKER_H_

#include "util/common.h"
#include "util/rpc.h"
#include "util/fpga.h"
#include "kernel/kernel.h"
#include "kernel/table.h"
#include "kernel/global-table.h"
#include "kernel/local-table.h"

#include "worker/worker.pb.h"

#include <boost/thread.hpp>
#include <mpi.h>

using boost::shared_ptr;

namespace dsm {

// If this node is the master, return false immediately.  Otherwise
// start a worker and exit when the computation is finished.
bool StartWorker(const ConfigData& conf);

class Worker : public TableHelper, private boost::noncopyable {
struct Stub;
public:
  Worker(const ConfigData &c);
  ~Worker();

  void Run();

  void KernelLoop();
  void TableLoop();
  Stats get_stats() {
    return stats_;
  }

  void CheckForMasterUpdates();
  void CheckNetwork();

  void HandleSwapRequest(const SwapTable& req, EmptyMessage *resp, const RPCInfo& rpc);
  void HandleClearRequest(const ClearTable& req, EmptyMessage *resp, const RPCInfo& rpc);
  void HandleIteratorRequest(const IteratorRequest& iterator_req, IteratorResponse *iterator_resp, const RPCInfo& rpc);
  void HandleShardAssignment(const ShardAssignmentRequest& req, EmptyMessage *resp, const RPCInfo& rpc);

  void HandlePutRequest();
  void HandlePutRequestToFPGA();
  void HandlePutRequestFromFPGA();
  void startHandlePutRequestFromFPGA();
  void putRequestScopedLockSection(); //deepak

  // Barrier: wait until all table data is transmitted.
  void HandleFlush(const EmptyMessage& req, EmptyMessage *resp, const RPCInfo& rpc);
  void HandleApply(const EmptyMessage& req, EmptyMessage *resp, const RPCInfo& rpc);

  void FlushUpdates();

  // Enable or disable triggers
  void HandleEnableTrigger(const EnableTrigger& req, EmptyMessage* resp, const RPCInfo& rpc);
  
  // terminate iteration
  void HandleTermNotification(const TerminationNotification& req, EmptyMessage* resp, const RPCInfo& rpc);

  int peer_for_shard(int table_id, int shard) const;
  int id() const { return config_.worker_id(); };
  int epoch() const { return epoch_; }

  int64_t pending_kernel_bytes() const;
  bool network_idle() const;

  bool has_incoming_data() const;

  void flushDataToFPGA();
  void HandleFpgaToWorkerPutRequest(const EmptyMessage& req, EmptyMessage *resp, const FPGARPCInfo& rpc);
  void HandleFPGACheckTerminate(const EmptyMessage& req, EmptyMessage *resp, const FPGARPCInfo& rpc);
  void HandleFPGAFlushData(const EmptyMessage& req, EmptyMessage *resp, const FPGARPCInfo& rpc);
private:
  void StartCheckpoint(int epoch, CheckpointType type);
  void FinishCheckpoint();
  bool waitFPGAResponse();
  void SendTermcheck(int index, int updates, double current);
  void Restore(int epoch);
  void UpdateEpoch(int peer, int peer_epoch);

  mutable boost::recursive_mutex state_lock_;
  mutable boost::recursive_mutex state_terminate_check_lock_; //deepak

  // The current epoch this worker is running within.
  int epoch_;

  int num_peers_;
  bool running_;
  CheckpointType active_checkpoint_;

  typedef unordered_map<int, bool> CheckpointMap;
  CheckpointMap checkpoint_tables_;


  ConfigData config_;

  // The status of other workers.
  vector<Stub*> peers_;

  NetworkThread *network_;
  FPGAThread *ft;

  unordered_set<GlobalTable*> dirty_tables_;

  uint32_t iterator_id_;
  unordered_map<uint32_t, TableIterator*> iterators_;

  struct KernelId {
    string kname_;
    int table_;
    int shard_;

    KernelId(string kname, int table, int shard) :
      kname_(kname), table_(table), shard_(shard) {}

#define CMP_LESS(a, b, member)\
  if ((a).member < (b).member) { return true; }\
  if ((b).member < (a).member) { return false; }

    bool operator<(const KernelId& o) const {
      CMP_LESS(*this, o, kname_);
      CMP_LESS(*this, o, table_);
      CMP_LESS(*this, o, shard_);
      return false;
    }
  };

  map<KernelId, DSMKernel*> kernels_;

  Stats stats_;
};

}

#endif /* WORKER_H_ */
