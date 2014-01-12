#include "client/client.h"
#include "util/common.h"
#include <boost/algorithm/string.hpp>

DECLARE_string(nodetype_file); //Deepak

#define DAMP_FACTOR 0.8

using namespace dsm;

DECLARE_string(graph_dir);
DECLARE_string(result_dir);
DECLARE_int64(num_nodes);
DECLARE_double(portion);

static bool isNodeFPGA=false;
static vector<workerAddress> waddress;
static vector<fpgaWord> sdata;//all records associated with static data
static int num_workers;
static long num_dram_words;

//Deepak comment
/*
static vector<int> readUnWeightLinks(string links){
    vector<int> linkvec;
    int spacepos = 0;
    while((spacepos = links.find_first_of(" ")) != links.npos){
        int to;
        if(spacepos > 0){
            to = boost::lexical_cast<int>(links.substr(0, spacepos));
        }
        links = links.substr(spacepos+1);
        linkvec.push_back(to);
    }

    return linkvec;
}
*/

static vector<Link> readUnWeightLinks(string links, int num_nodes, int shard_id, int *numSelfLinks){
    vector<Link> linkvec;
    int spacepos = 0;
    int selfLinks = 0;


    while((spacepos = links.find_first_of(" ")) != links.npos){
    	Link to(0, 0, 0);

        //int to;
        if(spacepos > 0){
            //to = boost::lexical_cast<int>(links.substr(0, spacepos));
        	to.end = boost::lexical_cast<int>(links.substr(0, spacepos));
        	to.weight = 0;
        	//calculate number of self links
        	if(to.end%num_workers==shard_id)
        		selfLinks++;
        }
        links = links.substr(spacepos+1);
        linkvec.push_back(to);
    }

    //VLOG(0)<<" num nodes = "<<num_nodes<<" shard id = "<<shard_id<<" links = "<<selfLinks<<"\n";
    *numSelfLinks = selfLinks;
    return linkvec;
}

//struct PagerankInitializer : public Initializer<int, float, vector<int> > { //deepak comment
struct PagerankInitializer : public Initializer<int, float, vector<Link> > {
    void initTable(TypedGlobalTable<int, float, float, vector<Link> >* table, int shard_id, int num_nodes, vector<fpgaWord> &keys, vector<fpgaWord> &ptrdata){
        string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);
        ifstream inFile;
        string type;
        string ip;
        string eth;

        VLOG(0)<<"Inside init table\n";

        int numKeysInTable = 0;
        inFile.open(patition_file.c_str());
        if (!inFile) {
            cerr << "Unable to open file" << patition_file;
            exit(1); // terminate with error
        }

        //parse the conf/nodetype file to identify the node type
        char entry[100];
        ifstream nodeFileType;

        std::string hostfile;

        //the conf files are named 0.conf, 1.conf etc.. based on shard ID - hostname doesnt work for some reason
        std::stringstream out;
        out << shard_id;
        hostfile = std::string("conf/")+out.str().c_str()+std::string(".conf");


        //nodeFileType.open(FLAGS_nodetype_file.c_str());
        nodeFileType.open(hostfile.c_str());
        if (!nodeFileType) {
            cerr << "Unable to open configuration file " << hostfile<<" \n";
            exit(1); // terminate with error
        }

        char hname[128] = "";
        gethostname(hname, sizeof(hname));

        VLOG(0)<<"Opened conf file in "<<hname<<"- "<<hostfile<<"\n";
        int lineNum=0;

        //while(nodeFileType.getline(entry,50)) {
        	nodeFileType.getline(entry,50);
        	string linestr(entry);

        	//Configuration specified as - [cpu/fpga]	[ipaddress of fpga]
        	int worker_id = shard_id; //boost::lexical_cast<int>(linestr.substr(0, pos));

        	int pos = linestr.find("\t");
        	string first = linestr.substr(0, pos);
            string rest = linestr.substr(pos+1);

