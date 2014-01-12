#ifndef GLOBALTABLE_H_
#define GLOBALTABLE_H_

#include "table.h"
#include "local-table.h"

#include "util/file.h"
#include "util/rpc.h"
#include "util/fpga.h"

#include "util/common.h" //Deepak
#include <queue>

//#define GLOBAL_TABLE_USE_SCOPEDLOCK

namespace dsm {

class Worker;
class Master;

// Encodes table entries using the passed in TableData protocol buffer.
struct ProtoTableCoder : public TableCoder {
	ProtoTableCoder(const TableData* in);
  virtual void WriteEntryToFile(StringPiece k, StringPiece v1, StringPiece v2, StringPiece v3);
  virtual bool ReadEntryFromFile(string* k, string *v1, string *v2, string *v3);

  int read_pos_;
  TableData *t_;
};

// Encodes table entries using the passed in TableData protocol buffer.
struct ProtoKVPairCoder : public KVPairCoder {
	ProtoKVPairCoder(const KVPairData* in);
  virtual void WriteEntryToNet(StringPiece k, StringPiece v1);
  virtual bool ReadEntryFromNet(string* k, string *v1);

  int read_pos_;
  KVPairData *t_;
};

struct PartitionInfo {
  PartitionInfo() : dirty(false), tainted(false) {}
  bool dirty;
  bool tainted;
  ShardInfo sinfo;
};

class GlobalTable : virtual public TableBase {
public:
  virtual void UpdatePartitions(const ShardInfo& sinfo) = 0;
  virtual TableIterator* get_iterator(int shard, bool bfilter, unsigned int fetch_num = FETCH_NUM) = 0;

  virtual bool is_local_shard(int shard) = 0;
  virtual bool is_local_key(const StringPiece &k) = 0;

  virtual PartitionInfo* get_partition_info(int shard) = 0;
  virtual LocalTable* get_partition(int shard) = 0;

  virtual bool tainted(int shard) = 0;
  virtual int owner(int shard) = 0;

protected:
  friend class Worker;
  friend class Master;

  virtual int64_t shard_size(int shard) = 0;
};

class MutableGlobalTable : virtual public GlobalTable {
public:
  // Handle updates from the master or other workers.
  virtual void SendUpdates() = 0;
  virtual void ApplyUpdates(const KVPairData& req) = 0;
  virtual void ApplyPutUpdatesToFPGA(const KVPairData& req) = 0;
  virtual void ApplyPutUpdatesFromFPGA(char *buf, int len, int shardNum) = 0;
  virtual void ApplyFPGAFlushUpdates(char *buf, int len, int shardNum) = 0;
  virtual void HandlePutRequests() = 0;
  virtual void TermCheck() = 0;

  virtual int pending_write_bytes() = 0;

  virtual void clear() = 0;
  virtual void resize(int64_t new_size) = 0;

  // Exchange the content of this table with that of table 'b'.
  virtual void swap(GlobalTable *b) = 0;
protected:
  friend class Worker;
  virtual void local_swap(GlobalTable *b) = 0;
};

class GlobalTableBase : virtual public GlobalTable {
public:
  virtual ~GlobalTableBase();

  void Init(const TableDescriptor *tinfo);

  void UpdatePartitions(const ShardInfo& sinfo);

  virtual TableIterator* get_iterator(int shard, bool bfilter, unsigned int fetch_num = FETCH_NUM) = 0;

  virtual bool is_local_shard(int shard);
  virtual bool is_local_key(const StringPiece &k);

  int64_t shard_size(int shard);

  PartitionInfo* get_partition_info(int shard) { return &partinfo_[shard]; }
  LocalTable* get_partition(int shard) { return partitions_[shard]; }

  bool tainted(int shard) { return get_partition_info(shard)->tainted; }
  int owner(int shard) { return get_partition_info(shard)->sinfo.owner(); }
protected:
  virtual int shard_for_key_str(const StringPiece& k) = 0;

  int worker_id_;

  vector<LocalTable*> partitions_;
  vector<LocalTable*> cache_;

