#include "client/client.h"
//#include "FPGAInterface.h"

using namespace dsm;

DEFINE_int32(graph_size, 100, "");
DEFINE_bool(weighted, false, "");
DEFINE_double(logn_degree_m, 0, "");
DEFINE_double(logn_degree_s, 2, "");
DEFINE_double(logn_weight_m, 0, "");
DEFINE_double(logn_weight_s, 1, "");
DEFINE_int32(weightgen_method, 1, "");
DEFINE_bool(uploadDFS, false, "");
DEFINE_string(dfs_path, "", "");
DEFINE_string(hadoop_path, "/home/yzhang/hadoop-priter-0.1/bin/hadoop", "");
DECLARE_string(graph_dir);


static boost::mt19937 gen(time(0));

static double _mean_degree=FLAGS_logn_degree_m;
static double _sigma_degree=FLAGS_logn_degree_s;
static double mu_degree = sqrt(exp(2*_mean_degree)*exp(_sigma_degree*_sigma_degree));
static double sigma_degree = exp(_mean_degree)*sqrt(exp(2*_sigma_degree*_sigma_degree)-exp(_sigma_degree*_sigma_degree));

static double _mean_weight=FLAGS_logn_weight_m;
static double _sigma_weight=FLAGS_logn_weight_s;
static double mu_weight = sqrt(exp(2*_mean_weight)*exp(_sigma_weight*_sigma_weight));
static double sigma_weight = exp(_mean_weight)*sqrt(exp(2*_sigma_weight*_sigma_weight)-exp(_sigma_weight*_sigma_weight));

static int rand_target() {
    boost::uniform_int<> dist(0, FLAGS_graph_size-1);
    boost::variate_generator<boost::mt19937&, boost::uniform_int<> > die(gen, dist);
    return die();
}

static int rand_degree() {
    boost::lognormal_distribution<double> lnd(mu_degree, sigma_degree);
    boost::variate_generator<boost::mt19937&, boost::lognormal_distribution<double> > lnd_generator(gen,lnd);
    return ceil(lnd_generator());
}

static float rand_weight() {
    boost::lognormal_distribution<float> lnd(mu_weight, sigma_weight);
    boost::variate_generator<boost::mt19937&, boost::lognormal_distribution<float> > lnd_generator(gen,lnd);
    return lnd_generator();
}

void removeDuplicates(std::vector<int>& vec)
{
   std::sort(vec.begin(), vec.end());
   vec.erase(std::unique(vec.begin(), vec.end()), vec.end());
}

static vector<int> InitLinks(const int &key) {
  vector<int> links;
  int degree = rand_degree();
  if(degree > 10000) {
	  VLOG(1) << "degree is " << degree;
	  degree = 10000;
  }

  /*Deepak added - Cap the max number of edges per node (otherwise makes it difficult for an FPGA implementation)*/
  /*
  while(degree > 500) {
	degree = rand_degree();
  }
  */

  for (int n = 0; n < degree; n++) {
        int p = rand_target();
	//Deepak - Check to see if links dont contain duplicate node IDs
        while((p == key) ) {
            p = rand_target();
        }

        links.push_back(p);
  }

  /*Deepak added*/ 
  removeDuplicates(links); //check
  return links;
}

//d = log(1+logn(m,s))
static vector<Link> InitLinks2(int key) {
  vector<Link> links;
  int degree = rand_degree();
  if(degree > 10000) {
	  VLOG(1) << "degree is " << degree;
	  degree = 10000;
  }

  for (int n = 0; n < degree; n++) {
      int target = rand_target();
      while(target == key){
          target = rand_target();
      }
              
      float weight = log(1+rand_weight());
      
      links.push_back(Link(target, weight, 0));
  }
  return links;
}

//d = 1/logn(m,s)
static vector<Link> InitLinks3(int key) {
  vector<Link> links;
  int degree = rand_degree();
  if(degree > 10000) {
	  VLOG(1) << "degree is " << degree;
	  degree = 10000;
  }

  for (int n = 0; n < degree; n++) {
      int target = rand_target();
      while(target == key){
          target = rand_target();
      }
              
      float weight = 1 / rand_weight();
      
      links.push_back(Link(target, weight, 0));
  }
  return links;
}



struct GraphGenInitializer : public Initializer<int, float, vector<int> > {
public:
    void gen_unweightgraph(TypedGlobalTable<int, float, float, vector<int> >* a, int shard_id){  
      ofstream partition;
      string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);
      partition.open(patition_file.c_str());

