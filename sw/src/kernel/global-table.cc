#include "kernel/global-table.h"
#include "statetable.h"
#include "util/fpga.h"

static const int kMaxNetworkPending = 1 << 26;
static const int kMaxNetworkChunk = 1 << 20;

DEFINE_int32(snapshot_interval, 99999999, "");
DEFINE_int32(bufmsg, 1000000, "");

namespace dsm {

void GlobalTableBase::UpdatePartitions(const ShardInfo& info) {
  partinfo_[info.shard()].sinfo.CopyFrom(info);
}

GlobalTableBase::~GlobalTableBase() {
  for (int i = 0; i < partitions_.size(); ++i) {
    delete partitions_[i];
  }
}

TableIterator* GlobalTableBase::get_iterator(int shard, bool bfilter, unsigned int fetch_num) {
  return partitions_[shard]->get_iterator(this->helper(), bfilter);
}

bool GlobalTableBase::is_local_shard(int shard) {
  if (!helper()) 
    return false;
  //cout<<"Owner of shard = "<<owner(shard)<<"Helper = "<<helper_id()<<"\n";
  return owner(shard) == helper_id();
}

bool GlobalTableBase::is_local_key(const StringPiece &k) {
  return is_local_shard(shard_for_key_str(k));
}

void GlobalTableBase::Init(const TableDescriptor *info) {
  TableBase::Init(info);
  partitions_.resize(info->num_shards);
  partinfo_.resize(info->num_shards);
}

int64_t GlobalTableBase::shard_size(int shard) {
  if (is_local_shard(shard)) {
    return partitions_[shard]->size();
  } else {
    return partinfo_[shard].sinfo.entries();
  }
}

void MutableGlobalTableBase::resize(int64_t new_size) {
  for (int i = 0; i < partitions_.size(); ++i) {
    if (is_local_shard(i)) {
      partitions_[i]->resize(new_size / partitions_.size());
    }
  }
}

void MutableGlobalTableBase::swap(GlobalTable *b) {
  SwapTable req;

  req.set_table_a(this->id());
  req.set_table_b(b->id());
  VLOG(2) << StringPrintf("Sending swap request (%d <--> %d)", req.table_a(), req.table_b());

  NetworkThread::Get()->SyncBroadcast(MTYPE_SWAP_TABLE, req);
}

void MutableGlobalTableBase::clear() {
  ClearTable req;

  req.set_table(this->id());
  VLOG(2) << StringPrintf("Sending clear request (%d)", req.table());

  NetworkThread::Get()->SyncBroadcast(MTYPE_CLEAR_TABLE, req);
}


void MutableGlobalTableBase::start_checkpoint(const string& f) {
  for (int i = 0; i < partitions_.size(); ++i) {
    LocalTable *t = partitions_[i];

    if (is_local_shard(i)) {
      t->start_checkpoint(f + StringPrintf(".%05d-of-%05d", i, partitions_.size()));
    }
  }
}

void MutableGlobalTableBase::write_delta(const KVPairData& d) {
  if (!is_local_shard(d.shard())) {
    LOG_EVERY_N(INFO, 1000) << "Ignoring delta write for forwarded data";
    return;
  }

  partitions_[d.shard()]->write_delta(d);
}

void MutableGlobalTableBase::finish_checkpoint() {
  for (int i = 0; i < partitions_.size(); ++i) {
    LocalTable *t = partitions_[i];

    if (is_local_shard(i)) {
      t->finish_checkpoint();
    }
  }
}

void MutableGlobalTableBase::restore(const string& f) {
  for (int i = 0; i < partitions_.size(); ++i) {
    LocalTable *t = partitions_[i];

    if (is_local_shard(i)) {
      t->restore(f + StringPrintf(".%05d-of-%05d", i, partitions_.size()));
    } else {
      t->clear();
    }
  }
}

void MutableGlobalTableBase::TermCheck() {
    PERIODIC(FLAGS_snapshot_interval, {this->termcheck();});
}

void MutableGlobalTableBase::termcheck() {
    double total_current = 0;
    int total_updates = 0;
    for (int i = 0; i < partitions_.size(); ++i) {   
      if (is_local_shard(i)) {
        LocalTable *t = partitions_[i];
        double partF2;
        int partUpdates;
        t->termcheck(StringPrintf("snapshot/iter%d-part%d", snapshot_index, i), &partUpdates, &partF2);
        total_current += partF2;
        total_updates += partUpdates;
      }
    }
    //Deepak - probably hack here to do a termination check for FPGA based nodes
    VLOG(0) << "Yes ! I was here - total current = "<<total_current<<"!\n";
    if(helper()){
        helper()->SendTermcheck(snapshot_index, total_updates, total_current);
    }
  
    snapshot_index++;
}

void MutableGlobalTableBase::HandlePutRequests() {
  if (helper()) {
    helper()->HandlePutRequest();
  }
}

ProtoTableCoder::ProtoTableCoder(const TableData *in) : read_pos_(0), t_(const_cast<TableData*>(in)) {}

bool ProtoTableCoder::ReadEntryFromFile(string *k, string *v1, string *v2, string *v3) {
  if (read_pos_ < t_->rec_data_size()) {
    k->assign(t_->rec_data(read_pos_).key());
    v1->assign(t_->rec_data(read_pos_).value1());
    v2->assign(t_->rec_data(read_pos_).value2());
    v3->assign(t_->rec_data(read_pos_).value3());
    ++read_pos_;
    return true;
  }

  return false;
}

void ProtoTableCoder::WriteEntryToFile(StringPiece k, StringPiece v1, StringPiece v2, StringPiece v3) {
  Record *a = t_->add_rec_data();
  a->set_key(k.data, k.len);
  a->set_value1(v1.data, v1.len);
  a->set_value2(v2.data, v2.len);
  a->set_value3(v3.data, v3.len);
}

ProtoKVPairCoder::ProtoKVPairCoder(const KVPairData *in) : read_pos_(0), t_(const_cast<KVPairData*>(in)) {}

bool ProtoKVPairCoder::ReadEntryFromNet(string *k, string *v) {
  if (read_pos_ < t_->kv_data_size()) {
    k->assign(t_->kv_data(read_pos_).key());
    v->assign(t_->kv_data(read_pos_).value());
    ++read_pos_;
    return true;
  }

  return false;
}

void ProtoKVPairCoder::WriteEntryToNet(StringPiece k, StringPiece v) {
  Arg *a = t_->add_kv_data();
  a->set_key(k.data, k.len);
  a->set_value(v.data, v.len);
}

void MutableGlobalTableBase::BufSend() {

	//cout<<"Pending writes = "<<pending_writes_<<"\n";
	//cout<<"Buf msg flag = "<<FLAGS_bufmsg<<"\n";

    if (pending_writes_ > FLAGS_bufmsg) {
    	VLOG(2) << "accumulate enought pending writes " << pending_writes_ << " we send them";
      SendUpdates();
    }
}

void MutableGlobalTableBase::SendUpdates() {
  KVPairData put;
  for (int i = 0; i < partitions_.size(); ++i) {
    LocalTable *t = partitions_[i];

    //Deepak - This is where the key value pairs are actually transmitted to other workers - hack here
    if (!is_local_shard(i) && (get_partition_info(i)->dirty || !t->empty())) {
      // Always send at least one chunk, to ensure that we clear taint on
      // tables we own.
      do {
        put.Clear();
        put.set_shard(i);
        put.set_source(helper()->id());
        put.set_table(id());
        put.set_epoch(helper()->epoch());

        ProtoKVPairCoder c(&put);
        t->serializeToNet(&c);
        t->reset();
        put.set_done(true);

        //VLOG(3) << "Sending update for " << MP(t->id(), t->shard()) << " to " << owner(i) << " size " << put.kv_data_size();
        //cout << "Sending update for " << MP(t->id(), t->shard()) << " to " << owner(i) << " size " << put.kv_data_size()<<"\n";
        //VLOG(0) << "Sending update for " << MP(t->id(), t->shard()) << " to " << owner(i) << " size " << put.kv_data_size()<<"\n";

        NetworkThread::Get()->Send(owner(i) + 1, MTYPE_PUT_REQUEST, put);
      } while(!t->empty());

      VLOG(3) << "Done with update for " << MP(t->id(), t->shard());
      t->clear();
    }
  }
/*
  sendtime++;
  if(sendtime == 750)
	  VLOG(0) << sendtime << " takes " << send_overhead <<
		  " object create takes " << objectcreate_overhead;
*/
  pending_writes_ = 0;
}

int MutableGlobalTableBase::pending_write_bytes() {
  int64_t s = 0;
  for (int i = 0; i < partitions_.size(); ++i) {
    LocalTable *t = partitions_[i];
    if (!is_local_shard(i)) {
      s += t->size();
    }
  }

  return s;
}

void MutableGlobalTableBase::local_swap(GlobalTable *b) {
  CHECK(this != b);

  MutableGlobalTableBase *mb = dynamic_cast<MutableGlobalTableBase*>(b);
  std::swap(partinfo_, mb->partinfo_);
  std::swap(partitions_, mb->partitions_);
  std::swap(cache_, mb->cache_);
  std::swap(pending_writes_, mb->pending_writes_);
}
}
