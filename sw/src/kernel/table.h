#ifndef ACCUMULATOR_H
#define ACCUMULATOR_H

#define FETCH_NUM 2048

#include "util/common.h"
#include "util/file.h"
#include "worker/worker.pb.h"
#include <boost/thread.hpp>

DECLARE_double(termcheck_threshold);

namespace dsm {

struct TableBase;
struct Table;

template <class K, class V1, class V2, class V3>
class TypedGlobalTable;


class TableData;

// This interface is used by global tables to communicate with the outside
// world and determine the current state of a computation.
struct TableHelper {
  virtual int id() const = 0;
  virtual int epoch() const = 0;
  virtual int peer_for_shard(int table, int shard) const = 0;
  virtual void HandlePutRequest() = 0;
  virtual void startHandlePutRequestFromFPGA() = 0; //deepak new
  virtual void HandlePutRequestToFPGA() = 0;
  virtual void HandlePutRequestFromFPGA() = 0;
  virtual void FlushUpdates() = 0;
  virtual void SendTermcheck(int index, int updates, double current) = 0;
};

struct SharderBase {};
struct InitializerBase {};
struct FPGAInitializerBase {};
struct AccumulatorBase {};
struct SenderBase {};
struct TermCheckerBase {};

struct BlockInfoBase {};


typedef int TriggerID;
struct TriggerBase {
  Table *table;
  TableHelper *helper;
  TriggerID triggerid;

  TriggerBase() {
    enabled_ = true;
  }
  virtual void enable(bool enabled__) { enabled_ = enabled__; }
  virtual bool enabled() { return enabled_; }

private:
  bool enabled_;
};


// Triggers are registered at table initialization time, and
// are executed in response to changes to a table.s
//
// When firing, triggers are activated in the order specified at
// initialization time.
template <class K, class V>
struct Trigger : public TriggerBase {
  virtual bool Fire(const K& k, const V& current, V& update) = 0;
};

//#ifdef SWIGPYTHON
//template <class K, class V> class TriggerDescriptor : public Trigger;
//#endif

#ifndef SWIG

// Each table is associated with a single accumulator.  Accumulators are
// applied whenever an update is supplied for an existing key-value cell.
template <class K>
struct Sharder : public SharderBase {
  virtual int operator()(const K& k, int shards) = 0;
};

template <class K, class V, class D>
struct Initializer : public InitializerBase {
  virtual void initTable(TypedGlobalTable<K, V, V, D>* table, int shard_id, int num_nodes, vector<fpgaWord> &keys, vector<fpgaWord> &ptrdata) = 0;
};

template <class K, class V, class D>
struct FPGAInitializer : public FPGAInitializerBase {
  virtual void sendKVPairsToFPGA(const K& k, const V& v, const V& deltav, const D& data, int shard_id, unsigned int *key_address, unsigned int *link_address, vector<fpgaWord> &keys) = 0;
};

template <class V>
struct Accumulator : public AccumulatorBase {
  virtual void accumulate(V* a, const V& b) = 0;
  virtual V priority(const V& delta, const V& state) = 0;
};

template <class K, class V, class D>
struct Sender : public SenderBase {
  virtual void send(const V& delta, const D& data, vector<pair<K, V> >* output) = 0;
  virtual const V& reset() const = 0;
};

template <class K, class V>
struct LocalTableIterator {
    virtual const K& key() = 0;
    virtual V& value2() = 0;
    virtual bool done() = 0;
    virtual void Next() = 0;
    virtual V defaultV() = 0;
};

template <class K, class V>
struct TermChecker : public TermCheckerBase {
    virtual double set_curr() = 0;
    virtual double local_report(LocalTableIterator<K, V>* statetable) = 0;
    virtual bool terminate(vector<double> local_reports) = 0;
};

// Commonly used accumulation and sharding operators.

struct Sharding {
  struct String  : public Sharder<string> {
    int operator()(const string& k, int shards) { return StringPiece(k).hash() % shards; }
  };

  struct Mod : public Sharder<int> {
    int operator()(const int& key, int shards) { return key % shards; }
  };

  struct UintMod : public Sharder<uint32_t> {
    int operator()(const uint32_t& key, int shards) { return key % shards; }
  };
};


template <class V>
struct Accumulators {
  struct Min : public Accumulator<V> {
    void accumulate(V* a, const V& b) { *a = std::min(*a, b); }
    V priority(const V& delta, const V& state) {return state - std::min(state, delta);}
  };

