#ifndef KERNELREGISTRY_H_
#define KERNELREGISTRY_H_

#include "kernel/table.h"
#include "kernel/global-table.h"
#include "kernel/local-table.h"
#include "kernel/table-registry.h"

#include "util/common.h"
#include <boost/function.hpp>
#include <boost/lexical_cast.hpp>
#include "util/fpga.h"
//#include "client/client.h"
#include <boost/thread.hpp>

namespace dsm {

template <class K, class V1, class V2, class V3>
class TypedGlobalTable;

class TableBase;
class Worker;

template <class K, class V, class D>
class MaiterKernel;

#ifndef SWIG
class MarshalledMap {
public:
  struct MarshalledValue {
    virtual string ToString() const = 0;
    virtual void FromString(const string& s) = 0;
    virtual void set(const void* nv) = 0;
    virtual void* get() const = 0;
  };

  template <class T>
  struct MarshalledValueT  : public MarshalledValue {
    MarshalledValueT() : v(new T) {}
    ~MarshalledValueT() { delete v; }

    string ToString() const {
      string tmp;
      m_.marshal(*v, &tmp);
      return tmp;
    }

    void FromString(const string& s) {
      m_.unmarshal(s, v);
    }

    void* get() const { return v; }
    void set(const void *nv) {
      *v = *(T*)nv;
    }

    mutable Marshal<T> m_;
    T *v;
  };

  template <class T>
  void put(const string& k, const T& v) {
    if (serialized_.find(k) != serialized_.end()) {
      serialized_.erase(serialized_.find(k));
    }

    if (p_.find(k) == p_.end()) {
      p_[k] = new MarshalledValueT<T>;
    }

    p_[k]->set(&v);
  }

  template <class T>
  T& get(const string& k) const {
    if (serialized_.find(k) != serialized_.end()) {
      p_[k] = new MarshalledValueT<T>;
      p_[k]->FromString(serialized_[k]);
      serialized_.erase(serialized_.find(k));
    }

    return *(T*)p_.find(k)->second->get();
  }

  bool contains(const string& key) const {
    return p_.find(key) != p_.end() ||
           serialized_.find(key) != serialized_.end();
  }

  Args* ToMessage() const {
    Args* out = new Args;
    for (unordered_map<string, MarshalledValue*>::const_iterator i = p_.begin(); i != p_.end(); ++i) {
      Arg *p = out->add_param();
      p->set_key(i->first);
      p->set_value(i->second->ToString());
    }
    return out;
  }

  // We can't immediately deserialize the parameters passed in, since sadly we don't
  // know the type yet.  Instead, save the string values on the side, and de-serialize
  // on request.
  void FromMessage(const Args& p) {
    for (int i = 0; i < p.param_size(); ++i) {
      serialized_[p.param(i).key()] = p.param(i).value();
    }
  }

private:
  mutable unordered_map<string, MarshalledValue*> p_;
  mutable unordered_map<string, string> serialized_;
};
#endif


class DSMKernel {
public:
  // Called upon creation of this kernel by a worker.
  virtual void InitKernel() {}

  // The table and shard being processed.
  int current_shard() const { return shard_; }
  int current_table() const { return table_id_; }

  template <class T>
  T& get_arg(const string& key) const {
    return args_.get<T>(key);
  }

  template <class T>
  T& get_cp_var(const string& key, T defval=T()) {
    if (!cp_.contains(key)) {
      cp_.put(key, defval);
    }
    return cp_.get<T>(key);
  }

  GlobalTable* get_table(int id);

  template <class K, class V1, class V2, class V3>
  TypedGlobalTable<K, V1, V2, V3>* get_table(int id) {
    return dynamic_cast<TypedGlobalTable<K, V1, V2, V3>*>(get_table(id));
  }
  
  template <class K, class V, class D>
  void set_maiter(MaiterKernel<K, V, D> maiter){}
  
private:
  friend class Worker;
  friend class Master;

  void initialize_internal(Worker* w,
                           int table_id, int shard);

