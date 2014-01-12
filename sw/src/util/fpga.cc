
 /* fpga.c
 *
 *  Created on: Sep 29, 2012
 *      Author: deepak
 */
#include "fpga.h"
#include <iostream>

DECLARE_double(sleep_time);

namespace dsm {

static FPGAThread* fp = NULL;

//DEFINE_double(sleep_time, 0.001, "");

FPGAThread* FPGAThread::InitFPGA(int workerId)
{
	VLOG(0) <<"Creating the FPGA helper class...\n";
	fp = new FPGAThread();


	//Get()->startFPGAThread();

	Get()->resetActiveThread();
	Get()->setTid(workerId);
	VLOG(0) <<"FPGA helper class creation success\n";
	return fp;
}

void FPGAThread::startFPGAThread() {
	VLOG(0) <<"FPGA Thread is starting \n";

	//Need a way to delete this instance upon exit TODO
	if(!Get()->FPGAInit()) {
		VLOG(0) << "FPGA initialization unsuccessful\n";
		return;
	}
	else {
		VLOG(0) <<"FPGA initialization successful\n";
	}

	t_ = new boost::thread(&FPGAThread::Run, this);

	termcheck_reply_process_t_ = new boost::thread(&FPGAThread::TermCheckCall, this);
	flush_reply_process_t_     = new boost::thread(&FPGAThread::FlushCall, this);
	//deepak - handle data updates in assistant synchronously (not in a thread)
	//data_reply_process_t_ = new boost::thread(&FPGAThread::DataCall, this);
	//deepak - check to see if activating the FPGA thread is causing an issue
	Get()->setActiveThread();
	//this->isActiveFPGAThread = true;

}

FPGAThread::FPGAThread() {}

FPGAThread* FPGAThread::Get() {
  return fp;
}

void FPGAThread::_RegisterCallback(int message_type, Message *req, Message* resp, FPGACallback cb) {
  FPGACallbackInfo *cbinfo = new FPGACallbackInfo;

  cbinfo->spawn_thread = false;
  cbinfo->req = req;
  cbinfo->resp = resp;
  cbinfo->call = cb;

  //CHECK_LT(message_type, kMaxMethods) << "Message type: " << message_type << " over limit.";
  fpgacallbacks_[message_type] =  cbinfo;
}

void FPGAThread::InvokeCallback(FPGACallbackInfo *ci, FPGARPCInfo rpc) {
  ci->call(rpc);
  //Header reply_header;
  //reply_header.is_reply = true;
  //Send(new RPCRequest(rpc.source, rpc.tag, *ci->resp, reply_header));
}

void FPGAThread::SpawnThreadFor(int req_type) {
  fpgacallbacks_[req_type]->spawn_thread = true;
}

//void Call(int dst, int method, const Message &msg, Message *reply) {
void FPGAThread::TermCheckCall() {
  //Send(dst, method, msg);
  Timer t;
  while(true) {
	  if (this->termcheckReplies.size()==0) {
		  Sleep(FLAGS_sleep_time);
		  //Sleep(0.5);
	  }
	  else {
		  checkTermCheckReplyQueue();
	  }
  }
}

//void Call(int dst, int method, const Message &msg, Message *reply) {
void FPGAThread::DataCall() {
  //Send(dst, method, msg);
  Timer t;
  while(true) {
	  //deepak comment
	  //while (!checkDataReplyQueue()) {
	//	  Sleep(FLAGS_sleep_time);
	  //}
  }
}

//void Call(int dst, int method, const Message &msg, Message *reply) {
void FPGAThread::FlushCall() {
  //Send(dst, method, msg);
  Timer t;
  while(true) {
	  //deepak comment
	  while (true) {
		  if(this->flushReplies.size()==0) {
			  Sleep(0.1);
		  }
		  else
			  checkFlushReplyQueue();
	  }
  }
}


}