            pos = rest.find("\t");
            string rest_first = rest.substr(0, pos);
            string rest_rest = rest.substr(pos+1);

            type = first;
            ip   = rest_first;
            eth  = rest_rest;

            wtype worker_type;
            if(type.compare("fpga")==0) {
            	worker_type = FPGA;
                isNodeFPGA=true;
                VLOG(0) << "Node is FPGA\n";
            }
            else {
            	worker_type = CPU;
            	isNodeFPGA=false;
                VLOG(0) << "Node is CPU\n";
            }

            fpga_info_t fpga_info;
            fpga_info.isNodeFPGA = isNodeFPGA;
            fpga_info.fpga_ip_address = ip;
            table->updateFPGAWorkerInfo(worker_id, fpga_info);
            VLOG(0)<<"Host ID - "<<shard_id<<" worker type is "<<worker_type<<" isNode FPGA = "<<isNodeFPGA<<" \n";

            waddress.push_back(workerAddress(worker_id,(wtype)worker_type,ip,eth));
            lineNum++;
         //}
         nodeFileType.close();

         //float imax = std::numeric_limits<float>::max();
         int imax = std::numeric_limits<int>::max();
         char line[1024000];
         //A variable to keep track of how many nodes in the table

         unsigned int keyaddr=FPGA_DRAM_START_ADDRESS;
         unsigned int ptr = FPGA_DRAM_START_ADDRESS + (num_nodes*FPGA_RECORD_SIZE_IN_WORDS*NUM_BYTES_IN_WORDS);
         unsigned int max_vect_size = keys.max_size();
         VLOG(0)<<"Is node fpga is "<<isNodeFPGA<<"\n";
         if(isNodeFPGA) {
         //if(shard_id==0) { //This is the culprit for the CPU to assistant communication breakdown - somehow the second open FPGA port interferes with communication
         	VLOG(0) << "fpga starting - shard ID - "<<shard_id<<"\n ";
         	FPGAThread::Get()->startFPGAThread();


         	//hard code IP addresses - TODO: Move these config to conf/0.conf file
         	if(boost::iequals(hname, "karma")) {
         		VLOG(0)<<"Setting iface name as "<<hname<<"\n";
         		FPGAThread::Get()->FPGAsetIP("10.1.1.1");
         		FPGAThread::Get()->FPGAsetInterfaceIP("10.1.1.2"); //set the interface IP (ie. assign ip address to eth1 port)
         	}
         	else if(boost::iequals(hname, "deepak-OptiPlex-780")) {
         	   VLOG(0)<<"Setting iface name as "<<hname<<"\n";
         	   FPGAThread::Get()->FPGAsetIP("20.1.1.1");
         	   FPGAThread::Get()->FPGAsetInterfaceIP("20.1.1.2"); //set the interface IP (ie. assign ip address to eth1 port)
         	}
         	else if(boost::iequals(hname, "rcg-studio")) {
         	   VLOG(0)<<"Setting iface name as "<<hname<<"\n";
         	   FPGAThread::Get()->FPGAsetIP("30.1.1.1");
         	   FPGAThread::Get()->FPGAsetInterfaceIP("30.1.1.2"); //set the interface IP (ie. assign ip address to eth1 port)
         	}
         	else if(boost::iequals(hname, "maya")) {
         		 VLOG(0)<<"Setting iface name as "<<hname<<"\n";
         		 FPGAThread::Get()->FPGAsetIP("40.1.1.1");
         	     FPGAThread::Get()->FPGAsetInterfaceIP("40.1.1.2"); //set the interface IP (ie. assign ip address to eth1 port)
         	}
         	else {
         		cerr<<"Unknown host name! STOP!!\n";
         	}

         	FPGAThread::Get()->enableFPGAAsst();
         	VLOG(0) << "fpga end\n ";

         	FPGAMessageType msg=START_LOAD;
         	FPGAThread::Get()->FPGAsendMessage(msg);
         }