  void set_args(const MarshalledMap& args);
  void set_checkpoint(const MarshalledMap& args);

  Worker *w_;
  int shard_;
  int table_id_;
  MarshalledMap args_;
  MarshalledMap cp_;
};

struct KernelInfo {
  KernelInfo(const char* name) : name_(name) {}

  virtual DSMKernel* create() = 0;
  virtual void Run(DSMKernel* obj, const string& method_name) = 0;
  virtual bool has_method(const string& method_name) = 0;

  string name_;
};

template <class C, class K, class V, class D>
struct KernelInfoT : public KernelInfo {
  typedef void (C::*Method)();
  map<string, Method> methods_;
  MaiterKernel<K, V, D>* maiter;

  KernelInfoT(const char* name, MaiterKernel<K, V, D>* inmaiter) : KernelInfo(name) {
      maiter = inmaiter;
  }

  DSMKernel* create() { return new C; }

  void Run(DSMKernel* obj, const string& method_id) {
    ((C*)obj)->set_maiter(maiter);
    boost::function<void (C*)> m(methods_[method_id]);
    m((C*)obj);
  }

  bool has_method(const string& name) {
    return methods_.find(name) != methods_.end();
  }

  void register_method(const char* mname, Method m, MaiterKernel<K, V, D>* inmaiter) { 
      methods_[mname] = m; 
  }
};

class ConfigData;
class KernelRegistry {
public:
  typedef map<string, KernelInfo*> Map;
  Map& kernels() { return m_; }
  KernelInfo* kernel(const string& name) { return m_[name]; }

  static KernelRegistry* Get();
private:
  KernelRegistry() {}
  Map m_;
};

template <class C, class K, class V, class D>
struct KernelRegistrationHelper {
  KernelRegistrationHelper(const char* name, MaiterKernel<K, V, D>* maiter) {
    KernelRegistry::Map& kreg = KernelRegistry::Get()->kernels();

    CHECK(kreg.find(name) == kreg.end());
    kreg.insert(make_pair(name, new KernelInfoT<C, K, V, D>(name, maiter)));
  }
};


template <class C, class K, class V, class D>
struct MethodRegistrationHelper {
  MethodRegistrationHelper(const char* klass, const char* mname, void (C::*m)(), MaiterKernel<K, V, D>* maiter) {
    ((KernelInfoT<C, K, V, D>*)KernelRegistry::Get()->kernel(klass))->register_method(mname, m, maiter);
  }
};

template <class K, class V, class D>
class MaiterKernel1 : public DSMKernel {
private:
    MaiterKernel<K, V, D>* maiter;
public:
    void set_maiter(MaiterKernel<K, V, D>* inmaiter) {
        maiter = inmaiter;
    }
    
    void init_table(TypedGlobalTable<K, V, V, D>* a){
        cout << "Reached here\n";
    	if(!a->initialized()){
            a->InitStateTable();
        }
        a->resize(maiter->num_nodes);
        maiter->initializer->initTable(a, current_shard(),maiter->num_nodes,maiter->keys,maiter->ptrdata);
    }

    void run() {
        VLOG(0) << "initializing table ";
        init_table(maiter->table);
    }
};

template <class K, class V, class D>
class MaiterKernel2 : public DSMKernel {
private:
    MaiterKernel<K, V, D>* maiter;
    vector<pair<K, V> >* output;
    int threshold;

public:
    void set_maiter(MaiterKernel<K, V, D>* inmaiter) {
        maiter = inmaiter;
    }
        
    void run_iter(const K& k, V &v1, V &v2, D &v3) {
        maiter->table->accumulateF2(k, v1);

        maiter->sender->send(v1, v3, output);
        if(output->size() > threshold){
            typename vector<pair<K, V> >::iterator iter;
            for(iter = output->begin(); iter != output->end(); iter++) {
                pair<K, V> kvpair = *iter;
                maiter->table->accumulateF1(kvpair.first, kvpair.second);
            }
            output->clear();
        }

        maiter->table->updateF1(k, maiter->sender->reset());
    }