  struct Max : public Accumulator<V> {
    void accumulate(V* a, const V& b) { *a = std::max(*a, b); }
    V priority(const V& delta, const V& state) {return std::max(state, delta) - state;}
  };

  struct Sum : public Accumulator<V> {
    void accumulate(V* a, const V& b) { *a = *a + b; }

    V priority(const V& delta, const V& state) {return delta;}
  };
};


template <class K, class V>
struct TermCheckers {
  struct Diff : public TermChecker<K, V> {
    double last;
    double curr;
    
    Diff(){
        last = -std::numeric_limits<double>::max();;
        curr = 0;
    }

    double set_curr(){
        return curr;
    }
    
    double local_report(LocalTableIterator<K, V>* statetable){
        double partial_curr = 0;
        V defaultv = statetable->defaultV();
        while(!statetable->done()){
            statetable->Next();
            if(statetable->value2() != defaultv){
                partial_curr += static_cast<double>(statetable->value2());
            }
        }
        return partial_curr;
    }
   
    //Deepak - my new terminate checking rule (to have a condition where we check for minimum value instead of sum
    /*
    bool terminate(vector<double> local_reports){
            curr = std::numeric_limits<float>::max();
            vector<double>::iterator it;
            for(it=local_reports.begin(); it!=local_reports.end(); it++){
                    //curr += *it;
            		if(*it<curr) //check for the lowest value among all values
            			curr=*it;
            }

            VLOG(0) << "terminate check : last progress " << last << " current progress " << curr << " difference " << abs(curr - last);
            if(abs(curr - last) <= FLAGS_termcheck_threshold){
                return true;
            }else{
                last = curr;
                return false;
            }
        }
	*/

    
    bool terminate(vector<double> local_reports){
        curr = 0;
        vector<double>::iterator it;
        for(it=local_reports.begin(); it!=local_reports.end(); it++){
                curr += *it;
        }
        
        VLOG(0) << "terminate check : last progress " << last << " current progress " << curr << " difference " << abs(curr - last);
        if(abs(curr - last) <= FLAGS_termcheck_threshold){
            return true;
        }else{
            last = curr;
            return false;
        }
    }
    
  };
};
#endif		//#ifdef SWIG / #else

struct TableFactory {
  virtual TableBase* New() = 0;
};

struct TableDescriptor {
public:
	TableDescriptor() { Reset(); }

	TableDescriptor(int id, int shards) {
    Reset();
    table_id = id;
    num_shards = shards;
  }

  void Reset() {
    table_id = -1;
    num_shards = -1;
    max_stale_time = 0.;
    helper = NULL;
    partition_factory = NULL;
    key_marshal = value1_marshal = value2_marshal = value3_marshal = NULL;
    accum = NULL;
    sharder = NULL;
    initializer = NULL;
    sender = NULL;
    termchecker = NULL;
  }

  int table_id;
  int num_shards;

  // For local tables, the shard of the global table they represent.
  int shard;
  int default_shard_size;
  double schedule_portion;
  

  vector<TriggerBase*> triggers;

  SharderBase *sharder;
  InitializerBase *initializer;
  AccumulatorBase *accum;
  SenderBase *sender;
  TermCheckerBase *termchecker;

  MarshalBase *key_marshal;
  MarshalBase *value1_marshal;
  MarshalBase *value2_marshal;
  MarshalBase *value3_marshal;

  // For global tables, factory for constructing new partitions.
  TableFactory *partition_factory;
  TableFactory *deltaT_factory;

  // For global tables, the maximum amount of time to cache remote values
  double max_stale_time;

