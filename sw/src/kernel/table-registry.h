#ifndef KERNEL_H_
#define KERNEL_H_

#include "util/common.h"
#include "kernel/table.h"
#include "kernel/global-table.h"
#include "kernel/local-table.h"
#include "kernel/statetable.h"
#include "kernel/deltatable.h"

static const int kStatsTableId = 1000000;

namespace dsm {

class GlobalTable;

class TableRegistry : private boost::noncopyable {
private:
  TableRegistry() {}
public:
  typedef map<int, GlobalTable*> Map;

  static TableRegistry* Get();

  Map& tables();
  GlobalTable* table(int id);
  MutableGlobalTable* mutable_table(int id);

private:
  Map tmap_;
};

// Swig doesn't like templatized default arguments; work around that here.
template<class K, class V1, class V2, class V3>
static TypedGlobalTable<K, V1, V2, V3>* CreateTable(int id, int shards, double schedule_portion,
                                           Sharder<K>* sharding,
                                           Initializer<K, V1, V3>* initializer,
                                           Accumulator<V1>* accum,
                                           Sender<K, V1, V3>* sender,
                                           TermChecker<K, V2>* termchecker) {
  TableDescriptor *info = new TableDescriptor(id, shards);
  info->key_marshal = new Marshal<K>;
  info->value1_marshal = new Marshal<V1>;
  info->value2_marshal = new Marshal<V2>;
  info->value3_marshal = new Marshal<V3>;
  info->sharder = sharding;
  info->initializer = initializer;
  info->partition_factory = new typename StateTable<K, V1, V2, V3>::Factory;
  info->deltaT_factory = new typename DeltaTable<K, V1>::Factory;
  info->accum = accum;
  info->sender = sender;
  info->termchecker = termchecker;
  info->schedule_portion = schedule_portion;

  return CreateTable<K, V1, V2, V3>(info);
}

template<class K, class V1, class V2, class V3>
static TypedGlobalTable<K, V1, V2, V3>* CreateTable(const TableDescriptor *info) {
  TypedGlobalTable<K, V1, V2, V3> *t = new TypedGlobalTable<K, V1, V2, V3>();
  t->Init(info);
  TableRegistry::Get()->tables().insert(make_pair(info->table_id, t));
  return t;
}

} // end namespace
#endif /* KERNEL_H_ */