        while (inFile.getline(line, 1024000)) {
            string linestr(line);
            int pos = linestr.find("\t");
            int source = boost::lexical_cast<int>(linestr.substr(0, pos));
            string links = linestr.substr(pos+1);
            //vector<int> linkvec = readUnWeightLinks(links);
            int selfLinks;
            vector<Link> linkvec = readUnWeightLinks(links,num_nodes,shard_id,&selfLinks);


            //table->put(source, 0.2, 0, linkvec);
            //table->put(source, 1-DAMP_FACTOR, 0, linkvec); //Deepak comment to see if values are the ones received from FPGA
            if(isNodeFPGA) {
            	table->put(source, 0.0, 0, linkvec);
            }
            else {
            	table->put(source, 0.2, 0, linkvec);
            }

            ////////////////FPGA Load //////////////////////
            int numLinks = linkvec.size();
            int numDramWordsForLink = numLinks;

            /*
            if(numLinks%8==0)
             	   	numDramWordsForLink = numLinks/8;
            else
               	  	numDramWordsForLink = (numLinks/8)+1;
			*/
            //VLOG(0) <<"Number of links is "<<numDramWordsForLink<<"\n";


            if(isNodeFPGA) {
            	//Pack the record [key, val, deltaval, ptr, size, 0, 0]
                keys.push_back(fpgaWord(keyaddr,source)); //key
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;

                float deltaval = (float)(1.0-DAMP_FACTOR);
                float val = 0; //test a non zero value deepak

                keys.push_back(fpgaWord(keyaddr,*(int*)&val)); //val
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;
                keys.push_back(fpgaWord(keyaddr,*(int*)&deltaval)); //delta
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;
                keys.push_back(fpgaWord(keyaddr,source));//pri
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;
                keys.push_back(fpgaWord(keyaddr,ptr)); //ptr
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;
                keys.push_back(fpgaWord(keyaddr,numDramWordsForLink)); //size of data
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;

                float mult_factor = (float)(DAMP_FACTOR/numDramWordsForLink);

                keys.push_back(fpgaWord(keyaddr,*(int*)&mult_factor)); //store the multiply factor here (ie. damp_factor/numlinks
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;

                //For multinode clusters, the last field must indicate the total number of self links
                //ie. the fraction of links whose end points reside in the same machine
                //VLOG(0)<<"Number of self links is "<<selfLinks<<"\n";
                keys.push_back(fpgaWord(keyaddr,selfLinks)); //zero
                keyaddr+=FPGA_DRAM_DRAM_INCREMENT_BYTES;

                //VLOG(0) <<"key size is "<<keys.size()<<"\n";
                if(keys.size()>100000000) {
                	VLOG(0) <<"Flushing current data\n";
                	VLOG(0) <<"Size of the nodes is "<<keys.size();
                    VLOG(0) <<"Size of the ptr is "<<ptrdata.size();


                	FPGAThread::Get()->FPGAloadDram(keys,LOAD_DATA);

                    keys.clear();
                }

                int i=0;
                vector<Link>::const_iterator it=linkvec.begin();
                for (it=linkvec.begin(); it!=linkvec.end(); it++) {
                	struct Link l = *it;
                	ptrdata.push_back(fpgaWord(ptr,l.end));
                	ptr = ptr+NUM_BYTES_IN_WORDS;
                	i++;
                }

                while((i%FPGA_RECORD_SIZE_IN_WORDS)!=0) {
                	ptrdata.push_back(fpgaWord(ptr,0xFFFFFFFF)); //dummy fill for unfilled pointers
                    ptr = ptr+NUM_BYTES_IN_WORDS;
                    i++;
                }

                if(ptrdata.size()>100000000) {
                	VLOG(0) <<"Size of the nodes is "<<keys.size();
                    VLOG(0) <<"Size of the ptr is "<<ptrdata.size();

                	VLOG(0) <<"Flushing ptr data\n";
                    FPGAThread::Get()->FPGAloadDram(ptrdata,LOAD_DATA);
                    ptrdata.clear();
                }

                //cout<<" Key - "<<source<<" numLinks = "<<numDramWordsForLink<<" num Self Links = "<<selfLinks<<"\n";

            }
            ///////////////////////////////////////////////////////
            numKeysInTable++;
        }
         VLOG(0)<<"Here\n";
        if(isNodeFPGA) {
        	num_dram_words=num_dram_words+keys.size();
        	num_dram_words=num_dram_words+ptrdata.size();

        	VLOG(0) <<"Size of the nodes is "<<keys.size();
        	VLOG(0) <<"Size of the ptr is "<<ptrdata.size();
              if(keys.size()) {
               	   	FPGAThread::Get()->FPGAloadDram(keys,LOAD_DATA);
               	   	keys.clear();
              }
              if(ptrdata.size()) {
               	   	FPGAThread::Get()->FPGAloadDram(ptrdata,LOAD_DATA);
               	   	ptrdata.clear();
              }

              FPGAThread::Get()->FPGAsendMessage(END_LOAD);

              boost::this_thread::sleep(boost::posix_time::milliseconds(MILLISECONDS_AFTER_LOAD));
              FPGAThread::Get()->setNumKeysInFPGA(numKeysInTable);
        }