      const int num_shards = a->num_shards();
      for (int i = shard_id; i < FLAGS_graph_size; i += num_shards) { //Deepak - This is where unique key value pairs for each worker are generated i+=num_shards
          partition << i << "\t";
          vector<int> links = InitLinks(i);
          vector<int>::iterator it;
          for(it=links.begin(); it!=links.end(); it++){
              int target = *it;
              partition << target << " ";
          }
          partition << "\n";

          /*Print links test here*/
          /*
          for(it=links.begin(); it!=links.end(); it++) {
        	  cout<<" Link from here is "<<*it<<"\n";
          }
          */

          //Deepak - Hack here to send generated data to FPGA worker
          //sendToFPGA(i,links);

      }
      partition.close();
    }

    void gen_hadoop_unweightgraph(TypedGlobalTable<int, float, float, vector<int> >* a, int shard_id){  
      ofstream partition;
      ofstream hadooppartition;
      string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);
      string patition_file_hadoop = StringPrintf("%shadoop/part%d", FLAGS_graph_dir.c_str(), shard_id);
      partition.open(patition_file.c_str());
      hadooppartition.open(patition_file_hadoop.c_str());

      const int num_shards = a->num_shards();
      for (int i = shard_id; i < FLAGS_graph_size; i += num_shards) {
          partition << i << "\t";
          hadooppartition << i << "\t1:";
          vector<int> links = InitLinks(i);
          vector<int>::iterator it;
          for(it=links.begin(); it!=links.end(); it++){
              int target = *it;
              partition << target << " ";
              hadooppartition << target << " ";
          }
          partition << "\n";
          hadooppartition << "\n";
      }
      partition.close();
      hadooppartition.close();              

      string delete_cmd = StringPrintf("%s dfs -rmr %s", FLAGS_hadoop_path.c_str(), patition_file.c_str());
      string put_cmd = StringPrintf("%s dfs -put %s %s", FLAGS_hadoop_path.c_str(), patition_file.c_str(), patition_file.c_str());
      VLOG(1) << "hadoop cmd is " << endl << delete_cmd << endl << put_cmd << endl;
      system(delete_cmd.c_str());
      system(put_cmd.c_str());

      string delete_cmd2 = StringPrintf("%s dfs -rmr %s", FLAGS_hadoop_path.c_str(), patition_file_hadoop.c_str());
      string put_cmd2 = StringPrintf("%s dfs -put %s %s", FLAGS_hadoop_path.c_str(), patition_file_hadoop.c_str(), patition_file_hadoop.c_str());
      VLOG(1) << "hadoop cmd is " << endl << delete_cmd2 << endl << put_cmd2 << endl;
      system(delete_cmd2.c_str());
      system(put_cmd2.c_str());
    }

    void gen_weightgraph(TypedGlobalTable<int, float, float, vector<int> >* a, int shard_id){  
        VLOG(1) << "i am in";
      ofstream partition;
      string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);

      partition.open(patition_file.c_str());

      const int num_shards = a->num_shards();
      for (int i = shard_id; i < FLAGS_graph_size; i += num_shards) {
          partition << i << "\t";
          vector<Link> links = InitLinks2(i);
          vector<Link>::iterator it;
          for(it=links.begin(); it!=links.end(); it++){
              Link target = *it;
              partition << target.end << "," << target.weight << " ";
          }
          partition << "\n";
      }
      partition.close();
      VLOG(1) << "i am out";
    }


    void gen_hadoop_weightgraph(TypedGlobalTable<int, float, float, vector<int> >* a, int shard_id){  
      ofstream partition, hadoop_partition;
      string patition_file = StringPrintf("%s/part%d", FLAGS_graph_dir.c_str(), shard_id);
      string hadoop_patition_file = StringPrintf("%shadoop/part%d", FLAGS_graph_dir.c_str(), shard_id);
      partition.open(patition_file.c_str());
      hadoop_partition.open(hadoop_patition_file.c_str());

      const int num_shards = a->num_shards();
      for (int i = shard_id; i < FLAGS_graph_size; i += num_shards) {
          partition << i << "\t";
          if(i == 0){
              hadoop_partition << i << "\tf0:";
          }else{
              hadoop_partition << i << "\tp:";
          }

          vector<Link> links = InitLinks2(i);
          vector<Link>::iterator it;
          for(it=links.begin(); it!=links.end(); it++){
              Link target = *it;
              partition << target.end << "," << target.weight << " ";
              hadoop_partition << target.end << "," << target.weight << " ";
          }
          partition << "\n";
          hadoop_partition << "\n";
      }
      partition.close();
      hadoop_partition.close();

      string delete_cmd = StringPrintf("%s dfs -rmr %s", FLAGS_hadoop_path.c_str(), patition_file.c_str());
      string put_cmd = StringPrintf("%s dfs -put %s %s", FLAGS_hadoop_path.c_str(), patition_file.c_str(), patition_file.c_str());
      VLOG(1) << "hadoop cmd is " << endl << delete_cmd << endl << put_cmd << endl;
      system(delete_cmd.c_str());
      system(put_cmd.c_str());

      string delete_cmd2 = StringPrintf("%s dfs -rmr %s", FLAGS_hadoop_path.c_str(), hadoop_patition_file.c_str());
      string put_cmd2 = StringPrintf("%s dfs -put %s %s", FLAGS_hadoop_path.c_str(), hadoop_patition_file.c_str(), hadoop_patition_file.c_str());
      VLOG(1) << "hadoop cmd is " << endl << delete_cmd2 << endl << put_cmd2 << endl;
      system(delete_cmd2.c_str());
      system(put_cmd2.c_str());
    }

    void initTable(TypedGlobalTable<int, float, float, vector<int> >* table, int shard_id, int num_nodes, vector<fpgaWord> &keys, vector<fpgaWord> &ptrdata){
      VLOG(1) << "generating synthetic graph";
      //table->InitStateTable();
      if(FLAGS_uploadDFS){
          if(FLAGS_weighted){
              gen_hadoop_weightgraph(table, shard_id);
          }else{
              gen_hadoop_unweightgraph(table, shard_id);
          }
      }else{
          if(FLAGS_weighted){
              gen_weightgraph(table, shard_id);
          }else{
              gen_unweightgraph(table, shard_id);
          }
      }
    }
};


static int GraphGen(ConfigData& conf) {
    MaiterKernel<int, float, vector<int> >* kernel = new MaiterKernel<int, float, vector<int> >(
                                        conf, FLAGS_graph_size, 1, "",
                                        new Sharding::Mod,
                                        new GraphGenInitializer,
                                        NULL,
                                        NULL,
                                        NULL);
    
    
    kernel->registerMaiter();

    if (!StartWorker(conf)) {
        Master m(conf);
        m.run_maiter(kernel);
    }
    
    delete kernel;
    return 0;
}

REGISTER_RUNNER(GraphGen);