  // For global tables, reference to the local worker.  Used for passing
  // off remote access requests.
  TableHelper *helper;
};

class TableIterator;

struct Table {
  virtual const TableDescriptor& info() const = 0;
  virtual TableDescriptor& mutable_info() = 0;
  virtual int id() const = 0;
  virtual int num_shards() const = 0;
};

struct UntypedTable {
  virtual bool contains_str(const StringPiece& k) = 0;
  virtual string get_str(const StringPiece &k) = 0;
  virtual void update_str(const StringPiece &k, const StringPiece &v1, const StringPiece &v2, const StringPiece &v3) = 0;
};

struct TableIterator {
  virtual void key_str(string *out) = 0;
  virtual void value1_str(string *out) = 0;
  virtual void value2_str(string *out) = 0;
  virtual void value3_str(string *out) = 0;
  virtual bool done() = 0;
  virtual void Next() = 0;
};

// Methods common to both global and local table views.
class TableBase : public Table {
public:
  typedef TableIterator Iterator;
    virtual void Init(const TableDescriptor* info) {
	info_ = *info;
        terminated_ = false;
    CHECK(info_.key_marshal != NULL);
    CHECK(info_.value1_marshal != NULL);
    CHECK(info_.value2_marshal != NULL);
    CHECK(info_.value3_marshal != NULL);
  }

  const TableDescriptor& info() const { return info_; }
  TableDescriptor& mutable_info() { return info_; }
  int id() const { return info().table_id; }
  int num_shards() const { return info().num_shards; }

  TableHelper *helper() { return info().helper; }
  int helper_id() { return helper()->id(); }

  int num_triggers() { return info_.triggers.size(); }
  TriggerBase *trigger(int idx) { return info_.triggers[idx]; }

  TriggerID register_trigger(TriggerBase *t) {
    if (helper()) {
      t->helper = helper();
    }
    t->table = this;
	t->triggerid = info_.triggers.size();

    info_.triggers.push_back(t);
    return t->triggerid;
  }

  void set_helper(TableHelper *w) {
    for (int i = 0; i < info_.triggers.size(); ++i) {
      trigger(i)->helper = w;
    }

    info_.helper = w;
  }
  
  void terminate(){
      terminated_ = true;
  }

protected:
  TableDescriptor info_;
  bool terminated_;
};

template <class K, class V1, class V2, class V3>
	struct ClutterRecord
	{
		K k;
		V1 v1;
		V2 v2;
		V3 v3;

		ClutterRecord()
		: k(), v1(), v2(), v3() { }

		ClutterRecord(const K& __a, const V1& __b, const V2& __c, const V3& __d)
		: k(__a), v1(__b), v2(__c), v3(__d) { }

	    template<class K1, class U1, class U2, class U3>
	    	ClutterRecord(const ClutterRecord<K1, U1, U2, U3>& __p)
		: k(__p.k),
		  v1(__p.v1),
		  v2(__p.v2),
		  v3(__p.v3) { }

	    ostream& operator<<(ostream& out)
	    {
	    	return out<< k << "\t" << v1 << "|" << v2 << "|" << v3;
	    }
	};

// Key/value typed interface.
template <class K, class V1, class V2, class V3>
class TypedTable : virtual public UntypedTable {
public:
  virtual bool contains(const K &k) = 0;
  virtual V1 getF1(const K &k) = 0;
  virtual V2 getF2(const K &k) = 0;
  virtual V3 getF3(const K &k) = 0;
  virtual ClutterRecord<K, V1, V2, V3> get(const K &k) = 0;
  virtual void put(const K &k, const V1 &v1, const V2 &v2, const V3 &v3) = 0;
  virtual void updateF1(const K &k, const V1 &v) = 0;
  virtual void updateF2(const K &k, const V2 &v) = 0;
  virtual void updateF3(const K &k, const V3 &v) = 0;
  virtual void accumulateF1(const K &k, const V1 &v) = 0;
  virtual void accumulateAsstFromFPGAF1(const K &k, const V1 &v) = 0;
  virtual void accumulateAsstToFPGAF1(const K &k, const V1 &v) = 0;

  virtual void accumulateF2(const K &k, const V2 &v) = 0;
  virtual void accumulateF3(const K &k, const V3 &v) = 0;
  virtual bool remove(const K &k) = 0;

  // Default specialization for untyped methods
  virtual bool contains_str(const StringPiece& s) {
    K k;
    kmarshal()->unmarshal(s, &k);
    return contains(k);
  }

  virtual string get_str(const StringPiece &s) {
    K k;
    string f1, f2, f3;

    kmarshal()->unmarshal(s, &k);
    v1marshal()->marshal(getF1(k), &f1);
    v2marshal()->marshal(getF2(k), &f2);
    v3marshal()->marshal(getF3(k), &f3);
    return f1+f2+f3;
  }