        VLOG(0) <<"[[Used DRAM Space ="<<(double)((double)(num_dram_words)/(double)(FPGA_DRAM_SIZE_IN_WORDS/32))*100;
        //wait 1 sec for FPGA to complete data transfer
        //if((keys.size()/FPGA_RECORD_SIZE_IN_WORDS)>=10000)
        //boost::this_thread::sleep(boost::posix_time::milliseconds(FPGA_INTERVAL_BETWEEN_LOAD_PACKET_MILLISECOND));
        //boost::this_thread::sleep(boost::posix_time::milliseconds(2000)); //workaround to fix corrupt values
        //set the number of keys in the table for future use (address allocation)
        //table->setNumKeysInTable(numKeysInTable);

    }
};

struct PagerankSender : public Sender<int, float, vector<Link> > {
    float zero;

    PagerankSender() : zero(0){}

    void send(const float& delta, const vector<Link>& data, vector<pair<int, float> >* output){
        int size = (int) data.size();
        float outv = delta * DAMP_FACTOR / size;

        //VLOG(0) <<" Size is "<<size<<"Out v is "<<outv;
        for(vector<Link>::const_iterator it=data.begin(); it!=data.end(); it++){
            //int target = *it;
        	Link target = *it;
            output->push_back(make_pair(target.end, outv));
            //cout <<"Sending Delta val =  "<<delta<<" target val = "<<outv<<" to node "<<target.end<<"\n";
        }
    }

    const float& reset() const {
        return zero;
    }
};


static int Pagerank(ConfigData& conf) {
    /*
	MaiterKernel<int, float, vector<Link> >* kernel = new MaiterKernel<int, float, vector<Link> >(
                                        conf, FLAGS_num_nodes*conf.num_workers(), FLAGS_portion, FLAGS_result_dir,
                                        new Sharding::Mod,
                                        new PagerankInitializer,
                                        new Accumulators<float>::Sum,
                                        new PagerankSender,
                                        new TermCheckers<int, float>::Diff);
     */

    MaiterKernel<int, float, vector<Link> >* kernel = new MaiterKernel<int, float, vector<Link> >(
                                        conf, FLAGS_num_nodes, FLAGS_portion, FLAGS_result_dir,
                                        new Sharding::Mod,
                                        new PagerankInitializer,
                                        new Accumulators<float>::Sum,
                                        new PagerankSender,
                                        new TermCheckers<int, float>::Diff);

    num_workers = kernel->conf.num_workers();
    
    kernel->registerMaiter();

    if (!StartWorker(conf)) {
        Master m(conf);
        m.run_maiter(kernel);
    }
    
    delete kernel;
    return 0;
}

REGISTER_RUNNER(Pagerank);
