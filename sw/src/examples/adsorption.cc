#include "client/client.h"


using namespace dsm;

DECLARE_string(graph_dir);
DECLARE_string(result_dir);
DECLARE_int64(num_nodes);
DECLARE_double(portion);
DECLARE_int32(adsorption_starts);
DECLARE_double(adsorption_damping);

static vector<Link> readWeightLinks(string links){
    vector<Link> linkvec;
    int spacepos = 0;
    while((spacepos = links.find_first_of(" ")) != links.npos){
        Link to(0, 0, 0);
        if(spacepos > 0){
            string link = links.substr(0, spacepos);
            int cut = links.find_first_of(",");
            to.end = boost::lexical_cast<int>(link.substr(0, cut));
            to.weight = boost::lexical_cast<float>(link.substr(cut+1));
        }
        links = links.substr(spacepos+1);
        linkvec.push_back(to);
    }
    
    return linkvec;
}

struct AdsorptionInitializer : public Initializer<int, float, vector<Link> > {
    void initTable(TypedGlobalTable<int, float, float, vector<Link> >* table, int shard_id, int num_nodes, vector<fpgaWord> &keys, vector<fpgaWord> &ptrdata){
        string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);
        ifstream inFile;
        inFile.open(patition_file.c_str());

        if (!inFile) {
            cerr << "Unable to open file" << patition_file;
            exit(1); // terminate with error
        }

        char line[1024000];
        while (inFile.getline(line, 1024000)) {
            string linestr(line);
            int pos = linestr.find("\t");
            int source = boost::lexical_cast<int>(linestr.substr(0, pos));
            string links = linestr.substr(pos+1);
            vector<Link> linkvec = readWeightLinks(links);

            if(source < FLAGS_adsorption_starts){
                table->put(source, 10, 0, linkvec);
            }else{
                table->put(source, 0, 0, linkvec);
            }
        }
    }
};

struct AdsorptionSender : public Sender<int, float, vector<Link> > {
    float zero;
    
    AdsorptionSender() : zero(0) {}
    
    void send(const float& delta, const vector<Link>& data, vector<pair<int, float> >* output){
        for(vector<Link>::const_iterator it=data.begin(); it!=data.end(); it++){
            Link target = *it;
            float outv = delta * FLAGS_adsorption_damping * target.weight;
            output->push_back(make_pair(target.end, outv));
        }
    }

    const float& reset() const{
        return zero;
    }
};


static int Adsorption(ConfigData& conf) {
    MaiterKernel<int, float, vector<Link> >* kernel = new MaiterKernel<int, float, vector<Link> >(
                                        conf, FLAGS_num_nodes, FLAGS_portion, FLAGS_result_dir,
                                        new Sharding::Mod,
                                        new AdsorptionInitializer,
                                        new Accumulators<float>::Sum,
                                        new AdsorptionSender,
                                        new TermCheckers<int, float>::Diff);
    
    
    kernel->registerMaiter();

    if (!StartWorker(conf)) {
        Master m(conf);
        m.run_maiter(kernel);
    }
    
    delete kernel;
    return 0;
}

REGISTER_RUNNER(Adsorption);

