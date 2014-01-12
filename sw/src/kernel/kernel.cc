#include <stdio.h>

#include "kernel/kernel.h"
#include "kernel/table-registry.h"

namespace dsm {

class Worker;
void DSMKernel::initialize_internal(Worker* w, int table_id, int shard) {
  w_ = w;
  table_id_ = table_id;
  shard_ = shard;
}

void DSMKernel::set_args(const MarshalledMap& args) {
  args_ = args;
}

GlobalTable* DSMKernel::get_table(int id) {
  GlobalTable* t = (GlobalTable*)TableRegistry::Get()->table(id);
  CHECK_NE(t, (void*)NULL);
  return t;
}

KernelRegistry* KernelRegistry::Get() {
  static KernelRegistry* r = NULL;
  if (!r) { r = new KernelRegistry; }
  return r;
}

RunnerRegistry* RunnerRegistry::Get() {
  static RunnerRegistry* r = NULL;
  if (!r) { r = new RunnerRegistry; }
  return r;
}


}