    void run_loop(TypedGlobalTable<K, V, V, D>* a) {
        Timer timer;
        double totalF1 = 0;
        int updates = 0;
        output = new vector<pair<K, V> >;
        //threshold = 1000; //Deepak set threshold to 1
        threshold = 10000;

        if(maiter->table->checkNodeType(current_shard())) { //If the node is an FPGA
			VLOG(0) << "Shard "<<current_shard()<<" is an FPGA\n";
			FPGAThread* ft=FPGAThread::Get();

			//Temporarily comment for testing pagerank
			VLOG(0) << "Send START_UPDATE to FPGA\n";
			cout<<"Send START_UPDATE to FPGA\n";
			ft->Get()->resetTerminated();

			//stop any previous runs
			//ft->FPGAsendMessage(END_UPDATE);

			a->send_fpga_asst_updates(current_shard());

			ft->FPGAsendMessage(START_UPDATE); //Deepak - disable updates for now

			while(true) {
				/*

				//boost::this_thread::sleep( boost::posix_time::seconds(1) ); //deepak - increased sleep to 10seconds to makesure FPGA is not checkterminate interrupted frequently

				cout<<"FPGA checking for termination now\n";
				//check_for_termination sends a TERMCHECK SIGNAL to the FPGA node

				*/
				if(a->check_for_termination(current_shard())) {
					cout <<"Termination detected\n";
					break;
				}


				//typename TypedGlobalTable<K, V, V, D>::Iterator *it = a->get_typed_iterator(current_shard(), false);
				//if(it == NULL) break;
				if(ft->isTerminated())
					break;
				else
					boost::this_thread::sleep(boost::posix_time::milliseconds(FPGA_TERMCHECK_SLEEP_INTERVAL_MILLISECONDS));
					//usleep(50000); //0.05 seconds
					//boost::this_thread::sleep( boost::posix_time::seconds(0.5));

			}
			return;
		}
		else {
			cout<< "[Shard "<<current_shard()<<"] The node is a CPU node\n";
        //the main loop for iterative update
        while(true){
            //set false, no inteligient stop scheme, which can check whether there are changes in statetable
            typename TypedGlobalTable<K, V, V, D>::Iterator *it = a->get_typed_iterator(current_shard(), false);
            if(it == NULL) break;

            for (; !it->done(); it->Next()) {
                totalF1+=it->value1();
                updates++;

                //VLOG(1)<<"Key is "<< it->key()<<" Value 1 is "<<it->value1()<<" Value 2 is "<<it->value2();

                run_iter(it->key(), it->value1(), it->value2(), it->value3());
            }
            delete it;

            //send out buffer
            typename vector<pair<K, V> >::iterator iter;
            for(iter = output->begin(); iter != output->end(); iter++) {
                pair<K, V> kvpair = *iter;
                maiter->table->accumulateF1(kvpair.first, kvpair.second);
            }
            output->clear();
            
				//sleep(3);
				//for expr
				cout << timer.elapsed() << "\t" << current_shard() << "\t" << totalF1 << "\t" << updates << endl;
			}
        }
    }

    void map() {
        VLOG(0) << "start performing iterative update";
        run_loop(maiter->table);
    }
};

template <class K, class V, class D>
class MaiterKernel3 : public DSMKernel {
private:
    MaiterKernel<K, V, D>* maiter;
public:
    void set_maiter(MaiterKernel<K, V, D>* inmaiter) {
        maiter = inmaiter;
    }
        
