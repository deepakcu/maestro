/*
 * deltatable.h
 *
 *  Created on: Aug 4, 2011
 *      Author: yzhang
 */

#ifndef DELTATABLE_H_
#define DELTATABLE_H_

#include "util/common.h"
#include "worker/worker.pb.h"
#include "kernel/table.h"
#include "kernel/local-table.h"
#include <boost/noncopyable.hpp>

namespace dsm {

template <class K, class V1>
class DeltaTable :
	public LocalTable,
	public PTypedTable<K, V1>,
  private boost::noncopyable {
private:
#pragma pack(push, 1)
  struct Bucket {
    K k;
    V1 v1;
    bool in_use;
  };
#pragma pack(pop)

public:
  typedef FileDecodeIterator<K, V1, int, int> FileUpdateDecoder;
  typedef NetDecodeIterator<K, V1> NetUpdateDecoder;

  struct Iterator : public PTypedTableIterator<K, V1> {
    Iterator(DeltaTable<K, V1>& parent) : pos(-1), parent_(parent) {
      Next();
    }

    Marshal<K>* kmarshal() { return parent_.kmarshal(); }
    Marshal<V1>* v1marshal() { return parent_.v1marshal(); }

    void Next() {
      do {
        ++pos;
      } while (pos < parent_.size_ && !parent_.buckets_[pos].in_use);
    }

    bool done() {
      return pos == parent_.size_;
    }

    const K& key() { return parent_.buckets_[pos].k; }
    V1& value1() { return parent_.buckets_[pos].v1; }

    int pos;
    DeltaTable<K, V1> &parent_;
  };

  struct Factory : public TableFactory {
    TableBase* New() { return new DeltaTable<K, V1>(); }
  };

  // Construct a DeltaTable with the given initial size; it will be expanded as necessary.
  DeltaTable(int size=1);
  ~DeltaTable() {}

  void Init(const TableDescriptor* td) {
    TableBase::Init(td);
  }

  V1 get(const K& k);
  bool contains(const K& k);
  void put(const K& k, const V1& v1);
  void update(const K& k, const V1& v);
  void accumulate(const K& k, const V1& v);
  bool remove(const K& k) {
    LOG(FATAL) << "Not implemented.";
    return false;
  }

  void resize(int64_t size);

  bool empty() { return size() == 0; }
  int64_t size() { return entries_; }

  void clear() {
    for (int i = 0; i < size_; ++i) { buckets_[i].in_use = 0; }
    entries_ = 0;
  }

  void reset(){
	  buckets_.clear();
	  size_ = 0;
	  entries_ = 0;
	  resize(1);
  }

  //Deepak - implement the new virtual function
  bool isTerminated(TableHelper* helper) {
      cout<<"FPGA Delta table isTerminated\n";
	  return false;
  }
  bool sendFPGAAsstUpdates(TableHelper* helper) {
	  	  return false;
  }
  TableIterator *get_iterator(TableHelper* helper, bool bfilter) {
      return new Iterator(*this);
  }

  TableIterator *schedule_iterator(TableHelper* helper, bool bfilter) {
      return NULL;
  }
  
  TableIterator *entirepass_iterator(TableHelper* helper) {
      return NULL;
  }

  void serializeToFile(TableCoder *out);
  void serializeToNet(KVPairCoder *out);
  void deserializeFromFile(TableCoder *in, DecodeIteratorBase *itbase);
  void deserializeFromNet(KVPairCoder *in, DecodeIteratorBase *itbase);
  void deserializeFromFPGA(char * buf, int len, DecodeIteratorBase *itbase);
  void serializeToSnapshot(const string& f, int* updates, double* totalF2) {return;}

  Marshal<K>* kmarshal() { return ((Marshal<K>*)info_.key_marshal); }
  Marshal<V1>* v1marshal() { return ((Marshal<V1>*)info_.value1_marshal); }

private:
  uint32_t bucket_idx(K k) {
    return hashobj_(k) % size_;
  }

  int bucket_for_key(const K& k) {
    int start = bucket_idx(k);
    int b = start;

    do {
      if (buckets_[b].in_use) {
        if (buckets_[b].k == k) {
          return b;
        }
      } else {
        return -1;
      }

       b = (b + 1) % size_;
    } while (b != start);

    return -1;
  }

  std::vector<Bucket> buckets_;

  int64_t entries_;
  int64_t size_;

  std::tr1::hash<K> hashobj_;
};

template <class K, class V1>
DeltaTable<K, V1>::DeltaTable(int size)
  : buckets_(0), entries_(0), size_(0) {
  clear();

  resize(size);
}

template <class K, class V1>
void DeltaTable<K, V1>::serializeToFile(TableCoder *out) {
  Iterator *i = (Iterator*)get_iterator(NULL, false);
  string k, v1;
  while (!i->done()) {
    k.clear(); v1.clear();
    ((Marshal<K>*)info_.key_marshal)->marshal(i->key(), &k);
    ((Marshal<V1>*)info_.value1_marshal)->marshal(i->value1(), &v1);
    out->WriteEntryToFile(k, v1, "", "");
    i->Next();
  }
  delete i;
}

template <class K, class V1>
void DeltaTable<K, V1>::serializeToNet(KVPairCoder *out) {
  Iterator *i = (Iterator*)get_iterator(NULL, false);
  string k, v1;
  while (!i->done()) {
    k.clear(); v1.clear();;
    ((Marshal<K>*)info_.key_marshal)->marshal(i->key(), &k);
    ((Marshal<V1>*)info_.value1_marshal)->marshal(i->value1(), &v1);
    out->WriteEntryToNet(k, v1);
    i->Next();
  }
  delete i;
}

template <class K, class V1>
void DeltaTable<K, V1>::deserializeFromFile(TableCoder *in, DecodeIteratorBase *itbase) {
  FileUpdateDecoder* it = static_cast<FileUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  string kt, v1t, v2t, v3t;

  it->clear();
  while (in->ReadEntryFromFile(&kt, &v1t, &v2t, &v3t)) {
    ((Marshal<K>*)info_.key_marshal)->unmarshal(kt, &k);
    ((Marshal<V1>*)info_.value1_marshal)->unmarshal(v1t, &v1);
    it->append(k, v1, 0, 0);
  }
  it->rewind();
  return;
}

template <class K, class V1>
void DeltaTable<K, V1>::deserializeFromNet(KVPairCoder *in, DecodeIteratorBase *itbase) {
  NetUpdateDecoder* it = static_cast<NetUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  string kt, v1t;

  it->clear();
  while (in->ReadEntryFromNet(&kt, &v1t)) {
    ((Marshal<K>*)info_.key_marshal)->unmarshal(kt, &k);
    ((Marshal<V1>*)info_.value1_marshal)->unmarshal(v1t, &v1);
    it->append(k, v1);
  }
  it->rewind();
  return;
}

//Deepak - decode FPGA buffer
template <class K, class V1>
void DeltaTable<K, V1>::deserializeFromFPGA(char *buf, int len, DecodeIteratorBase *itbase) {
  NetUpdateDecoder* it = static_cast<NetUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  string kt, v1t;
  int i=0;

  char *buf_it = buf;

  it->clear();
  while (i!=len) {
	string kt(buf_it,buf_it+sizeof(int));
	buf_it+=sizeof(int);
	string vlt(buf_it,buf_it+sizeof(int));
    ((Marshal<K>*)info_.key_marshal)->unmarshalFPGA(kt, &k);
    ((Marshal<V1>*)info_.value1_marshal)->unmarshalFPGA(v1t, &v1);
    it->append(k, v1);
    i+=(2*sizeof(int));
  }
  it->rewind();
  return;
}

//Deepak - serialize key value pairs to FPGA


template <class K, class V1>
void DeltaTable<K, V1>::resize(int64_t size) {
  CHECK_GT(size, 0);
  if (size_ == size)
    return;

  std::vector<Bucket> old_b = buckets_;
  int old_entries = entries_;

  VLOG(2) << "Rehashing... " << entries_ << " : " << size_ << " -> " << size;

  buckets_.resize(size);
  size_ = size;
  clear();

  for (int i = 0; i < old_b.size(); ++i) {
    if (old_b[i].in_use) {
      put(old_b[i].k, old_b[i].v1);
    }
  }

  CHECK_EQ(old_entries, entries_);
}

template <class K, class V1>
bool DeltaTable<K, V1>::contains(const K& k) {
  return bucket_for_key(k) != -1;
}

template <class K, class V1>
V1 DeltaTable<K, V1>::get(const K& k) {
  int b = bucket_for_key(k);
  //The following key display is a hack hack hack and only yields valid
  //results for ints.  It will display nonsense for other types.
  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

  return buckets_[b].v1;
}

template <class K, class V1>
void DeltaTable<K, V1>::update(const K& k, const V1& v) {
	int b = bucket_for_key(k);

	CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

	buckets_[b].v1 = v;
}

template <class K, class V1>
void DeltaTable<K, V1>::accumulate(const K& k, const V1& v) {
  int b = bucket_for_key(k);

  if(b == -1){
	  put(k, v);
  }else{
	  ((Accumulator<V1>*)info_.accum)->accumulate(&buckets_[b].v1, v);
  }
}

template <class K, class V1>
void DeltaTable<K, V1>::put(const K& k, const V1& v1) {
  int start = bucket_idx(k);
  int b = start;
  bool found = false;

  VLOG(2) << "put " << k << "," << v1 << " into deltatable";
  do {
    if (!buckets_[b].in_use) {
      break;
    }

    if (buckets_[b].k == k) {
      found = true;
      break;
    }

    b = (b + 1) % size_;
  } while(b != start);

  // Inserting a new entry:
  if (!found) {
    if (entries_ > size_ * kLoadFactor) {
      resize((int)(1 + size_ * 2));
      put(k, v1);
    } else {
      buckets_[b].in_use = 1;
      buckets_[b].k = k;
      buckets_[b].v1 = v1;
      ++entries_;
    }
  } else {
    // Replacing an existing entry
    buckets_[b].v1 = v1;
  }
}
}


#endif /* DELTATABLE_H_ */
