#ifndef SPARSE_MAP_H_
#define SPARSE_MAP_H_

#include "util/common.h"
#include "worker/worker.pb.h"
#include "kernel/table.h"
#include "kernel/local-table.h"
#include <boost/noncopyable.hpp>
#include <boost/random/mersenne_twister.hpp>
#include <boost/random/uniform_int.hpp>
#include <boost/random/lognormal_distribution.hpp>
#include <boost/random/variate_generator.hpp>
#include <algorithm>
#include <stdio.h>
#include <boost/lexical_cast.hpp>

namespace dsm {

static const int sample_size =1000; //deepak - default sample_size is 1000 (commented for now)
//static const int sample_size = 16;

template <class K, class V1, class V2, class V3>
struct ClutterRecord;

template <class K, class V1, class V2, class V3>
class StateTable :
  public LocalTable,
  public TypedTable<K, V1, V2, V3>,
  private boost::noncopyable {
private:
#pragma pack(push, 1)
  struct Bucket {
    K k;
    V1 v1;
    V2 v2;
    V3 v3;
    V1 priority;
    bool in_use;
  };
#pragma pack(pop)

public:
  typedef FileDecodeIterator<K, V1, V2, V3> FileUpdateDecoder;
  typedef NetDecodeIterator<K, V1> NetUpdateDecoder;

  struct Iterator : public TypedTableIterator<K, V1, V2, V3> {
        Iterator(StateTable<K, V1, V2, V3>& parent, bool bfilter) : pos(-1), parent_(parent) {
            if(bfilter){
                //check if there is a change
                b_no_change = true;

                //random number generator
                boost::mt19937 gen(time(0));
                boost::uniform_int<> dist(0, parent_.buckets_.size()-1);
                boost::variate_generator<boost::mt19937&, boost::uniform_int<> > rand_num(gen, dist);

                defaultv = ((Sender<K, V1, V3>*)parent_.info_.sender)->reset();
                int i;
                for(i=0; i<sample_size && b_no_change; i++){
                    int rand_pos = rand_num();
                    while(!parent_.buckets_[rand_pos].in_use){
                        rand_pos = rand_num();
                    }

                    b_no_change = b_no_change && parent_.buckets_[rand_pos].v1 != defaultv;
                }
            }else{
                b_no_change = false;
            }

            Next();
        }

        Marshal<K>* kmarshal() { return parent_.kmarshal(); }
        Marshal<V1>* v1marshal() { return parent_.v1marshal(); }
        Marshal<V2>* v2marshal() { return parent_.v2marshal(); }
        Marshal<V3>* v3marshal() { return parent_.v3marshal(); }

        void Next() {
          do {
            ++pos;
          } while (pos < parent_.size_ && (parent_.buckets_[pos].v1 == defaultv || !parent_.buckets_[pos].in_use));
        }

        bool done() {
          return pos == parent_.size_;
        }

        const K& key() { return parent_.buckets_[pos].k; }
        V1& value1() { return parent_.buckets_[pos].v1; }
        V2& value2() { return parent_.buckets_[pos].v2; }
        V3& value3() { return parent_.buckets_[pos].v3; }

        int pos;
        StateTable<K, V1, V2, V3> &parent_;
        bool b_no_change;
        V1 defaultv;
  };

  struct ScheduledIterator : public TypedTableIterator<K, V1, V2, V3> {
	ScheduledIterator(StateTable<K, V1, V2, V3>& parent, bool bfilter) : pos(-1), parent_(parent) {

	b_no_change = true;

    	//random number generator
        boost::mt19937 gen(time(0));
        boost::uniform_int<> dist(0, parent_.buckets_.size()-1);
        boost::variate_generator<boost::mt19937&, boost::uniform_int<> > rand_num(gen, dist);

        V1 defaultv = ((Sender<K, V1, V3>*)parent_.info_.sender)->reset();
        
        if(parent_.entries_ <= sample_size){
            //if table size is less than the sample set size, schedule them all
            int i;
            for(i=0; i<parent_.size_; i++){
                if(parent_.buckets_[i].in_use){
                    scheduled_pos.push_back(i);
                    b_no_change = b_no_change && parent_.buckets_[i].v1 != defaultv;
                }
            }
            if(b_no_change && bfilter) return;
            if(!bfilter) b_no_change = false;
        }else{
                //sample random pos, the sample reflect the whole data set more or less
                vector<int> sampled_pos;
                int i;
                int trials = 0;
                for(i=0; i<sample_size; i++){
                    int rand_pos = rand_num();
                    trials++;
                    while(!parent_.buckets_[rand_pos].in_use){
                            rand_pos = rand_num();
                            trials++;
                    }
                    sampled_pos.push_back(rand_pos);

                    b_no_change = b_no_change && parent_.buckets_[rand_pos].v1 == defaultv;
                }

                if(b_no_change && bfilter) return;
                if(!bfilter) b_no_change = false;

                //determine priority
                for(i=0; i<parent_.size_; i++){
                    if(parent_.buckets_[i].v1 == defaultv) continue;
                    parent_.buckets_[i].priority = ((Accumulator<V1>*)parent.info_.accum)->priority(parent_.buckets_[i].v1, parent_.buckets_[i].v2);
                }
                
                //get the cut index, everything larger than the cut will be scheduled
                sort(sampled_pos.begin(), sampled_pos.end(), compare_priority(parent_));
                int cut_index = sample_size*parent_.info_.schedule_portion;
                V1 threshold = parent_.buckets_[sampled_pos[cut_index]].priority;
                //V1 threshold = ((Scheduler<K, V1>*)parent_.info_.scheduler)->priority(parent_.buckets_[sampled_pos[cut_index]].k, parent_.buckets_[sampled_pos[cut_index]].v1);

                VLOG(1) << "cut index " << cut_index << " theshold " << threshold << " pos " << sampled_pos[cut_index] << " max " << parent_.buckets_[sampled_pos[0]].v1;


                if(cut_index==0 || parent_.buckets_[sampled_pos[0]].priority == threshold){
                    //to avoid non eligible records
                    int i;
			for(i=0; i<parent_.size_; i++){
                        if(!parent_.buckets_[i].in_use) continue;
                        if(parent_.buckets_[i].v1 == defaultv) continue;
                        
                        if(parent_.buckets_[i].priority >= threshold){
                            scheduled_pos.push_back(i); 
                        }
                    }
                }else{
                    int i;
                    for(i=0; i<parent_.size_; i++){
                        if(!parent_.buckets_[i].in_use) continue;
                        if(parent_.buckets_[i].v1 == defaultv) continue;
                        
                        if(parent_.buckets_[i].priority > threshold){
                            scheduled_pos.push_back(i); 
                        }
                    }
                }
            }
			//Deepak commented
            //VLOG(1) << "table size " << parent_.buckets_.size() << " workerid " << parent_.id() << " scheduled " << scheduled_pos.size();
            Next();
         }
  
        Marshal<K>* kmarshal() { return parent_.kmarshal(); }
        Marshal<V1>* v1marshal() { return parent_.v1marshal(); }
        Marshal<V2>* v2marshal() { return parent_.v2marshal(); }
        Marshal<V3>* v3marshal() { return parent_.v3marshal(); }

        void Next() {
            ++pos;
        }

        bool done() {
          return pos == scheduled_pos.size();
        }

        const K& key() { return parent_.buckets_[scheduled_pos[pos]].k; }
        V1& value1() { return parent_.buckets_[scheduled_pos[pos]].v1; }
        V2& value2() { return parent_.buckets_[scheduled_pos[pos]].v2; }
        V3& value3() { return parent_.buckets_[scheduled_pos[pos]].v3; }

        class compare_priority {
        public:
            StateTable<K, V1, V2, V3> &parent;
            
            compare_priority(StateTable<K, V1, V2, V3> &inparent): parent(inparent) {}
            
            bool operator()(const int a, const int b) {
              return ((Accumulator<V1>*)parent.info_.accum)->priority(parent.buckets_[a].v1, parent.buckets_[a].v2)
                              > ((Accumulator<V1>*)parent.info_.accum)->priority(parent.buckets_[b].v1, parent.buckets_[b].v2);
            }
        };

        int pos;
        StateTable<K, V1, V2, V3> &parent_;
        double portion;
        vector<int> scheduled_pos;
        bool b_no_change;
   };

   //for termination check
   struct EntirePassIterator : public TypedTableIterator<K, V1, V2, V3>, public LocalTableIterator<K, V2> {
        EntirePassIterator(StateTable<K, V1, V2, V3>& parent) : pos(-1), parent_(parent) {
            Next();
            total = 0;
            defaultv = ((Sender<K, V1, V3>*)parent_.info_.sender)->reset();
        }

        Marshal<K>* kmarshal() { return parent_.kmarshal(); }
        Marshal<V1>* v1marshal() { return parent_.v1marshal(); }
        Marshal<V2>* v2marshal() { return parent_.v2marshal(); }
        Marshal<V3>* v3marshal() { return parent_.v3marshal(); }

        void Next() {
          do {
            ++pos;
          } while (pos < parent_.size_ && !parent_.buckets_[pos].in_use);
          total++;
        }

        bool done() {
            return pos == parent_.size_;
        }

        V1 defaultV(){
            return defaultv;
        }
        
        const K& key() { return parent_.buckets_[pos].k; }
        V1& value1() { return parent_.buckets_[pos].v1; }
        V2& value2() { return parent_.buckets_[pos].v2; }
        V3& value3() { return parent_.buckets_[pos].v3; }

        int pos;
        StateTable<K, V1, V2, V3> &parent_;
        int total;
        V1 defaultv;
    };
   
  struct Factory : public TableFactory {
    TableBase* New() { return new StateTable<K, V1, V2, V3>(); }
  };

  // Construct a StateTable with the given initial size; it will be expanded as necessary.
  StateTable(int size=1);
  ~StateTable() {}

  void Init(const TableDescriptor* td) {
    TableBase::Init(td);
  }

  V1 getF1(const K& k);
  V2 getF2(const K& k);
  V3 getF3(const K& k);
  ClutterRecord<K, V1, V2, V3> get(const K& k);
  bool contains(const K& k);
  void put(const K& k, const V1& v1, const V2& v2, const V3& v3);
  void updateF1(const K& k, const V1& v);
  void updateF2(const K& k, const V2& v);
  void updateF3(const K& k, const V3& v);
  void accumulateF1(const K& k, const V1& v);
  void accumulateAsstFromFPGAF1(const K& k, const V1& v);
  void accumulateAsstToFPGAF1(const K& k, const V1& v);

  void accumulateF2(const K& k, const V2& v);
  void accumulateF3(const K& k, const V3& v);
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

  void reset() {}

  bool compare_priority(int i, int j) {
      return buckets_[i].priority > buckets_[j].priority;
  	//return ((Scheduler<K, V1>*)info_.scheduler)->priority(buckets_[i].k, buckets_[i].v1)
  			//> ((Scheduler<K, V1>*)info_.scheduler)->priority(buckets_[j].k, buckets_[j].v1);
  }

  TableIterator *get_iterator(TableHelper* helper, bool bfilter) {
      if(terminated_) return NULL;              //if get term signal, return null to tell program terminate
      helper->FlushUpdates();
      //boost::this_thread::sleep( boost::posix_time::seconds(0.1) ); //deepak comment
      helper->HandlePutRequest();
      
      Iterator* iter = new Iterator(*this, bfilter);
      int trial = 0;
      while(iter->b_no_change){
          VLOG(1) << "wait for put";
          delete iter;
          helper->FlushUpdates();
          //boost::this_thread::sleep( boost::posix_time::seconds(1) ); //deepak comment
          helper->HandlePutRequest();
              
          if(terminated_) return NULL;              //if get term signal, return null to tell program terminate

          iter = new Iterator(*this, bfilter);

          trial++;
          if(trial >= 10){
              delete iter;
              EntirePassIterator* entireIter = new EntirePassIterator(*this);
              
              total_curr = 0;
              while (!entireIter->done()) {
                entireIter->Next();
                total_curr += entireIter->value2();
              }

              VLOG(1) << "send term check since many times trials " << total_curr << "and perform a pass of the current table";
              helper->SendTermcheck(-1, total_updates, total_curr);
              
              return entireIter;
          }
              
      }
      
      return iter;
  }
  bool sendFPGAAsstUpdates(TableHelper* helper) {
	  helper->startHandlePutRequestFromFPGA();

	  //for(int i=0;i<40;i++) {
	  //helper->HandlePutRequestFromFPGA(); //deepak new
	  //helper->FlushUpdates();
	  //helper->HandlePutRequestToFPGA(); //deepak new


	  //helper->FlushUpdates();
	  //}
  }
  //Deepak - new API to check if termination criterion was met
  bool isTerminated(TableHelper* helper) {

	  if(FPGAThread::Get()->isTermCheckInProgress())
		  return terminated_;

	  //cout<<"Is terminated in FPGA is "<<terminated_<<"\n";
	  if(terminated_) return true;              //if get term signal, return null to tell program terminate

	  //VLOG(0)<<"isTerminated calling sendTermCheck\n";
	  helper->SendTermcheck(-1, total_updates, total_curr);
	  //helper->FlushUpdates(); //flush any updates accumulated in the FPGA assistant
	  //cout<<"Returned after SendTermCheck "<<terminated_<<"\n";
	  return terminated_;

  }
  TableIterator *schedule_iterator(TableHelper* helper, bool bfilter) {
  
//deepak - testing the statetables here
/*
                  EntirePassIterator* entireIter = new EntirePassIterator(*this);

                  int i=0;
                  while (!entireIter->done()) {
                            entireIter->Next();
                            //total_curr += entireIter->value2();
                            VLOG(0)<<"State table key = "<<entireIter->key()<<" value2 = "<<static_cast<double>(entireIter->value2())<<"\n";
                            i++;
                  }
                  VLOG(0)<<"Total state table size is "<<i<<"\n";
*/


      if(terminated_) return NULL;
      helper->FlushUpdates();
      boost::this_thread::sleep( boost::posix_time::seconds(0.1) );
      helper->HandlePutRequest();
      
      ScheduledIterator* iter = new ScheduledIterator(*this, bfilter);
      int trial = 0;
      while(iter->b_no_change){      
          VLOG(1) << "wait for put, send buffered updates";
          delete iter;
          helper->FlushUpdates();
          //boost::this_thread::sleep( boost::posix_time::seconds(1) );
          helper->HandlePutRequest();

          if(terminated_) return NULL;              //if get term signal, return null to tell program terminate

          iter = new ScheduledIterator(*this, bfilter);

          trial++;
          if(trial >= 10){
              delete iter;
              EntirePassIterator* entireIter = new EntirePassIterator(*this);
              
              total_curr = 0;
              while (!entireIter->done()) {
                entireIter->Next();
                total_curr += entireIter->value2();
              }

              VLOG(1) << "send term check since many times trials " << total_curr << "and perform a pass of the current table";
              helper->SendTermcheck(-1, total_updates, total_curr);

              return entireIter;
          }
      }

      return iter;
  }
  
  TableIterator *entirepass_iterator(TableHelper* helper) {
      return new EntirePassIterator(*this);
  }

    
  void serializeToFile(TableCoder *out);
  void serializeToNet(KVPairCoder *out);
  void deserializeFromFile(TableCoder *in, DecodeIteratorBase *itbase);
  void deserializeFromNet(KVPairCoder *in, DecodeIteratorBase *itbase);
  void deserializeFromFPGA(char * buf, int len, DecodeIteratorBase *itbase);
  void serializeToSnapshot(const string& f, int *updates, double *totalF2);
  void convertBigToLittle(char *data, int size);

  Marshal<K>* kmarshal() { return ((Marshal<K>*)info_.key_marshal); }
  Marshal<V1>* v1marshal() { return ((Marshal<V1>*)info_.value1_marshal); }
  Marshal<V2>* v2marshal() { return ((Marshal<V2>*)info_.value2_marshal); }
  Marshal<V3>* v3marshal() { return ((Marshal<V3>*)info_.value3_marshal); }

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
  double total_curr;
  int64_t total_updates;

  std::tr1::hash<K> hashobj_;
  
};

template <class K, class V1, class V2, class V3>
StateTable<K, V1, V2, V3>::StateTable(int size)
  : buckets_(0), entries_(0), size_(0), total_curr(0), total_updates(0) {
  clear();

  VLOG(1) << "new statetable size " << size;
  resize(size);
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::serializeToFile(TableCoder *out) {
  Iterator *i = (Iterator*)get_iterator(NULL, false);
  string k, v1, v2, v3;
  while (!i->done()) {
    k.clear(); v1.clear(); v2.clear(); v3.clear();
    ((Marshal<K>*)info_.key_marshal)->marshal(i->key(), &k);
    ((Marshal<V1>*)info_.value1_marshal)->marshal(i->value1(), &v1);
    ((Marshal<V2>*)info_.value2_marshal)->marshal(i->value2(), &v2);
    ((Marshal<V3>*)info_.value3_marshal)->marshal(i->value3(), &v3);
    out->WriteEntryToFile(k, v1, v2, v3);
    i->Next();
  }
  delete i;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::serializeToNet(KVPairCoder *out) {
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

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::deserializeFromFile(TableCoder *in, DecodeIteratorBase *itbase) {
  FileUpdateDecoder* it = static_cast<FileUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  V2 v2;
  V3 v3;
  string kt, v1t, v2t, v3t;

  it->clear();
  while (in->ReadEntryFromFile(&kt, &v1t, &v2t, &v3t)) {
    ((Marshal<K>*)info_.key_marshal)->unmarshal(kt, &k);
    ((Marshal<V1>*)info_.value1_marshal)->unmarshal(v1t, &v1);
    ((Marshal<V2>*)info_.value2_marshal)->unmarshal(v2t, &v2);
    ((Marshal<V3>*)info_.value3_marshal)->unmarshal(v3t, &v3);
    it->append(k, v1, v2, v3);
  }
  it->rewind();
  return;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::deserializeFromNet(KVPairCoder *in, DecodeIteratorBase *itbase) {
  NetUpdateDecoder* it = static_cast<NetUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  string kt, v1t;

  //deepak - try hacking here to send value to fpga
  FPGAThread *ft;
  ft = FPGAThread::Get();

  it->clear();

  vector<fpgaWord> kvpairs;
  while (in->ReadEntryFromNet(&kt, &v1t)) {
    ((Marshal<K>*)info_.key_marshal)->unmarshal(kt, &k);
    ((Marshal<V1>*)info_.value1_marshal)->unmarshal(v1t, &v1);
    it->append(k, v1);

    //HHHHHACKK
    //also send to fpga
    if(ft->isActive()) {
    	int key = (*(int*)&k);
    	int val = (*(int*)&v1);
    	//kvpairs.add()
    	if(bucket_for_key(k)!=-1 && val!=0) {
    		//if(bucket_for_key(k)!=-1 && val>MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE) {
    		kvpairs.push_back(fpgaWord(key,val));
    	}
    }

  }

  /*
  if(ft->isActive()) {
	  cout <<"ID "<<ft->getTid()<<" Here I am active\n";
  }
  else {
	  cout <<"ID "<<ft->getTid()<<" Here I am NOT active\n";
  }
  */

  //how do we check if the keys are indeed correct (ie. odd keys goto 1 and even keys goto 0 ?)

  if(ft->isActive()) {
		  if((!ft->isTerminated())&&(kvpairs.size()>0)) {
			  //if(v1>MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE) {
				  //cout<<" Sending "<<kvpairs.size()<<" keys to the FPGA\n";
				  //deepak - to debug, disable sending to fpga for now
				  ft->FPGAloadDram(kvpairs,WORKER_TO_FPGA_PUT_REQUEST);
			  //}
		  }
		  else {
			 //cout<<" Either ft is terminated or kvpair size is 0\n";

		  }
		  kvpairs.clear();
  } else {

	  //cout<<" ft thread not active \n";
  }

  it->rewind();
  return;
}

//Performs an in-place  big to little endian conversion of 4 bytes chars
template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::convertBigToLittle(char *data, int size)
{

	for(int i=0;i<size/2;i++) {
		char c = *(data+i);
		*(data+i)=*(data+(size-1-i));
		*(data+(size-1-i))=c;
	}
	//int num = *((unsigned int*)data);
	//assuming int size is 4 bytes
	//num = ( (num & 0xff000000)>>24 | (num & 0x00ff0000>>8) | (num & 0x0000ff00<<8) | (num & 0x000000ff<<24) );
}

//Deepak - decode FPGA buffer
template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::deserializeFromFPGA(char *buf, int len, DecodeIteratorBase *itbase) {
  NetUpdateDecoder* it = static_cast<NetUpdateDecoder*>(itbase);
  K k;
  V1 v1;
  string  kt,v1t;
  int i=0;

  char *buf_it = buf;
  //skip the first 2 bytes
  //buf_it+=2;
  //len-=2;

  //VLOG(0) << " deserialize FPGA len is "<<len <<"\n";
  it->clear();

  //reverse bytes in the stream
  //skip little to big endian, do this conversion in FPGA instead

  for(char *t=buf;t<buf+len;t+=sizeof(int)) {
	  convertBigToLittle(t,sizeof(int));
  }



  int *t=(int*)buf;
  while (((char*)t)<buf+len) {

	string kt =  boost::lexical_cast<string>( *((int*)t) );
	k = static_cast<K>(*((int*)t));
	t++;
	//string vlt = boost::lexical_cast<string>( *((int*)t) );
	//v1 = static_cast<V1>(*((int*)t));
	string vlt = boost::lexical_cast<string>( *((V1*)t) );
	v1 = static_cast<V1>(*((V1*)t));
	t++;
	//cout << " The key is "<<kt<<"value here is "<<vlt<<"\n";

	//((Marshal<K>*)info_.key_marshal)->unmarshalFPGA(kt, &k);
    //((Marshal<V1>*)info_.value1_marshal)->unmarshalFPGA(v1t, &v1);
    //VLOG(0) << " Marhsalled key is "<<k<<"Marshalled value here is "<<v1<<"\n";

    //const StringPiece& s, T *t

    //v1 = reinterpret_cast<V1>(*((unsigned int*)t));
	//v1 = (V1)vlt;

    it->append(k, v1);

  }
  it->rewind();

  free(buf); //buffer created in fpga.h by the recieve thread (must be called to avoid memory leaks)
  return;
}

//it can also be used to generate snapshot, but currently in order to measure the performance we skip this step, 
//but focus on termination check
template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::serializeToSnapshot(const string& f, int* updates, double* totalF2) {
  total_curr = 0;
  EntirePassIterator* entireIter = new EntirePassIterator(*this);
  total_curr = static_cast<double>(((TermChecker<K, V2>*)info_.termchecker)->local_report(entireIter));
  delete entireIter;
  *updates = total_updates;
  *totalF2 = total_curr;
}


template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::resize(int64_t size) {
  CHECK_GT(size, 0);
  if (size_ == size)
    return;

  std::vector<Bucket> old_b = buckets_;
  int old_entries = entries_;

  //LOG(INFO) << "Rehashing... " << entries_ << " : " << size_ << " -> " << size;

  buckets_.resize(size);
  size_ = size;
  clear();

  for (int i = 0; i < old_b.size(); ++i) {
    if (old_b[i].in_use) {
      put(old_b[i].k, old_b[i].v1, old_b[i].v2, old_b[i].v3);
    }
  }

  CHECK_EQ(old_entries, entries_);
}

template <class K, class V1, class V2, class V3>
bool StateTable<K, V1, V2, V3>::contains(const K& k) {
  return bucket_for_key(k) != -1;
}

template <class K, class V1, class V2, class V3>
V1 StateTable<K, V1, V2, V3>::getF1(const K& k) {
  int b = bucket_for_key(k);
  //The following key display is a hack hack hack and only yields valid
  //results for ints.  It will display nonsense for other types.
  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

  return buckets_[b].v1;
}

template <class K, class V1, class V2, class V3>
V2 StateTable<K, V1, V2, V3>::getF2(const K& k) {
  int b = bucket_for_key(k);
  //The following key display is a hack hack hack and only yields valid
  //results for ints.  It will display nonsense for other types.
  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

  return buckets_[b].v2;
}

template <class K, class V1, class V2, class V3>
V3 StateTable<K, V1, V2, V3>::getF3(const K& k) {
  int b = bucket_for_key(k);
  //The following key display is a hack hack hack and only yields valid
  //results for ints.  It will display nonsense for other types.
  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

  return buckets_[b].v3;
}

template <class K, class V1, class V2, class V3>
ClutterRecord<K, V1, V2, V3> StateTable<K, V1, V2, V3>::get(const K& k) {
  int b = bucket_for_key(k);
  //The following key display is a hack hack hack and only yields valid
  //results for ints.  It will display nonsense for other types.
  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

  return ClutterRecord<K, V1, V2, V3>(k, buckets_[b].v1, buckets_[b].v2, buckets_[b].v3);
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::updateF1(const K& k, const V1& v) {
    int b = bucket_for_key(k);

    CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

    buckets_[b].v1 = v;
    total_updates++;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::updateF2(const K& k, const V2& v) {
    int b = bucket_for_key(k);

    CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

    buckets_[b].v2 = v;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::updateF3(const K& k, const V3& v) {
    int b = bucket_for_key(k);

    CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";

    buckets_[b].v3 = v;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::accumulateF1(const K& k, const V1& v) {
  int b = bucket_for_key(k);

  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";
  ((Accumulator<V1>*)info_.accum)->accumulate(&buckets_[b].v1, v);
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::accumulateAsstFromFPGAF1(const K& k, const V1& v) {
  return;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::accumulateAsstToFPGAF1(const K& k, const V1& v) {

	int key = *((int*)&k);
	int val = *((int*)&v);

	cout<<"Key in st is "<<key<<" val is "<<hex<<val<<"\n";
	FPGAThread *ft;
	ft = FPGAThread::Get();
	//deepak - avoid sending miniscule values to the FPGA
	/*
	if(v>MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE) {
		  ft->FPGASendKVPair((*(int*)&k),(*(int*)&v));
	}
	*/

	return;
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::accumulateF2(const K& k, const V2& v) {
  int b = bucket_for_key(k);

  CHECK_NE(b, -1) << "No entry for requested key <" << *((int*)&k) << ">";
  ((Accumulator<V1>*)info_.accum)->accumulate(&buckets_[b].v2, v);
}

template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::accumulateF3(const K& k, const V3& v) {

}


template <class K, class V1, class V2, class V3>
void StateTable<K, V1, V2, V3>::put(const K& k, const V1& v1, const V2& v2, const V3& v3) {
  int start = bucket_idx(k);
  int b = start;
  bool found = false;

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
    if (entries_ > size_ /** kLoadFactor*/) {     //doesn't consider loadfactor, the tablesize is pre-defined 
        LOG(INFO) << "resizing... " << size_ << " : " << (int)(1 + size_ * 2) << " entries "<< entries_;
        resize((int)(1 + size_ * 2));
        put(k, v1, v2, v3);
    } else {
      buckets_[b].in_use = 1;
      buckets_[b].k = k;
      buckets_[b].v1 = v1;
      buckets_[b].v2 = v2;
      buckets_[b].v3 = v3;
      
      buckets_[b].priority = ((Accumulator<V1>*)info_.accum)->priority(v1, v2);
      ++entries_;
    }
  } else {
    // Replacing an existing entry
    buckets_[b].v1 = v1;
    buckets_[b].v2 = v2;
    buckets_[b].v3 = v3;
    buckets_[b].priority = ((Accumulator<V1>*)info_.accum)->priority(v1, v2);
  }
}

}
#endif /* SPARSE_MAP_H_ */