  virtual void update_str(const StringPiece& kstr, const StringPiece &vstr1, const StringPiece &vstr2, const StringPiece &vstr3) {
    K k; V1 v1; V2 v2; V3 v3;
    kmarshal()->unmarshal(kstr, &k);
    v1marshal()->unmarshal(vstr1, &v1);
    v2marshal()->unmarshal(vstr2, &v2);
    v3marshal()->unmarshal(vstr3, &v3);
    put(k, v1, v2, v3);
  }

protected:
  virtual Marshal<K> *kmarshal() = 0;
  virtual Marshal<V1> *v1marshal() = 0;
  virtual Marshal<V2> *v2marshal() = 0;
  virtual Marshal<V3> *v3marshal() = 0;
};

template <class K, class V1, class V2, class V3>
struct TypedTableIterator : public TableIterator {
  virtual const K& key() = 0;
  virtual V1& value1() = 0;
  virtual V2& value2() = 0;
  virtual V3& value3() = 0;

  virtual void key_str(string *out) { kmarshal()->marshal(key(), out); }
  virtual void value1_str(string *out) { v1marshal()->marshal(value1(), out); }
  virtual void value2_str(string *out) { v2marshal()->marshal(value2(), out); }
  virtual void value3_str(string *out) { v3marshal()->marshal(value3(), out); }

protected:
  virtual Marshal<K> *kmarshal() {
    static Marshal<K> m;
    return &m;
  }

  virtual Marshal<V1> *v1marshal() {
    static Marshal<V1> m;
    return &m;
  }

  virtual Marshal<V2> *v2marshal() {
    static Marshal<V2> m;
    return &m;
  }

  virtual Marshal<V3> *v3marshal() {
    static Marshal<V3> m;
    return &m;
  }
};

template <class K, class V1, class V2, class V3> struct TypedTableIterator;

// Key/value typed interface.
template <class K, class V1>
class PTypedTable : virtual public UntypedTable {
public:
  virtual bool contains(const K &k) = 0;
  virtual V1 get(const K &k) = 0;
  virtual void put(const K &k, const V1 &v1) = 0;
  virtual void update(const K &k, const V1 &v) = 0;
  virtual void accumulate(const K &k, const V1 &v) = 0;
  virtual bool remove(const K &k) = 0;

  // Default specialization for untyped methods
  virtual bool contains_str(const StringPiece& s) {
    K k;
    kmarshal()->unmarshal(s, &k);
    return contains(k);
  }

  virtual string get_str(const StringPiece &s) {
	K k;
	string out;

	kmarshal()->unmarshal(s, &k);
	v1marshal()->marshal(get(k), &out);
	return out;
  }

  virtual void update_str(const StringPiece& kstr, const StringPiece &vstr1, const StringPiece &vstr2, const StringPiece &vstr3) {
    K k; V1 v1;
    kmarshal()->unmarshal(kstr, &k);
    v1marshal()->unmarshal(vstr1, &v1);
    put(k, v1);
  }

protected:
  virtual Marshal<K> *kmarshal() = 0;
  virtual Marshal<V1> *v1marshal() = 0;
};

template <class K, class V1>
struct PTypedTableIterator : public TableIterator {
  virtual const K& key() = 0;
  virtual V1& value1() = 0;

  virtual void key_str(string *out) { kmarshal()->marshal(key(), out); }
  virtual void value1_str(string *out) { v1marshal()->marshal(value1(), out); }
  virtual void value2_str(string *out) { v1marshal()->marshal(value1(), out); }
  virtual void value3_str(string *out) { v1marshal()->marshal(value1(), out); }

protected:
  virtual Marshal<K> *kmarshal() {
    static Marshal<K> m;
    return &m;
  }

  virtual Marshal<V1> *v1marshal() {
    static Marshal<V1> m;
    return &m;
  }
};

struct DecodeIteratorBase {
};


// Added for the sake of triggering on remote updates/puts <CRM>
template <typename K, typename V1, typename V2, typename V3>
struct FileDecodeIterator : public TypedTableIterator<K, V1, V2, V3>, public DecodeIteratorBase {

  Marshal<K>* kmarshal() { return NULL; }
  Marshal<V1>* v1marshal() { return NULL; }
  Marshal<V2>* v2marshal() { return NULL; }
  Marshal<V3>* v3marshal() { return NULL; }