  boost::recursive_mutex& mutex() { return m_; }
  boost::recursive_mutex m_;
  boost::mutex& trigger_mutex() { return m_trig_; }
  boost::mutex m_trig_;

  vector<PartitionInfo> partinfo_;

  struct CacheEntry {
    double last_read_time;
    string value;
  };

  unordered_map<StringPiece, CacheEntry> remote_cache_;
};

class MutableGlobalTableBase :
  virtual public GlobalTableBase,
  virtual public MutableGlobalTable,
  virtual public Checkpointable {
public:
  MutableGlobalTableBase() : pending_writes_(0), snapshot_index(0) {}

  void BufSend();
  void SendUpdates();
  virtual void ApplyUpdates(const KVPairData& req) = 0;
  void HandlePutRequests();
  void TermCheck();

  int pending_write_bytes();

  void clear();
  void resize(int64_t new_size);

  void start_checkpoint(const string& f);
  void write_delta(const KVPairData& d);
  void finish_checkpoint();
  void restore(const string& f);  

  void swap(GlobalTable *b);

protected:
  int64_t pending_writes_;
  int snapshot_index;
  void local_swap(GlobalTable *b);
  void termcheck();

	//double send_overhead;
	//double objectcreate_overhead;
	//int sendtime;
};

template <class K, class V1, class V2, class V3>
class TypedGlobalTable :
  virtual public GlobalTable,
  public MutableGlobalTableBase,
  public TypedTable<K, V1, V2, V3>,
  private boost::noncopyable {
public:
	//Deepak - new API
	bool check_for_termination(int shard);

	//Deepak - new API
	bool send_fpga_asst_updates(int shard);
	bool initialized(){
		return binit;
	}

	//Deepak - a helper to keep track of how many keys in table (for address generating)
	void setNumKeysInTable(int numKeys) {
		numKeysInTable = numKeys;
	}

	//Deepak - a helper to get # keys in table (for address generating)
	int getNumKeysInTable() {
		return numKeysInTable;
	}

	//A helper that stores the worker id, type and IP address of the FPGA (if any) it is connected to
	void updateFPGAWorkerInfo(int worker_id, fpga_info_t fpga_info) {
		fpga_info_store[worker_id] = fpga_info;
		return;
	}

	fpga_info_t getFPGAWorkerInfo(int worker_id) {
		return fpga_info_store[worker_id];
	}

	//Deepak
	bool checkNodeType(int worker_id) {
		return fpga_info_store[worker_id].isNodeFPGA;
	}

	void printFPGAStore() {
		VLOG(0) << "fpga store size is " << fpga_info_store.size();
		for(int i=0;i<fpga_info_store.size();i++)
			VLOG(0) << "is node fpga is "<<fpga_info_store[i].isNodeFPGA << "ip address is "<< fpga_info_store[i].fpga_ip_address<<"\n";
	}

  typedef pair<K, V1> KVPair;
  typedef TypedTableIterator<K, V1, V2, V3> Iterator;
  typedef NetDecodeIterator<K, V1> NetUpdateDecoder;
  virtual void Init(const TableDescriptor *tinfo) {
    GlobalTableBase::Init(tinfo);

    for (int i = 0; i < partitions_.size(); ++i) {
    	partitions_[i] = create_deltaT(i);
    }

    //deepak initialize the vector to store fpga info associated with workers
    fpga_info_store.resize(partitions_.size());

    //Clear the update queue, just in case
    update_queue.clear();
    binit = false;
  }

  void InitStateTable(){
    for (int i = 0; i < partitions_.size(); ++i) {
        if(is_local_shard(i)){
            partitions_[i] = create_localT(i);
        }
    }
    binit = true;
  }

  int get_shard(const K& k);
  V1 get_localF1(const K& k);
  V2 get_localF2(const K& k);
  V3 get_localF3(const K& k);

  // Store the given key-value pair in this hash. If 'k' has affinity for a
  // remote thread, the application occurs immediately on the local host,
  // and the update is queued for transmission to the owner.
	void put(const K &k, const V1 &v1, const V2 &v2, const V3 &v3);
	void updateF1(const K &k, const V1 &v);
	void updateF2(const K &k, const V2 &v);
	void updateF3(const K &k, const V3 &v);
	void enqueue_updateF1(K k, V1 v);
	void accumulateF1(const K &k, const V1 &v);
	void accumulateAsstFromFPGAF1(const K &k, const V1 &v);
	void accumulateAsstToFPGAF1(const K &k, const V1 &v);
	void accumulateF2(const K &k, const V2 &v);
	void accumulateF3(const K &k, const V3 &v);

	// Return the value associated with 'k', possibly blocking for a remote fetch.
	ClutterRecord<K, V1, V2, V3> get(const K &k);
	V1 getF1(const K &k);
	V2 getF2(const K &k);
	V3 getF3(const K &k);
	bool contains(const K &k);
	bool remove(const K &k);

  TableIterator* get_iterator(int shard, bool bfilter, unsigned int fetch_num = FETCH_NUM);
  
  TypedTable<K, V1, V2, V3>* partition(int idx) {
    return dynamic_cast<TypedTable<K, V1, V2, V3>* >(partitions_[idx]);
  }

  PTypedTable<K, V1>* deltaT(int idx) {
    return dynamic_cast<PTypedTable<K, V1>* >(partitions_[idx]);
  }

  virtual TypedTableIterator<K, V1, V2, V3>* get_typed_iterator(int shard, bool bfilter, unsigned int fetch_num = FETCH_NUM) {
    return static_cast<TypedTableIterator<K, V1, V2, V3>* >(get_iterator(shard, bfilter, fetch_num));
  }
  
  TypedTableIterator<K, V1, V2, V3>* get_entirepass_iterator(int shard) {
    return (TypedTableIterator<K, V1, V2, V3>*) partitions_[shard]->entirepass_iterator(this->helper());
  }
    
  //deepak - returns the #keys we received from FPGA flush
  int checkKeysFlushedFromFPGA(int worker_id) {
	  return fpga_info_store[worker_id].numKeysFlushedFromFPGA;
  }
  //deepak - use this API to push updates from other CPUs to the FPGA node
  void ApplyPutUpdatesToFPGA(const dsm::KVPairData& req) {

	  //boost::recursive_mutex::scoped_lock sl(mutex());

	  	  //cout << "ApplyPutUpdatesToFPGA\n";
	      //cout << "FPGA applying updates, from " << req.source();

	      if (!is_local_shard(req.shard())) {
	        LOG_EVERY_N(INFO, 1000)
	            << "Forwarding push request from: " << MP(id(), req.shard())
	            << " to " << owner(req.shard());
	      }

	      // Changes to support centralized of triggers <CRM>
	      ProtoKVPairCoder c(&req);
	      NetUpdateDecoder it;
	      partitions_[req.shard()]->deserializeFromNet(&c, &it);

	      //deepak - try adding some delay hjere
	      //boost::this_thread::sleep( boost::posix_time::seconds(0.1));

	      //convert key value pairs to FPGA address locations
	      /*
	      for(;!it.done(); it.Next()) {
	      	VLOG(2) << this->owner(req.shard()) << ":" << req.shard() << "read from remote " << it.key() << ";" << it.value1();
	          //accumulateAsstToFPGAF1(it.key(),it.value1()); //accumulateF1 is the default update
	      	  int shard = get_shard(it.key());
	      	  partition(shard)->accumulateAsstToFPGAF1(it.key(),it.value1());


	      }
	      */

	      //send updates to the FPGA node


	      //TermCheck();
  }
  void ApplyPutUpdatesFromFPGA(char *buf, int len, int shardNum)  {
  	  //make sure we have a mutex to this section
  	  //deepak - unnecsaary mutex comment
	  //boost::recursive_mutex::scoped_lock sl(mutex());

  	  //VLOG(0)<<"ApplyPutUpdatesFromFPGA\n";
  	  //cout<<"ApplyPutUpdatesFromFPGA\n";
  	  //split the character stream into key value pairs and update the table
  	  NetUpdateDecoder it;

  	  partitions_[shardNum]->deserializeFromFPGA(buf, len, &it);

        int i=0;
        //cout<<"FPGARcv buf = "<<buf<<" parse start\n";

        for(;!it.done(); it.Next()) {
      		    //cout<<"[FPGARcv "<<shardNum<<"] Key = "<<i<<"(K,V) = ("<<it.key()<<"  = "<<it.value1()<<")\n";

        		accumulateAsstFromFPGAF1(it.key(),it.value1()); //accumulateF1 is the default update //Deepak - temp disable
        }

    }


  void ApplyFPGAFlushUpdates(char *buf, int len, int shardNum)
  {

	  //make sure we have a mutex to this section
	  boost::recursive_mutex::scoped_lock sl(mutex());

	  //split the character stream into key value pairs and update the table
	  NetUpdateDecoder it;
	  //VLOG(0) <<" Total partitions is " << partitions_.size() << " and shard number is " << shardNum << "\n";

	  partitions_[shardNum]->deserializeFromFPGA(buf, len, &it);

      int i=0;
      for(;!it.done(); it.Next()) {
          //we must skip the first 4 bytes in the data stream (this word was inserted for ethernet alignment purposes)
    	  if(i!=0) {
    		  cout<<"Flush key - "<<it.key()<<" val - "<<it.value1()<<"\n";
    		  accumulateF1(it.key(),it.value1()); //accumulateF1 is the default update //Deepak - temp disable
    		  //VLOG(0) <<" Shard # "<< shardNum <<"Key is going to be "<<it.key()<<"Value is going to be updated to "<<it.value1()<<"\n";
    	  }
    	  else
    		  i++;
          //accumulateF1(it.key(),1000); //accumulateF1 is the default update
      }
      fpga_info_store[shardNum].numKeysFlushedFromFPGA = fpga_info_store[shardNum].numKeysFlushedFromFPGA+1;
      //numKeysFlushedFromFPGA++;
      //VLOG(0) << "[shard="<< shardNum << "] Num keys updated is "<<fpga_info_store[shardNum].numKeysFlushedFromFPGA <<"\n";
  }

  //Deepak - hack when a put request is received the table is updated here	
  void ApplyUpdates(const dsm::KVPairData& req) {
    boost::recursive_mutex::scoped_lock sl(mutex());

    VLOG(2) << "applying updates, from " << req.source();

    if (!is_local_shard(req.shard())) {
      LOG_EVERY_N(INFO, 1000)
          << "Forwarding push request from: " << MP(id(), req.shard())
          << " to " << owner(req.shard());
    }

    // Changes to support centralized of triggers <CRM>
    ProtoKVPairCoder c(&req);
    NetUpdateDecoder it;
    partitions_[req.shard()]->deserializeFromNet(&c, &it);

    for(;!it.done(); it.Next()) {
    	VLOG(2) << this->owner(req.shard()) << ":" << req.shard() << "read from remote " << it.key() << ";" << it.value1();
        accumulateF1(it.key(),it.value1());
    }
    
    TermCheck();
  }

  Marshal<K> *kmarshal() { return ((Marshal<K>*)info_.key_marshal); }
  Marshal<V1> *v1marshal() { return ((Marshal<V1>*)info_.value1_marshal); }
  Marshal<V2> *v2marshal() { return ((Marshal<V2>*)info_.value2_marshal); }
  Marshal<V3> *v3marshal() { return ((Marshal<V3>*)info_.value3_marshal); }

protected:
  int shard_for_key_str(const StringPiece& k);
  virtual LocalTable* create_localT(int shard);
  virtual LocalTable* create_deltaT(int shard);
  deque<KVPair> update_queue;
  bool binit;
  int numKeysInTable; //Variable to keep track of number of keys
  vector<fpga_info_t> fpga_info_store; //A table to keep track of the info about all the FPGA nodes in the cluster

};

static const int kWriteFlushCount = 1000000;

template<class K, class V1, class V2, class V3>
int TypedGlobalTable<K, V1, V2, V3>::get_shard(const K& k) {
  DCHECK(this != NULL);
  DCHECK(this->info().sharder != NULL);

  Sharder<K> *sharder = (Sharder<K>*)(this->info().sharder);
  int shard = (*sharder)(k, this->info().num_shards);
  DCHECK_GE(shard, 0);
  DCHECK_LT(shard, this->num_shards());
  return shard;
}

template<class K, class V1, class V2, class V3>
int TypedGlobalTable<K, V1, V2, V3>::shard_for_key_str(const StringPiece& k) {
  return get_shard(unmarshal(static_cast<Marshal<K>* >(this->info().key_marshal), k));
}

template<class K, class V1, class V2, class V3>
V1 TypedGlobalTable<K, V1, V2, V3>::get_localF1(const K& k) {
  int shard = this->get_shard(k);

  CHECK(is_local_shard(shard)) << " non-local for shard: " << shard;

  return partition(shard)->getF1(k);
}

template<class K, class V1, class V2, class V3>
V2 TypedGlobalTable<K, V1, V2, V3>::get_localF2(const K& k) {
  int shard = this->get_shard(k);

  CHECK(is_local_shard(shard)) << " non-local for shard: " << shard;

  return partition(shard)->getF2(k);
}

template<class K, class V1, class V2, class V3>
V3 TypedGlobalTable<K, V1, V2, V3>::get_localF3(const K& k) {
  int shard = this->get_shard(k);

  CHECK(is_local_shard(shard)) << " non-local for shard: " << shard;

  return partition(shard)->getF3(k);
}

// Store the given key-value pair in this hash. If 'k' has affinity for a
// remote thread, the application occurs immediately on the local host,
// and the update is queued for transmission to the owner.
template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::put(const K &k, const V1 &v1, const V2 &v2, const V3 &v3) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif
  if (is_local_shard(shard)) {
	  //LOG(INFO) << "This shard is "<< shard <<" and partition is "<< partition(shard) << " \n";
	  //VLOG(1) << "Put value in table is Key is "<<k<<" Value 1 is "<<v1<<" Value 2 is "<<v2; //Deepak
	  partition(shard)->put(k, v1, v2, v3);


  }else{
	  VLOG(1) << "not local put";
	  ++pending_writes_;
  }

