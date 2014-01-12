#ifndef MASTER_H_
#define MASTER_H_

#include "util/common.h"
#include "util/rpc.h"
#include "worker/worker.pb.h"
#include "kernel/table-registry.h"
#include "kernel/kernel.h"

namespace dsm {

class WorkerState;
class TaskState;

struct RunDescriptor {
   string kernel;
   string method;

   GlobalTable *table;
   bool barrier;

   CheckpointType checkpoint_type;
   int checkpoint_interval;

   // Tables to checkpoint.  If empty, commit all tables.
   vector<int> checkpoint_tables;
   vector<int> shards;

   int epoch;

   // Key-value map of arguments to pass to kernel functions
   MarshalledMap params;

   RunDescriptor() {
     Init("bogus", "bogus", NULL);
   }

   RunDescriptor(const string& kernel,
                 const string& method,
                 GlobalTable *table,
                 vector<int> cp_tables=vector<int>()) {
     Init(kernel, method, table, cp_tables);
   }

   void Init(const string& kernel,
             const string& method,
             GlobalTable *table,
             vector<int> cp_tables=vector<int>()) {
     barrier = true;
     checkpoint_type = CP_NONE;
     checkpoint_interval = -1;
     checkpoint_tables = cp_tables;

     if (!checkpoint_tables.empty()) {
       checkpoint_type = CP_MASTER_CONTROLLED;
     }

     this->kernel = kernel;
     this->method = method;
     this->table = table;
   }
 };


class Master : public TableHelper {
public:
  Master(const ConfigData &conf);
  ~Master();

  //TableHelper methods
  int id() const { return -1; }
  int epoch() const { return kernel_epoch_; }
  int peer_for_shard(int table, int shard) const {
    return tables_[table]->owner(shard);
  }
  void HandlePutRequest() { return; }
  void startHandlePutRequestFromFPGA() { return; }
  virtual void HandlePutRequestToFPGA() { return; }
  virtual void HandlePutRequestFromFPGA() { return; }
  void FlushUpdates() {return;}
  void SendTermcheck(int index, int updates, double current) {return;}

  void run_all(RunDescriptor r);
  void run_one(RunDescriptor r);
  void run_range(RunDescriptor r, vector<int> shards);

  // N.B.  All run_* methods are blocking.
  void run_all(const string& kernel, const string& method, GlobalTable* locality) {
    run_all(RunDescriptor(kernel, method, locality));
  }

  //maiter program
  template<class K, class V, class D>
  void run_maiter(MaiterKernel<K, V, D>* maiter){
      if(maiter->sharder == NULL){
          maiter->sharder = new Sharding::Mod;
      }
      
      if(maiter->initializer != NULL){
          run_all("MaiterKernel1", "run", maiter->table);
      }
        
      if(maiter->accum != NULL && maiter->sender != NULL){
          run_all("MaiterKernel2", "map", maiter->table);
      }

      if(maiter->termchecker != NULL){
          run_all("MaiterKernel3", "run", maiter->table);
      }
  }
  
  // Run the given kernel function on one (arbitrary) worker node.
  void run_one(const string& kernel, const string& method, GlobalTable* locality) {
    run_one(RunDescriptor(kernel, method, locality));
  }

  // Run the kernel function on the given set of shards.
  void run_range(const string& kernel, const string& method,
                 GlobalTable* locality, vector<int> shards) {
    run_range(RunDescriptor(kernel, method, locality), shards);
  }

  void enable_trigger(const TriggerID triggerid, int table,  bool enable);

  void run(RunDescriptor r);

  template <class T>
  T& get_cp_var(const string& key, T defval=T()) {
    if (!cp_vars_.contains(key)) {
      cp_vars_.put(key, defval);
    }
    return cp_vars_.get<T>(key);
  }


  void barrier();
  void cp_barrier();

  // Blocking.  Instruct workers to save table and kernel state.
  // When this call returns, all requested tables in the system will have been
  // committed to disk.
  void checkpoint();

  //Non-Blocking, termination check
  bool termcheck();

  // Attempt restore from a previous checkpoint for this job.  If none exists,
  // the process is left in the original state, and this function returns false.
  bool restore();

private:
  void start_checkpoint();
  void start_worker_checkpoint(int worker_id, const RunDescriptor& r);
  void finish_worker_checkpoint(int worker_id, const RunDescriptor& r);
  void finish_checkpoint();
  void terminate_iteration();

  WorkerState* worker_for_shard(int table, int shard);

  // Find a worker to run a kernel on the given table and shard.  If a worker
  // already serves the given shard, return it.  Otherwise, find an eligible
  // worker and assign it to them.
  WorkerState* assign_worker(int table, int shard);

  void send_table_assignments();
  bool steal_work(const RunDescriptor& r, int idle_worker, double avg_time);
  void assign_tables();
  void assign_tasks(const RunDescriptor& r, vector<int> shards);
  int dispatch_work(const RunDescriptor& r);

  void dump_stats();
  int reap_one_task();

  ConfigData config_;
  int checkpoint_epoch_;
  int termcheck_epoch_;
  int kernel_epoch_;

  MarshalledMap cp_vars_;

  RunDescriptor current_run_;
  double current_run_start_;
  int dispatched_; //# of dispatched tasks
  int finished_; //# of finished tasks

  bool shards_assigned_;

  bool checkpointing_;
  bool terminated_;

  // Used for interval checkpointing.
  double last_checkpoint_;
  double last_termcheck_;
  Timer* barrier_timer;
  ofstream conv_track_log;
  ofstream sync_track_log;
  int iter;

  vector<WorkerState*> workers_;

  typedef map<string, MethodStats> MethodStatsMap;
  MethodStatsMap method_stats_;

  TableRegistry::Map& tables_;
  NetworkThread* network_;
  Timer runtime_;
};
}

#endif /* MASTER_H_ */