    void dump(TypedGlobalTable<K, V, V, D>* a){
        double totalF1 = 0;
        double totalF2 = 0;
        fstream File;

        if(a->checkNodeType(current_shard())) {
        	FPGAThread *ft = FPGAThread::Get();
        	//Request FPGA to flush table
        	//Before flushing stop the update process
        	if(ft->isActive()) {
        		VLOG(0) <<"FPGA Thread is active\n";
        		//ft->FPGAsendMessage(END_UPDATE);

        	   	VLOG(0) << "Send START_FLUSH_DATA to FPGA\n";
        	   	//dsiable flush to stop system from crashing
        	   	//boost::this_thread::sleep( boost::posix_time::seconds(1) );
        	   	/*
        	   	ft->FPGAsendMessage(START_FLUSH_DATA);

        	   	if(FPGAThread::Get()->isActive())
        	   		VLOG(0)<<" packet count is "<<FPGAThread::Get()->getPacketCount()<<" and timespent = "<<FPGAThread::Get()->getTimeSpent()<<"\n";

        	   	//VLOG(0)<<"keys flushed from FPGA = "<<a->checkKeysFlushedFromFPGA(current_shard())<<" total keys in table = "<<a->getNumKeysInTable()<<"\n";
        	   	//while(a->checkKeysFlushedFromFPGA(current_shard())<a->getNumKeysInTable()) {

        	   	while(ft->getKeysReturnedFromFPGA()<ft->getNumKeysInFPGA()) {

        	   		boost::this_thread::sleep( boost::posix_time::seconds(0.1) );
        		//VLOG(0)<<" shard "<<current_shard()<<" curr value is "<<a->checkKeysFlushedFromFPGA(current_shard());
        	   	};
        	   	*/


        	   //VLOG(0)<<"keys flushed from FPGA = "<<a->checkKeysFlushedFromFPGA(current_shard())<<" total keys in table = "<<a->getNumKeysInTable()<<"\n";
        	   	VLOG(0)<<"keys flushed from FPGA = "<<ft->getKeysReturnedFromFPGA()<<" total keys in table = "<<ft->getNumKeysInFPGA()<<"\n";
        	}

        }

        //VLOG(0) << "Waiting for FPGA to deliver data..\n";
        //wait here until FPGA dumps all the data

        //dump the data received from FPGA into a file

        VLOG(0)<<"Opening the file to write data\n";
        string file = StringPrintf("%s/part-%d", maiter->output.c_str(), current_shard());
        File.open(file.c_str(), ios::out);

        /*new implementation*/
        /*
        typename TypedGlobalTable<K, V, V, D>::Iterator *it = a->get_entirepass_iterator(current_shard());
        for (; !it->done(); it->Next()) {
                totalF1 += it->value1();
                totalF2 += it->value2();

                //VLOG(0) << it->key() << "\t" << it->value1() << "|" << it->value2() << "\n";
                File << it->key() << "\t" << it->value1() << "|" << it->value2() << "\n";
        }
        */
	

	//Old implementation commented

       typename TypedGlobalTable<K, V, V, D>::Iterator *it = a->get_typed_iterator(current_shard(), true);
        for (int i = current_shard(); i < maiter->num_nodes; i += maiter->conf.num_workers()) {
                totalF1 += maiter->table->getF1(i);
                totalF2 += maiter->table->getF2(i);

                File << i << "\t" << maiter->table->getF1(i) << "|" << maiter->table->getF2(i) << "\n";
        };


        delete it;
        File.close();

        cout << "total F1 : " << totalF1 << endl;
        cout << "total F2 : " << totalF2 << endl;
        VLOG(0)<<"Dump finished\n";

    }

    void run() {
        VLOG(0) << "dumping result";
        dump(maiter->table);
    }
};


template <class K, class V, class D>
class MaiterKernel{
    
public:
        
    int64_t num_nodes;
    double schedule_portion;
    ConfigData conf;
    string output;
    Sharder<K> *sharder;
    Initializer<K, V, D> *initializer;
    Accumulator<V> *accum;
    Sender<K, V, D> *sender;
    TermChecker<K, V> *termchecker;
    bool isNodeFPGA; //Deepak

    vector<fpgaWord> keys; //all records associated with keys
    vector<fpgaWord> ptrdata; //all records associated with ptrdata
    vector<workerAddress> workerAddresses;//support max 20 workers

