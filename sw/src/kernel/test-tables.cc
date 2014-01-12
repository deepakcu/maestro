#include "util/common.h"
#include "kernel/sparse-table.h"
#include "kernel/global-table.h"

#include "util/static-initializers.h"
#include <gflags/gflags.h>

using std::tr1::unordered_map;
using namespace dsm;

int optimizer_hack;

DEFINE_int32(test_table_size, 100000, "");
#define START_TEST_PERF { Timer t; for (int i = 0; i < FLAGS_test_table_size; ++i) {

#define END_TEST_PERF(name)\
  }\
  fprintf(stderr, "%s: %d ops in %.3f seconds; %.0f/s %.0f cycles\n",\
          #name, FLAGS_test_table_size, t.elapsed(), t.rate(FLAGS_test_table_size), t.cycle_rate(FLAGS_test_table_size)); }

#define TEST_PERF(name, op)\
    START_TEST_PERF \
    op; \
    END_TEST_PERF(name)

namespace {
struct MapTestRGB {
  uint16_t r;
  uint16_t g;
  uint16_t b;
};


template <class T>
static T* GetTable() {
  TableDescriptor td(0, 1);
  td.accumF1 = new Accumulators<int>::Replace();
  td.accumF2 = new Accumulators<int>::Replace();
  td.key_marshal = new Marshal<int>;
  td.value1_marshal = new Marshal<int>;

  T *t = new T;
  t->Init(&td);
  t->resize(100);
  return t;
}

template <class T>
static void TestPut() {
  T* t = GetTable<T>();

  for (int i = 0; i < 10000; ++i) {
    t->put(i, i*7, i*11, "0 1 2 3 4 5 6 7 8 9");
  }

  for (int i = 0; i < 10000; ++i) {
    CHECK(t->contains(i));
    CHECK_EQ(t->getF1(i), i*7);
    CHECK_EQ(t->getF2(i), i*11);
    CHECK_EQ(t->getF3(i), "0 1 2 3 4 5 6 7 8 9");
  }
}

template <class T>
static void TestIterate() {
  T* t = GetTable<T>();

  // Dense tables create entries rounded up to the size of a block, so let's do that here
  // also to avoid spurious errors (for entries that are default initialized)
  for (int i = 0; i < 10000; ++i) {
    t->put(i, 1, 2, "0 1 2 3 4 5 6 7 8 9");
  }

  std::tr1::unordered_map<int, int> check;
  typename T::Iterator *i = (typename T::Iterator*)t->get_iterator();
  while (!i->done()) {
    CHECK_EQ(t->contains(i->key()), true);
    CHECK_EQ(i->value1(), 1) << i->key() << " : " << i->value1();

    check[i->key()] = 1;
    i->Next();
  }

  for (int i = 0; i < 10000; ++i) {
    CHECK(check.find(i) != check.end());
  }
}

template <class T>
static void TestUpdate() {
  T* t = GetTable<T>();

  for (int i = 0; i < 10000; ++i) {
    t->put(i, 1, 2, "0 1 2 3 4 5 6 7 8 9");
  }

  for (int i = 0; i < 10000; ++i) {
    CHECK(t->contains(i));
    t->updateF1(i, 3);
    t->updateF2(i, 4);
    t->updateF3(i, "10");
  }

  for (int i = 0; i < 10000; ++i) {
    CHECK(t->contains(i));
    CHECK_EQ(t->getF1(i), 3);
    CHECK_EQ(t->getF2(i), 4);
    CHECK_EQ(t->getF3(i), "10");
  }
}
/*
typedef NetDecodeIterator<int, int, int, string> NetUpdateDecoder;

template <class T>
static void TestSerialize() {
  T* t = GetTable<T>();

  static const int kTestSize = 10000;
  for (int i = 0; i < kTestSize; ++i) {
    t->put(i, 1, 2, "10");
  }

  CHECK_EQ(t->size(), kTestSize);

  KVPairData tdata;
  T* t2 = GetTable<T>();

  ProtoKVPairCoder c(&tdata);
  NetUpdateDecoder it;
  t2->deserializeFromNet(&c, &it);

  for(;!it.done(); it.Next()) {
	  t2->updateF1(it.key(),it.value1());
  }

  LOG(INFO) << "Serialized table to: " << tdata.ByteSize() << " bytes.";

  CHECK_EQ(t->size(), t2->size());

  TableIterator *i1 = t->get_iterator();
  TableIterator *i2 = t2->get_iterator();

  int count = 0;
  string k1, k2, v1, v2;

  while (!i1->done()) {
    CHECK_EQ(i2->done(), false);

    i1->key_str(&k1); i1->value1_str(&v1);
    i2->key_str(&k2); i2->value1_str(&v2);

    CHECK_EQ(k1, k2);
    CHECK_EQ(v1, v2);

    i1->Next();
    i2->Next();
    ++count;
  }

  CHECK_EQ(i2->done(), true);
  CHECK_EQ(count, t->size());
}
*/
typedef SparseTable<int, int, int, string> STInt;

REGISTER_TEST(SparseTablePut, TestPut<STInt>());

REGISTER_TEST(SparseTableUpdate, TestUpdate<STInt>());

//REGISTER_TEST(SparseTableSerialize, TestSerialize<STInt>());

REGISTER_TEST(SparseTableIterate, TestIterate<STInt>());

static void TestMapPerf() {
  vector<int> source(FLAGS_test_table_size);
  for (int i = 0; i < source.size(); ++i) {
    source[i] = random() % FLAGS_test_table_size;
  }

  SparseTable<int, float, float, string> *h = GetTable<SparseTable<int, float, float, string> >();
  TEST_PERF(SparseTablePut, h->put(source[i], i, i, "0 1 2 3 4 5 6 7 8 9"));
  TEST_PERF(SparseTableGet, h->get(source[i]));

  vector<int> array_test(FLAGS_test_table_size * 2);
  std::tr1::hash<int> hasher;

  // Need to have some kind of side effect or this gets eliminated entirely.
  optimizer_hack = 0;
  TEST_PERF(ArrayPut, optimizer_hack += array_test[hasher(i) % FLAGS_test_table_size]);
}
REGISTER_TEST(SparseTablePerf, TestMapPerf());

}