  //if (pending_writes_ > kWriteFlushCount) {
    //SendUpdates();
  //}
  BufSend();

  PERIODIC(0.1, {this->HandlePutRequests();});
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::updateF1(const K &k, const V1 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
      partition(shard)->updateF1(k, v);

      ++pending_writes_;
      BufSend();

      PERIODIC(0.1, {this->HandlePutRequests();});
    //VLOG(3) << " shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  } else {
      deltaT(shard)->update(k, v);
  }
/*
  //Deal with updates enqueued inside triggers
  while(!update_queue.empty()) {
    KVPair thispair(update_queue.front());
    update_queue.pop_front();
    update(thispair.first,thispair.second);
  }
  */
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::updateF2(const K &k, const V2 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
      partition(shard)->updateF2(k, v);

    //VLOG(3) << " shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  } else {
	  VLOG(2) << "update F2 shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  }
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::updateF3(const K &k, const V3 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
      partition(shard)->updateF3(k, v);

    //VLOG(3) << " shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  } else {
	  VLOG(2) << "update F3 shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  }
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::accumulateF1(const K &k, const V1 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
       //VLOG(1) << this->owner(shard) << ":" << shard << " accumulate " << v << " on local " << k;
	  partition(shard)->accumulateF1(k, v);
	  //cout<<"PC Local partition("<<shard<<")accumulateAsstFromFPGAF1 Local - Key = "<<k<<" Val = "<<v<<"\n";
  } else {
        //VLOG(1) << this->owner(shard) << ":" << shard << " accumulate " << v << " on remote " << k;
	    deltaT(shard)->accumulate(k, v);
	    //cout<<"PC Delta partition("<<shard<<")accumulate Local - Key = "<<k<<" Val = "<<v<<"\n";
        //++pending_writes_;

        //if (pending_writes_ > kWriteFlushCount) {
          //SendUpdates();
        //}
        //BufSend();

        //PERIODIC(0.1, {this->HandlePutRequests();});
  }
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::accumulateAsstFromFPGAF1(const K &k, const V1 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
       //VLOG(1) << this->owner(shard) << ":" << shard << " accumulate " << v << " on local " << k;
      //VLOG(0)<<"Local partition("<<shard<<")accumulateAsstFromFPGAF1 Local - Key = "<<k<<" Val = "<<v<<"\n";
	  cout<<"The unfortunate happened \n";
	  //cout<<"FPGA Local partition("<<shard<<")accumulateAsstFromFPGAF1 Local - Key = "<<k<<" Val = "<<v<<"\n";


	  //deepak - commenting to avoid the error - see what happens
	  partition(shard)->accumulateAsstFromFPGAF1(k, v);
  } else {
        //VLOG(1) << this->owner(shard) << ":" << shard << " accumulate " << v << " on remote " << k;
	    //VLOG(0)<<"Delta partition("<<shard<<")accumulate Local - Key = "<<k<<" Val = "<<v<<"\n";
	    //cout<<"FPGA Delta partition("<<shard<<")accumulate Local - Key = "<<k<<" Val = "<<v<<"\n";
        deltaT(shard)->accumulate(k, v);
        //++pending_writes_;

        //if (pending_writes_ > kWriteFlushCount) {
          //SendUpdates();
        //}
        //BufSend();

        //PERIODIC(0.1, {this->HandlePutRequests();});
  }
}

//Deepak - accumulate F1 to forward updates to the FPGA node

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::accumulateAsstToFPGAF1(const K &k, const V1 &v) {
  int shard = this->get_shard(k);

//deepak  comment - unnecessary mutex
//#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
//    boost::mutex::scoped_lock sl(trigger_mutex());
//    boost::recursive_mutex::scoped_lock sl(mutex());
//#endif

  /*
  if (is_local_shard(shard)) {
	  FPGAThread *ft;
	  ft = FPGAThread::Get();
	  //deepak - avoid sending miniscule values to the FPGA
	  if(v>MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE) {
		  ft->FPGASendKVPair((*(int*)&k),(*(int*)&v));
	  }
//	  boost::this_thread::sleep( boost::posix_time::seconds(0.2) ); // try to slow down the sends

  } else {
	  cout<<"Got a key that I never wanted! key = "<<k<<" val = "<<v<<"\n";
	  //deltaT(shard)->accumulate(k, v);
  }
  */
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::accumulateF2(const K &k, const V2 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
      partition(shard)->accumulateF2(k, v);

    //VLOG(3) << " shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  } else {
	  VLOG(2) << "accumulate F2 shard " << shard << " local? " << " : " << is_local_shard(shard);
  }
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::accumulateF3(const K &k, const V3 &v) {
  int shard = this->get_shard(k);

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
    boost::mutex::scoped_lock sl(trigger_mutex());
    boost::recursive_mutex::scoped_lock sl(mutex());
#endif

  if (is_local_shard(shard)) {
      partition(shard)->accumulateF3(k, v);

    //VLOG(3) << " shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  } else {
	  VLOG(2) << "accumulate F3 shard " << shard << " local? " << " : " << is_local_shard(shard) << " : " << worker_id_;
  }
}

template<class K, class V1, class V2, class V3>
void TypedGlobalTable<K, V1, V2, V3>::enqueue_updateF1(K k, V1 v) {
  const KVPair thispair(k,v);
  update_queue.push_back(thispair);
}

// Return the value associated with 'k', possibly blocking for a remote fetch.
template<class K, class V1, class V2, class V3>
ClutterRecord<K, V1, V2, V3> TypedGlobalTable<K, V1, V2, V3>::get(const K &k) {
  int shard = this->get_shard(k);

  CHECK_EQ(is_local_shard(shard), true) << "key " << k << " is not located in local table";
#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
        boost::recursive_mutex::scoped_lock sl(mutex());
#endif
  return partition(shard)->get(k);
}

// Return the value associated with 'k', possibly blocking for a remote fetch.
template<class K, class V1, class V2, class V3>
V1 TypedGlobalTable<K, V1, V2, V3>::getF1(const K &k) {
  int shard = this->get_shard(k);

  CHECK_EQ(is_local_shard(shard), true) << "key " << k << " is not located in local table";

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
        boost::recursive_mutex::scoped_lock sl(mutex());
#endif
    return partition(shard)->getF1(k);
}

// Return the value associated with 'k', possibly blocking for a remote fetch.
template<class K, class V1, class V2, class V3>
V2 TypedGlobalTable<K, V1, V2, V3>::getF2(const K &k) {
  int shard = this->get_shard(k);

  CHECK_EQ(is_local_shard(shard), true) << "key " << k << " is not located in local table";

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
        boost::recursive_mutex::scoped_lock sl(mutex());
#endif
    return partition(shard)->getF2(k);
}

// Return the value associated with 'k', possibly blocking for a remote fetch.
template<class K, class V1, class V2, class V3>
V3 TypedGlobalTable<K, V1, V2, V3>::getF3(const K &k) {
  int shard = this->get_shard(k);

  CHECK_EQ(is_local_shard(shard), true) << "key " << k << " is not located in local table";

#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
        boost::recursive_mutex::scoped_lock sl(mutex());
#endif
    return partition(shard)->getF3(k);
}

template<class K, class V1, class V2, class V3>
bool TypedGlobalTable<K, V1, V2, V3>::contains(const K &k) {
  int shard = this->get_shard(k);

  if (is_local_shard(shard)) {
#ifdef GLOBAL_TABLE_USE_SCOPEDLOCK
        boost::recursive_mutex::scoped_lock sl(mutex());
#endif
    return partition(shard)->contains(k);
  }else {
	  return false;
  }
}

template<class K, class V1, class V2, class V3>
bool TypedGlobalTable<K, V1, V2, V3>::remove(const K &k) {
	  int shard = this->get_shard(k);

	  if (is_local_shard(shard)) {
	    return partition(shard)->remove(k);
	    return true;
	  }else {
		  return false;
	  }
}

template<class K, class V1, class V2, class V3>
LocalTable* TypedGlobalTable<K, V1, V2, V3>::create_localT(int shard) {
  TableDescriptor *linfo = new TableDescriptor(info());
  linfo->shard = shard;
  VLOG(2) << "create local statetable " << shard;
  LocalTable* t = (LocalTable*)info_.partition_factory->New();
  t->Init(linfo);

  return t;
}

template<class K, class V1, class V2, class V3>
LocalTable* TypedGlobalTable<K, V1, V2, V3>::create_deltaT(int shard) {
  TableDescriptor *linfo = new TableDescriptor(info());
  linfo->shard = shard;
  VLOG(2) << "create local deltatable " << shard;
  LocalTable* t = (LocalTable*)info_.deltaT_factory->New();
  t->Init(linfo);

  return t;
}

template<class K, class V1, class V2, class V3>
TableIterator* TypedGlobalTable<K, V1, V2, V3>::get_iterator(int shard, bool bfilter, unsigned int fetch_num) {
      CHECK_EQ(this->is_local_shard(shard), true) << "should use local get_iterator";

      if(info().schedule_portion < 1){;
              return (TypedTableIterator<K, V1, V2, V3>*) partitions_[shard]->schedule_iterator(this->helper(), bfilter);
      }else{
              return (TypedTableIterator<K, V1, V2, V3>*) partitions_[shard]->get_iterator(this->helper(), bfilter);
      }
}

//Deepak - new API
template<class K, class V1, class V2, class V3>
bool TypedGlobalTable<K, V1, V2, V3>::check_for_termination(int shard) {
      CHECK_EQ(this->is_local_shard(shard), true) << "should use local get_iterator";

      return partitions_[shard]->isTerminated(this->helper());
}

//Deepak - new API
template<class K, class V1, class V2, class V3>
bool TypedGlobalTable<K, V1, V2, V3>::send_fpga_asst_updates(int shard) {
      CHECK_EQ(this->is_local_shard(shard), true) << "should use local get_iterator";

      return partitions_[shard]->sendFPGAAsstUpdates(this->helper());
}
}
#endif /* GLOBALTABLE_H_ */
