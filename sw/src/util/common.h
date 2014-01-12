#ifndef COMMON_H_
#define COMMON_H_

#include <time.h>
#include <vector>
#include <string>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "glog/logging.h"
#include "google/gflags.h"
#include <google/protobuf/message.h>

#include "util/hash.h"
#include "util/static-initializers.h"
#include "util/stringpiece.h"
#include "util/timer.h"

#include <tr1/unordered_map>
#include <tr1/unordered_set>

#include <boost/type_traits.hpp>
#include <boost/utility/enable_if.hpp>

#define MAX_WORKER_NODES 								100
#define FPGA_DRAM_START_ADDRESS 						0x00000000 		//Base address of DRAM connected to FPGA
#define FPGA_DRAM_DRAM_INCREMENT_BYTES 					4 				//Increment DRAM address by this unit (in bytes)
#define FPGA_RECORD_SIZE_IN_WORDS 						8
#define NUM_BYTES_IN_WORDS 								4
#define DRAM_DUMMY_LINK_FILL 							0xFFFFFFFF
#define FPGA_DRAM_SIZE_IN_WORDS 						1024*1024*1024
#define MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE 			0.00001 		//val sent to other workers only if > the min threshold - reduces external communication
#define FPGA_TERMCHECK_SLEEP_INTERVAL_MILLISECONDS 		1000 			// (interval to check for Termination in FPGA - unit in seconds)
//#define FPGA_TERMCHECK_SLEEP_INTERVAL_MILLISECONDS 		1000 			// (interval to check for Termination in FPGA - unit in miseconds)
#define FPGA_INTERVAL_BETWEEN_LOAD_PACKET_MILLISECOND	1000
#define MILLISECONDS_AFTER_LOAD							20000

using std::map;
using std::vector;
using std::string;
using std::pair;
using std::make_pair;
using std::tr1::unordered_map;
using std::tr1::unordered_set;

namespace dsm {

void Init(int argc, char** argv);

uint64_t get_memory_rss();
uint64_t get_memory_total();

void Sleep(double t);
void DumpProfile();

double get_processor_frequency();

typedef enum worker_type {
    	FPGA=0,
    	CPU=1
}wtype;

//ds to store ip address and ids of all workers with attached fpgas
class workerAddress {
public:
		int shard_id;
    	wtype type;
    	string ip_address;
    	string ethInterface;
public:
    	workerAddress();

    	workerAddress(int id, wtype type, string ip, string eth) {
    		shard_id = id;
    		type = type;
    		ip_address = ip;
    		ethInterface = eth;
    	}

};


class fpgaWord {
public:
	int addr;
	int val;
public:
	fpgaWord();

	fpgaWord(int a, int v) {
		addr=a;
		val=v;
	}
};

//Deepak - a struct to store the details of FPGAs attached to each node
typedef struct {
	bool isNodeFPGA;
	string fpga_ip_address;
	int numKeysFlushedFromFPGA; //keep track how many flush updates we recieved from FPGA so far (to decide termination)
}fpga_info_t;

// Log-bucketed histogram.
class Histogram {
public:
  Histogram() : count(0) {}

  void add(double val);
  string summary();

  int bucketForVal(double v);
  double valForBucket(int b);

  int getCount() { return count; }
private:

  int count;
  vector<int> buckets;
  static const double kMinVal;
  static const double kLogBase;
};

class SpinLock {
public:
  SpinLock() : d(0) {}
  void lock() volatile;
  void unlock() volatile;
private:
  volatile int d;
};

static double rand_double() {
  return double(random()) / RAND_MAX;
}

// Simple wrapper around a string->double map.
struct Stats {
  double& operator[](const string& key) {
    return p_[key];
  }

  string ToString(string prefix) {
    string out;
    for (unordered_map<string, double>::iterator i = p_.begin(); i != p_.end(); ++i) {
      out += StringPrintf("%s -- %s : %.2f\n", prefix.c_str(), i->first.c_str(), i->second);
    }
    return out;
  }

  void Merge(Stats &other) {
    for (unordered_map<string, double>::iterator i = other.p_.begin(); i != other.p_.end(); ++i) {
      p_[i->first] += i->second;
    }
  }
private:
  unordered_map<string, double> p_;
};

struct MarshalBase {};

template <class T, class Enable = void>
struct Marshal : public MarshalBase {
  virtual void marshal(const T& t, string* out) {
    //GOOGLE_GLOG_COMPILE_ASSERT(std::tr1::is_pod<T>::value, Invalid_Value_Type);
    out->assign(reinterpret_cast<const char*>(&t), sizeof(t));
  }

  virtual void unmarshal(const StringPiece& s, T *t) {
    //GOOGLE_GLOG_COMPILE_ASSERT(std::tr1::is_pod<T>::value, Invalid_Value_Type);
    *t = *reinterpret_cast<const T*>(s.data);
  }

  //Deepak virtual functions
  virtual void marshalFPGA(const T& t, string* out) {
      //GOOGLE_GLOG_COMPILE_ASSERT(std::tr1::is_pod<T>::value, Invalid_Value_Type);
      out->assign(reinterpret_cast<const char*>(&t), sizeof(t));
  }

  virtual void unmarshalFPGA(const StringPiece& s, T *t) {
      //GOOGLE_GLOG_COMPILE_ASSERT(std::tr1::is_pod<T>::value, Invalid_Value_Type);
      *t = *reinterpret_cast<const T*>(s.data);
  }
};

template <class T>
struct Marshal<T, typename boost::enable_if<boost::is_base_of<string, T> >::type> : public MarshalBase {
  void marshal(const string& t, string *out) { *out = t; }
  void unmarshal(const StringPiece& s, string *t) { t->assign(s.data, s.len); }
};

template <class T>
struct Marshal<T, typename boost::enable_if<boost::is_base_of<google::protobuf::Message, T> >::type> : public MarshalBase {
  void marshal(const google::protobuf::Message& t, string *out) { t.SerializePartialToString(out); }
  void unmarshal(const StringPiece& s, google::protobuf::Message* t) { t->ParseFromArray(s.data, s.len); }
};

template <class T>
string marshal(Marshal<T>* m, const T& t) { string out; m->marshal(t, &out); return out; }

template <class T>
T unmarshal(Marshal<T>* m, const StringPiece& s) { T out; m->unmarshal(s, &out); return out; }

//Add custom FPGA unmarshalling code here
template <class T>
string marshalFPGA(Marshal<T>* m, const T& t) { string out; m->marshal(t, &out); return out; }

template <class T>
T unmarshalFPGA(Marshal<T>* m, const StringPiece& s) { T out; m->unmarshal(s, &out); return out; }

static vector<int> range(int from, int to, int step=1) {
  vector<int> out;
  for (int i = from; i < to; ++i) {
    out.push_back(i);
  }
  return out;
}

static vector<int> range(int to) {
  return range(0, to);
}
}

#define IN(container, item) (std::find(container.begin(), container.end(), item) != container.end())
#define COMPILE_ASSERT(x) extern int __dummy[(int)x]

#include "util/tuple.h"

#ifndef SWIG
// operator<< overload to allow protocol buffers to be output from the logging methods.
#include <google/protobuf/message.h>
namespace std{
static ostream & operator<< (ostream &out, const google::protobuf::Message &q) {
  string s = q.ShortDebugString();
  out << s;
  return out;
}

//Moved this struct from util/client.h to here
struct Link{
  Link(int inend, float inweight, int nLinks) : end(inend), weight(inweight), numSelfLinks(nLinks) {}
  int end;
  float weight;
  int numSelfLinks;
};

}
#endif

#endif /* COMMON_H_ */