	//The Maiter Kernel table - This is the global table
    TypedGlobalTable<K, V, V, D> *table;

    
    MaiterKernel() { Reset(); }

    MaiterKernel(ConfigData& inconf, int64_t nodes, double portion, string outdir,
                    Sharder<K>* insharder,
                    Initializer<K, V, D>* ininitializer,
                    Accumulator<V>* inaccumulator,
                    Sender<K, V, D>* insender,
                    TermChecker<K, V>* intermchecker) {
        Reset();
        
        conf = inconf;
        num_nodes = nodes;
        schedule_portion = portion;
        output = outdir;
        sharder = insharder;
        initializer = ininitializer;
        accum = inaccumulator;
        sender = insender;
        termchecker = intermchecker;
    }
    
    ~MaiterKernel(){}


    void Reset() {
        num_nodes = 0;
        schedule_portion = 1;
        output = "result";
        sharder = NULL;
        initializer = NULL;
        accum = NULL;
        sender = NULL;
        termchecker = NULL;
    }

	//Deepak uncommented to check
    void setNodeType(bool isFPGA)
    {
    	isNodeFPGA = isFPGA;
    }

public:
    int registerMaiter() {
	VLOG(0) << "shards " << conf.num_workers();
	table = CreateTable<K, V, V, D >(0, conf.num_workers(), schedule_portion,
                                        sharder, initializer, accum, sender, termchecker);

	VLOG(0) << "create table succeeded\n ";
		//There are 3 kernels for each job - run (loading phase), map (iteration phase), run (termination and collecting results)
		//These kernels are kept track in the kernel registry data structure (class KernelRegistry in this file)
        //initialize table job
        KernelRegistrationHelper<MaiterKernel1<K, V, D>, K, V, D>("MaiterKernel1", this);
        MethodRegistrationHelper<MaiterKernel1<K, V, D>, K, V, D>("MaiterKernel1", "run", &MaiterKernel1<K, V, D>::run, this);
        VLOG(0) << "kernel1 registered\n ";

        //iterative update job
        if(accum != NULL && sender != NULL){
            KernelRegistrationHelper<MaiterKernel2<K, V, D>, K, V, D>("MaiterKernel2", this);
            MethodRegistrationHelper<MaiterKernel2<K, V, D>, K, V, D>("MaiterKernel2", "map", &MaiterKernel2<K, V, D>::map, this);
        }
        VLOG(0) << "kernel2 registered\n ";

        //dumping result to disk job
        if(termchecker != NULL){
            KernelRegistrationHelper<MaiterKernel3<K, V, D>, K, V, D>("MaiterKernel3", this);
            MethodRegistrationHelper<MaiterKernel3<K, V, D>, K, V, D>("MaiterKernel3", "run", &MaiterKernel3<K, V, D>::run, this);
        }
        VLOG(0) << "kernel3 registered\n ";


     
	return 0;
    }
};


class RunnerRegistry {
public:
  typedef int (*KernelRunner)(ConfigData&);
  typedef map<string, KernelRunner> Map;

  KernelRunner runner(const string& name) { return m_[name]; }
  Map& runners() { return m_; }

  static RunnerRegistry* Get();
private:
  RunnerRegistry() {}
  Map m_;
};

struct RunnerRegistrationHelper {
  RunnerRegistrationHelper(RunnerRegistry::KernelRunner k, const char* name) {
    RunnerRegistry::Get()->runners().insert(make_pair(name, k));
  }
};

#define REGISTER_KERNEL(klass)\
  static KernelRegistrationHelper<klass> k_helper_ ## klass(#klass);

#define REGISTER_METHOD(klass, method)\
  static MethodRegistrationHelper<klass> m_helper_ ## klass ## _ ## method(#klass, #method, &klass::method);

#define REGISTER_RUNNER(r)\
  static RunnerRegistrationHelper r_helper_ ## r ## _(&r, #r);

}
#endif /* KERNELREGISTRY_H_ */