  FileDecodeIterator() {
    clear();
    rewind();
  }
  void append(K k, V1 v1, V2 v2, V3 v3) {
	  ClutterRecord<K, V1, V2, V3> thispair(k, v1, v2, v3);
    decodedeque.push_back(thispair);
//    LOG(ERROR) << "APPEND";
  }
  void clear() {
    decodedeque.clear();
//    LOG(ERROR) << "CLEAR";
  }
  void rewind() {
    intit = decodedeque.begin();
//    LOG(ERROR) << "REWIND: empty? " << (intit == decodedeque.end());
  }
  bool done() {
    return intit == decodedeque.end();
  }
  void Next() {
    intit++;
  }
  const K& key() {
    static K k2;
    if (intit != decodedeque.end()) {
      k2 = intit->k;
    }
    return k2;
  }
  V1& value1() {
    static V1 vv;
    if (intit != decodedeque.end()) {
      vv = intit->v1;
    }
    return vv;
  }
  V2& value2() {
    static V2 vv;
    if (intit != decodedeque.end()) {
      vv = intit->v2;
    }
    return vv;
  }
  V3& value3() {
    static V3 vv;
    if (intit != decodedeque.end()) {
      vv = intit->v3;
    }
    return vv;
  }

private:
  std::vector<ClutterRecord<K, V1, V2, V3> > decodedeque;
  typename std::vector<ClutterRecord<K, V1, V2, V3> >::iterator intit;
};

template <typename K, typename V1>
struct NetDecodeIterator : public PTypedTableIterator<K, V1>, public DecodeIteratorBase {

  Marshal<K>* kmarshal() { return NULL; }
  Marshal<V1>* v1marshal() { return NULL; }

  NetDecodeIterator() {
    clear();
    rewind();
  }
  void append(K k, V1 v1) {
	  pair<K, V1> thispair(k, v1);
    decodedeque.push_back(thispair);
//    LOG(ERROR) << "APPEND";
  }
  void clear() {
    decodedeque.clear();
//    LOG(ERROR) << "CLEAR";
  }
  void rewind() {
    intit = decodedeque.begin();
//    LOG(ERROR) << "REWIND: empty? " << (intit == decodedeque.end());
  }
  bool done() {
    return intit == decodedeque.end();
  }
  void Next() {
    intit++;
  }
  const K& key() {
    static K k2;
    if (intit != decodedeque.end()) {
      k2 = intit->first;
    }
    return k2;
  }
  V1& value1() {
    static V1 vv;
    if (intit != decodedeque.end()) {
      vv = intit->second;
    }
    return vv;
  }

private:
  std::vector<pair<K, V1> > decodedeque;
  typename std::vector<pair<K, V1> >::iterator intit;
};

// Checkpoint and restoration.
class Checkpointable {
public:
  virtual void start_checkpoint(const string& f) = 0;
  virtual void write_delta(const KVPairData& put) = 0;
  virtual void finish_checkpoint() = 0;
  virtual void restore(const string& f) = 0;
};

// Interface for serializing tables, either to disk or for transmitting via RPC.
struct TableCoder {
  virtual void WriteEntryToFile(StringPiece k, StringPiece v1, StringPiece v2, StringPiece v3) = 0;
  virtual bool ReadEntryFromFile(string* k, string *v1, string *v2, string *v3) = 0;

  virtual ~TableCoder() {}
};

// Interface for serializing tables, either to disk or for transmitting via RPC.
struct KVPairCoder {
  virtual void WriteEntryToNet(StringPiece k, StringPiece v1) = 0;
  virtual bool ReadEntryFromNet(string* k, string *v1) = 0;

  virtual ~KVPairCoder() {}
};

class Serializable {
public:
  virtual void deserializeFromFile(TableCoder *in, DecodeIteratorBase *it) = 0;
  virtual void serializeToFile(TableCoder* out) = 0;
};

class Transmittable {
public:
  virtual void deserializeFromNet(KVPairCoder *in, DecodeIteratorBase *it) = 0;
  virtual void serializeToNet(KVPairCoder* out) = 0;
  virtual void deserializeFromFPGA(char * buf, int len, DecodeIteratorBase *itbase) = 0;
};

class Snapshottable {
public:
  virtual void serializeToSnapshot(const string& f, int* updates, double* totalF2) = 0;
};

}

#endif
