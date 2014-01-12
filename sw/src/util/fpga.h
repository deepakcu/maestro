#ifndef FPGA_H
#define FPGA_H

#include <iostream>
#include "common.h"
/*
#include <linux/if_packet.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
*/

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <net/if.h>
#include <linux/sockios.h>
#include <boost/thread.hpp>
#include <boost/function.hpp>
//deepak - following to set the interface IP
#include <sys/ioctl.h>

#if __GLIBC__ >=2 && __GLIBC_MINOR >= 1
#include <netpacket/packet.h>
#include <net/ethernet.h>
#else
#include <asm/types.h>
#include <linux/if_ether.h>
#endif
#include <time.h>

//#define OUT_BUFFSIZE 1400
#define COMMAND_HEADER_SIZE 		6 //bytes
#define NUM_KV_PAIRS_PER_PACKET 	21 //how many kvpairs in 1 packet ?
#define BYTES_PER_KV_PAIR			64
#define NUM_BYTES_PER_PACKET		(COMMAND_HEADER_SIZE+NUM_KV_PAIRS_PER_PACKET*BYTES_PER_KV_PAIR) //1350
#define NUM_DATA_BYTES_PER_PACKET	(NUM_BYTES_PER_PACKET-COMMAND_HEADER_SIZE) //1344 //actual data exluding the command header
#define NUM_NIBBLES_PER_PACKET		(NUM_DATA_BYTES_PER_PACKET)/4 //336

#define OUT_BUFFSIZE 1350 //6 bytes for command+21 Kv pairs - Each kvpair takes 8 8-byte words = 64 bytes - therfore 21*64+6=1350

#define IN_BUFFSIZE  1500 //Max size of Ethernet frame
#define RCV_QUEUE_SIZE 10000
#define PORT 30

#define IFNAME "eth1"
#define HOST "10.1.1.4"
#define ifreq_offsetof(x)  offsetof(struct ifreq, x)

//void Die(char *mess) { perror(mess); exit(1); }
typedef void (*cbfunc_t)(char* buf, int len);

//using namespace std;
namespace dsm {

typedef google::protobuf::Message Message;
struct FPGARPCInfo {
  int source;
  int dest;
  int tag;
  char *msg;
  int length;
};

typedef enum  {
	START_LOAD=1,
	LOAD_DATA=2,
	END_LOAD=3,
	WORKER_TO_FPGA_PUT_REQUEST=4,
	START_UPDATE=5,
	END_UPDATE=6,
	START_CHECK_TERMINATE=7,
	START_FLUSH_DATA=8,
	FPGA_TO_WORKER_PUT_REQUEST=9, //reply message from FPGA
	FLUSH_DATA=10, //a			  //reply message from FPGA
	CHECK_TERMINATE=11, //b		  //reply message from FPGA
	EMPTY_COMMAND=12
}FPGAMessageType;

//#pragma pack(1)
typedef struct __attribute__((__packed__)) loadMessage {
	int  cmd;
	char pad[2];
	//int  message[OUT_BUFFSIZE/sizeof(int)];
	int  message[NUM_NIBBLES_PER_PACKET];
}lMessage_t;
//#pragma pack(pop)

/*
class FPGACallbackInfo {
public:
	FPGAMessageType mtype;
	cbfunc_t func; //the callback function

	FPGACallbackInfo() {}
	//FPGACallbackInfo(FPGAMessageType mt, cbfunc_t f);

	FPGACallbackInfo(FPGAMessageType mt, cbfunc_t f) {
		this->mtype = mt;
		this->func = f;
	}
};
*/



class FPGAThread {



public:
	static FPGAThread *Get();
	static FPGAThread* InitFPGA(int workerId);
	FPGAThread();
	~FPGAThread();
	void startFPGAThread();
	void TermCheckCall();
	void DataCall();
	void FlushCall();


#ifndef SWIG
  // Register the given function with the RPC thread.  The function will be invoked
  // from within the network thread whenever a message of the given type is received.
  typedef boost::function<void (const FPGARPCInfo& rpc)> FPGACallback;

  // Use RegisterCallback(...) instead.
  void _RegisterCallback(int req_type, Message *req, Message *resp, FPGACallback cb);

  // After registering a callback, indicate that it should be invoked in a
  // separate thread from the RPC server.
  void SpawnThreadFor(int req_type);
#endif

	struct FPGACallbackInfo {
	    Message *req;
	    Message *resp;

	    FPGACallback call;

	    bool spawn_thread;
	};




/*
void Run() {
	while(1)
	{
		//VLOG(0) << "Waiting in the recv thread\n";
		int len =recvfrom(sockfd_from_fpga, incoming_msg, IN_BUFFSIZE, 0, (struct sockaddr*)&from_fpga, &slen_from_fpga);
		if (len==-1)
		        std::cerr << "error in recieve()\n";
		//VLOG(0) << "Received\n";
		//VLOG(1) << "Received packet from %s:%d\nData: %s\n\n" << inet_ntoa(fpga_client.sin_addr), ntohs(fpga_client.sin_port), incoming_msg);


		//VLOG(1) << "Received packet from %s:%d\nData: %s\n\n",inet_ntoa(fpga_client.sin_addr), ntohs(fpga_client.sin_port), incoming_msg);

		//parse the incoming message, (make sure that the message is for us
		//copy the data to a buffer so that the rcv thread can capture new data


		//parse the header to understand the message type
		int *command = (int*)(&incoming_msg);
		//cout << "Reply recieved - Command is "<<(*command)<<"\n";
		//call the callback function with the key value pair

		int rcvType = *command;
		//VLOG(0) << " Command is " << *command << "\n";
		//tmp++;
		char *data = (char*)(&incoming_msg);
		len = len-(sizeof(int)+2); //skip 6 bytes
		data = data + (sizeof(int)+2);

		//cout<<"[FPGARcv] Length of databuf = "<<len;
		char *databuf = (char*)malloc(len*sizeof(char)); //this buffer must be freed after the data is processed (accumulated in statetable.h/kernel.h)
		memcpy(databuf,data,len);

		//printf("Here Key of the second string is %x\n",*((unsigned int*) (data+2*sizeof(int)) ));
		//printf("Here Val of the second string is %x\n",*((unsigned int*) (data+3*sizeof(int)) ));

		FPGARPCInfo rpc; //= { 0, 0, command, data, len };
		rpc.dest = 0;
		rpc.length = len;
		rpc.msg = databuf;
		rpc.source = 0;
		rpc.tag = rcvType;
		FPGACallbackInfo *ci = fpgacallbacks_[rcvType];

		//simply enqueue the replies from FPGAs - they will be processed in a different thread
		//boost::recursive_mutex::scoped_lock sl(q_lock);
		//deepak - need to figure out a way to handle fast responses from FPGA - for now, lets try not to enqueu anything other than termcheck responses from FPGA
		if(rpc.tag==CHECK_TERMINATE) {
			termcheckReplies.push_back(rpc);
		}
		else if(rpc.tag==FPGA_TO_WORKER_PUT_REQUEST){
			dataReplies.push_back(rpc);
			packet_count++;

		}
		else if(rpc.tag==FLUSH_DATA) {
			flushReplies.push_back(rpc);
			//ci->call(rpc);
		}
		else {
			cerr<<"Unknown message\n";
		}

		//ci->call(rpc);


	}

	//compare the message, invoke the callback method corresponding to the message type

}
*/

	void Run() {
		while(1)
		{
			//VLOG(0) << "Waiting in the recv thread\n";
			int len =recvfrom(sockfd_from_fpga, incoming_msg, IN_BUFFSIZE, 0, (struct sockaddr*)&from_fpga, &slen_from_fpga);

			if (len==-1) {
			        std::cerr << "error in recieve()\n";
			        break;
			}

			//parse the header to understand the message type
			int *command = (int*)(&incoming_msg);

			int rcvType = *command;
			char *data = (char*)(&incoming_msg);
			len = len-(sizeof(int)+2); //skip 6 bytes
			data = data + (sizeof(int)+2);

			char *databuf = (char*)malloc(len*sizeof(char)); //this buffer must be freed after the data is processed (accumulated in statetable.h/kernel.h)
			memcpy(databuf,data,len);

			FPGARPCInfo rpc; //= { 0, 0, command, data, len };
			rpc.dest = 0;
			rpc.length = len;
			rpc.msg = databuf;
			rpc.source = 0;
			rpc.tag = rcvType;
			FPGACallbackInfo *ci = fpgacallbacks_[rcvType];

			if(rpc.tag==CHECK_TERMINATE) {
				termcheckReplies.push_back(rpc);
			}
			/*
			else if(rpc.tag==FPGA_TO_WORKER_PUT_REQUEST){
				dataReplies.push_back(rpc);
				packet_count++;

			}
			*/
			else if(rpc.tag==FLUSH_DATA) {
				flushReplies.push_back(rpc);
				//ci->call(rpc);
			}
			else {
				//cout<<"rpc.tag is "<<rpc.tag<<"\n";
				//cerr<<"Unknown message with tag = "<<rpc.tag<<"\n";
			}
		}
		//close(sockfd_from_fpga);
	}


//bool check_reply_queue(int src, int type) {
bool checkTermCheckReplyQueue() {
  Queue& q = termcheckReplies;

  if (!q.empty()) {
    const FPGARPCInfo& rpc = q.front();
    FPGACallbackInfo *ci = fpgacallbacks_[rpc.tag];
   	ci->call(rpc); //disable calling in this context
    q.pop_front();
    return true;
  }
  return false;
}

/*
bool checkDataReplyQueue() {
  Queue& q = dataReplies;

  if (!q.empty()) {

    const FPGARPCInfo& rpc = q.front();
    FPGACallbackInfo *ci = fpgacallbacks_[rpc.tag];
	//new boost::thread(boost::bind(&FPGAThread::InvokeCallback, this, ci, rpc)); //call callback in a new thread
    ci->call(rpc); //call in this thread context

    q.pop_front();
    return true;
  }
  return false;
}
*/


int getDataReplyQueueSize() {
	return dataReplies.size();
}

//deepak - new
FPGARPCInfo checkDataReplyQueue() {
  Queue& q = dataReplies;

  if(q.empty()) {
	  FPGARPCInfo rpc;
	  rpc.tag=EMPTY_COMMAND;
	  return rpc;
  }
  else {
	  FPGARPCInfo rpc =  q.front();
	  q.pop_front();
	  return rpc;
  }

/*
  q.pop_front()
    const FPGARPCInfo& rpc = q.front();
    FPGACallbackInfo *ci = fpgacallbacks_[rpc.tag];
	//new boost::thread(boost::bind(&FPGAThread::InvokeCallback, this, ci, rpc)); //call callback in a new thread
    ci->call(rpc); //call in this thread context


    return true;
  }
  return false;
  */
}

//deepak - new
bool checkFlushReplyQueue() {
	  Queue& q = flushReplies;

	  if (!q.empty()) {
	    const FPGARPCInfo& rpc = q.front();
	    FPGACallbackInfo *ci = fpgacallbacks_[rpc.tag];
	    updateKeysReturnedFromFPGA();
	   	ci->call(rpc); //disable calling in this context
	    q.pop_front();
	    return true;
	  }
	  return false;
}


void FPGAsetInterfaceIP(char *host_ip)
{
	struct ifreq ifr;
	struct sockaddr_in sai;
	int sockfd;                     /* socket fd we use to manipulate stuff with */
	int selector;
	unsigned char mask;

	char *p;

    cout<<"In FPGA Set interface IP\n";
    /* Create a channel to the NET kernel. */
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    /* get interface name */
    strncpy(ifr.ifr_name, IFNAME, IFNAMSIZ);

    memset(&sai, 0, sizeof(struct sockaddr));
    sai.sin_family = AF_INET;
    sai.sin_port = 0;

    //sai.sin_addr.s_addr = inet_addr(HOST);
    sai.sin_addr.s_addr = inet_addr(host_ip);

    p = (char *) &sai;
    memcpy( (((char *)&ifr + ifreq_offsetof(ifr_addr) )),
    p, sizeof(struct sockaddr));
    int status=ioctl(sockfd, SIOCSIFADDR, &ifr);
    if(status<0) {
        	VLOG(0)<<"SIOCSIFADDR Interface setIP error\n";
    }
    ioctl(sockfd, SIOCGIFFLAGS, &ifr);
    if(status<0) {
    	VLOG(0)<<"SIOCGIFFLAGS Interface setIP error\n";
    }
    ifr.ifr_flags |= IFF_UP | IFF_RUNNING;
    // ifr.ifr_flags &= ~selector;  // unset something

    ioctl(sockfd, SIOCSIFFLAGS, &ifr);
    close(sockfd);
}



/*
 * Set the fpga server's IP and FPGA node's ethernet IP
 *
 */
void FPGAsetIP(std::string fpga_addr)
{
	fpga_ip_addr = fpga_addr.c_str();

	/* Construct the server sockaddr_in structure */
	memset(&to_fpga, 0, sizeof(to_fpga));          				/* Clear struct */
	to_fpga.sin_family = AF_INET;                  	   	 /* Internet/IP */
	to_fpga.sin_addr.s_addr = inet_addr(fpga_ip_addr);   /* IP address */
	//to_fpga.sin_port = htons(30); //htons(atoi(my_udp_port));       			/* server port */
	to_fpga.sin_port = htons(40);

	from_fpga_len = sizeof(from_fpga);

	/* Construct the client sockaddr_in structure */
	bzero(&from_fpga, sizeof(from_fpga));
	from_fpga.sin_family = AF_INET;
	from_fpga.sin_port = htons(PORT);
	from_fpga.sin_addr.s_addr = htonl(INADDR_ANY);

	if (inet_aton(fpga_ip_addr, &to_fpga.sin_addr)==0)  {
	     std::cerr << "inet_aton() failed with error \n";
	     exit(1);
	}

	if(bind(sockfd_from_fpga, (struct sockaddr*) &from_fpga, sizeof(from_fpga)))
		VLOG(0) << "Error binding the rcv socket\n";
	else
		VLOG(0) << "Rcv binding successful\n";

	/*
	if(bind(sockfd_to_fpga, (struct sockaddr*) &to_fpga, sizeof(to_fpga))==-1)
			VLOG(0) << "Error binding the snd socket\n";
	else
			VLOG(0) << "Snd binding successful\n";
	*/
}

/*
 * Open a new socket to communicate with the FPGA
 *
 */
int FPGAInit()
{
	VLOG(0) << " initializing FPGA \n";
	slen_from_fpga = sizeof(from_fpga);
	slen_to_fpga = sizeof(to_fpga);
	int rc;

	//For testing (Deepak)
	//fpga_server_ip_addr = "10.1.1.1";
	my_udp_port	 = "30";
	//fpga_ip_addr = "10.1.1.2";

	/* Create the UDP socket for receiver */
    if ((sockfd_from_fpga = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
	      std::cerr << "Failed to create rcv socket\n";
	      return 0;
	}
    else {
    	VLOG(0) <<"rcv socket succeed\n";
    }

    /* Create the UDP socket for sender*/
	if ((sockfd_to_fpga = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1) {
	      std::cerr << "failed to crete send socket\n";
	      return 0;
	}
	else {
		VLOG(0) << "snd socket succeed\n";
	}
	//Make the send socket bind to eth0 port
	memset(&ifr, 0, sizeof(ifr));
	    //snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "eth0"); //ethInterface
		snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "eth1"); //deepak - add support for interfaces other than eth0
	    if ((rc = setsockopt(sockfd_to_fpga, SOL_SOCKET, SO_BINDTODEVICE, (void *)&ifr, sizeof(ifr))) < 0)
		//if ((rc = setsockopt(sockfd_to_fpga, SOL_SOCKET, SO_REUSEADDR, (void *)&ifr, sizeof(ifr))) < 0)
	    {
	        VLOG(0) << "Server-setsockopt() error for SO_BINDTODEVICE\n";
	        return 0;
	    }
	    else {
	    	VLOG(0) << "Server-setsockopt() SUCCESS for SO_BINDTODEVICE\n";
	    }

	    VLOG(0)<<"JJJJJJEEEEEEEE\n";

	isSocketActive		=	true;
	isActiveFPGAThread 	= 	true;
	isFPGATerminated 	= 	false;
	packet_count 		= 	0;
	termCheckInProgress = 	false;
	numKeysInTable 		= 	0;
	keysRcvdFromFPGA 	= 	0;
	time_spent			=	0;
	return 1;
}


void sendPacket(char msg[], int totalTransmittedBytes, FPGAMessageType t)
{
	int null_val = 0;

	char *tmp = (char*)&outgoing_msg;

	//VLOG(0) <<" dram address is " << msg[0] << " " << msg[1] << " " << msg[2] << " " << msg[3] << "\n";

	//if (sendto(sockfd_to_fpga, outgoing_msg, OUT_BUFFSIZE, 0, (struct sockaddr*)&to_fpga, slen_to_fpga)==-1)
	int type = (int)t;
	memset(tmp,0,sizeof(outgoing_msg));
	memcpy(tmp,(char*)(&type),sizeof(int)); //insert the command type
	tmp = tmp+sizeof(int)+2;
	memcpy(tmp, msg, totalTransmittedBytes*sizeof(char)); //note we skip 2 bytes after the type to align with 64 bit datapath in hw

	int sendBytes = totalTransmittedBytes*sizeof(char)+sizeof(t)+2;


	//VLOG(0)<<"Send packet port = "<<to_fpga.sin_port<<" Send length = "<<slen_to_fpga<<" bytes = "<<sendBytes<<"\n";

	if (sendto(sockfd_to_fpga, outgoing_msg, sendBytes, 0, (struct sockaddr*)&to_fpga, slen_to_fpga)==-1) {
		VLOG(0) << "send error\n";
	}
	else {
		//VLOG(0) << "Send success\n";
	}
}

/*
int bigToLittle(int num)
{
	//assuming int size is 4 bytes
	return ( (num & 0xff000000)>>24 | (num & 0x00ff0000>>8) | (num & 0x0000ff00<<8) | (num & 0x000000ff<<24) );

}
*/

unsigned int littleToBig(int num)
{
	//			MSB[31:24]			MSB
	return ( ( ((num>>24)&0xff) | ((num<<8)&0xff0000) | ((num>>8)&0xff00) | ((num<<24)&0xff000000) ) );
}

/*
 * Accepts a DRAM address and value - Composes a packet with dram address and value, sends it
 *
 */

void FPGASendKVPair(int key, float val)
{
	//new code
	int totalTransmittedBytes=0;
	char msgbuf[128]; //use smaller packets to send key value pair
	int dram_addr;
	int dram_val;


	if(!isSocketActive) {
			std::cerr << "Socket not active. Returning..";
			return;
	}

	//Why send a value which is 0 ?
	if(val==0 || this->isTerminated()) {
		return;
	}

	//Deepak - just for a santity check - make sure we are not sending any error keys
	//CHECK(key%2==0);
	cout<<"[FPGASend] (K,V) = ("<<key<<"  = "<<((float)val)<<")\n";

	memset(msgbuf,0,sizeof(msgbuf));
	int *tmp = (int*)&msgbuf;
	dram_addr = littleToBig(key);

	int v=(*(int*)&val);
	dram_val  = ( ( ((v>>24)&0xff) | ((v<<8)&0xff0000) | ((v>>8)&0xff00) | ((v<<24)&0xff000000) ) );//littleToBig((int)val);

	memcpy(tmp,&dram_addr,sizeof(int));
	tmp++;
	memcpy(tmp,&dram_val,sizeof(int));
	tmp++;
	totalTransmittedBytes+=(2*sizeof(int));

	//cout<<"FPGA Asst sending DRAM [Key = "<<key<<" DRAM VAL = "<<val<<"] to the FPGA\n";
	//VLOG(0) << "Sending "<<totalTransmittedBytes<<" bytes\n";
	sendPacket(msgbuf,totalTransmittedBytes, WORKER_TO_FPGA_PUT_REQUEST);
}






/*
 * Helper to send a message (command) to the FPGA
 *
 */
void FPGAsendMessage(FPGAMessageType msg)
{
	char msgbuf[OUT_BUFFSIZE];
	memset(&msgbuf,0,sizeof(msgbuf));
	//VLOG(0) << " Sending message "<<msg<<"\n";
	//cout << " Sending message "<<msg<<"\n";
	//std::cout << " Sending message "<<msg<<"\n";
	sendPacket(msgbuf, 4*sizeof(int), msg); //send atleast four ints to confirm to min packet length

}


void FPGAloadDram(vector<fpgaWord>& keys, FPGAMessageType mtype)
{
	int totalTransmittedBytes=0;
	//char msgbuf[OUT_BUFFSIZE];
	char msgbuf[NUM_DATA_BYTES_PER_PACKET];
	unsigned int dram_addr;
	unsigned int dram_val;
	int i=0;

	begin = clock();

	//int numKVs = (OUT_BUFFSIZE-6)/(sizeof(int));
	int num_packet_words = NUM_DATA_BYTES_PER_PACKET/4; //1344/4 = 336 words
	lMessage_t lmsg;

	if(!isSocketActive) {
			std::cerr << "Socket not active. Returning..";
			return;
	}

	i=0;
	//lmsg.cmd = LOAD_DATA;
	lmsg.cmd    = 	mtype;
	lmsg.pad[0] =	0;
	lmsg.pad[1]	=	0;

	//VLOG(0) <<"Size of structure is "<<sizeof(lmsg)<<"\n";
	memset(lmsg.message,0,sizeof(lmsg.message)); //reset 1344 bytes

	int packet_word_cnt = 0;
	//fill address value pairs
	vector<fpgaWord>::const_iterator it=keys.begin();
	for (it=keys.begin(); it!=keys.end(); it++) {
		fpgaWord f = *it;

		lmsg.message[packet_word_cnt]	=  ( ( ((f.addr>>24)&0xff) | ((f.addr<<8)&0xff0000) | ((f.addr>>8)&0xff00) | ((f.addr<<24)&0xff000000) ) ); //littleToBig(f.addr);
		packet_word_cnt++;
		lmsg.message[packet_word_cnt]	=  ( ( ((f.val>>24)&0xff) | ((f.val<<8)&0xff0000) | ((f.val>>8)&0xff00) | ((f.val<<24)&0xff000000) ) ); //littleToBig(f.val);
		packet_word_cnt++;
		//cout<<"Key - "<<f.addr<<" Val - "<<f.val<<"\n";
		//VLOG(0)<<"Packet count is "<<packet_word_cnt<<"\n";
		if(packet_word_cnt==num_packet_words) {
			totalTransmittedBytes = sizeof(lmsg);
			//VLOG(0)<<"Sending packet size is "<<totalTransmittedBytes<<"\n";
			if(mtype==WORKER_TO_FPGA_PUT_REQUEST) {
				int to_port = to_fpga.sin_port;

				//cout<<"[Long packet] Total transmitted bytes are "<<totalTransmittedBytes<<"  socket to port is "<<to_port<<" \n";
				//VLOG(0)<<"[Long packet] Total transmitted bytes are "<<totalTransmittedBytes<<"  socket to port is "<<to_port<<" \n";
			}

			if (sendto(sockfd_to_fpga, (char*)(&lmsg), totalTransmittedBytes, 0, (struct sockaddr*)&to_fpga, slen_to_fpga)==-1) {
					//VLOG(0) << "send error\n";
				//boost::this_thread::sleep(boost::posix_time::milliseconds(2));
			}
			else {
					usleep(150); //sleep for 100 microseconds
					//boost::this_thread::sleep(boost::posix_time::milliseconds(2));
			}
			packet_word_cnt=0;
	   }


	}

	//sleep(0.5);
	//send the last packets
	if(packet_word_cnt!=0) {
		totalTransmittedBytes=(packet_word_cnt*4)+sizeof(lmsg.cmd)+2; //2 is for the zero padding
		//cout<<"Total transmitted bytes are "<<totalTransmittedBytes<<"\n";
		if (sendto(sockfd_to_fpga, (char*)(&lmsg), totalTransmittedBytes, 0, (struct sockaddr*)&to_fpga, slen_to_fpga)==-1) {

			VLOG(0) << "send error\n";
		}
		else {
				//VLOG(0) << "Send success\n";
				//sleep(0.1);
			int to_port = to_fpga.sin_port;
			//cout<<"[Short packet] Total transmitted bytes are "<<totalTransmittedBytes<<"  socket to port is "<<to_port<<" \n";
		}
	}

	/* here, do your time-consuming job */
	end = clock();
	time_spent = (time_spent+((double)(end - begin) / CLOCKS_PER_SEC));

}



/*
 * Accepts a DRAM address and value - Composes a packet with dram address and value, sends it
 */
/*
void FPGAloadDram(unsigned int _dram_addr[], unsigned int _dram_val[])
{
	int totalTransmittedBytes=0;
	char msgbuf[OUT_BUFFSIZE];
	unsigned int dram_addr;
	unsigned int dram_val;

	if(!isSocketActive) {
			std::cerr << "Socket not active. Returning..";
			return;
	}
	memset(msgbuf,0,sizeof(msgbuf));
	unsigned int *tmp = (unsigned int*)&msgbuf;

	for(int i=0;i<FPGA_RECORD_SIZE_IN_WORDS;i++) {
		//VLOG(0) << "Addr = "<<_dram_addr[i] <<" val = "<<_dram_val[i]<<"\n";
		//cout<<"Addr = "<<_dram_addr[i]<<"val = "<<_dram_val[i]<<"\n";



		dram_addr = littleToBig(_dram_addr[i]);
		dram_val  = littleToBig(_dram_val[i]);

		memcpy(tmp,&dram_addr,sizeof(unsigned int));
		tmp++;
		memcpy(tmp,&dram_val,sizeof(unsigned int));
		tmp++;
		totalTransmittedBytes+=(2*sizeof(unsigned int));
	}

	//VLOG(0) << "Sending "<<totalTransmittedBytes<<" bytes\n";
	sendPacket(msgbuf,totalTransmittedBytes, LOAD_DATA);
}
*/

int getTid() {
	return id_;
}

void setTid(int id) {
	id_ = id;
}


bool resetActiveThread(){
	isActiveFPGAThread = false;
}

bool setActiveThread(){
	isActiveFPGAThread = true;
}

void enableFPGAAsst(){
	fpgaAsstStatus = true;
}

void disableFPGAAsst(){
	fpgaAsstStatus = false;
}

bool isFPGAAsstActive(){
	return fpgaAsstStatus;
}

bool isActive() {
	return isActiveFPGAThread;
}

bool isTerminated() {
	return isFPGATerminated;
}

void setTerminated() {
	isFPGATerminated = true;
}

void resetTerminated() {
	isFPGATerminated = false;
}

int getPacketCount() {
	return packet_count;
}

double getTimeSpent() {
	return (double)(time_spent/(double)packet_count);
}


bool isTermCheckInProgress() {
	return termCheckInProgress;
}

void setTermCheckInProgress(bool val) {
	termCheckInProgress = val;
}

int getKeysReturnedFromFPGA() {
	return keysRcvdFromFPGA;
}

void updateKeysReturnedFromFPGA() {
	keysRcvdFromFPGA++;
}

void setNumKeysInFPGA(int numKeys) {
	numKeysInTable = numKeys;
}

int getNumKeysInFPGA() {
	return numKeysInTable;
}

private:
	//CPU worker can act as a server (when recieving messages from the FPGA) or as a client (send messages to FPGA)
	//static const int kMaxHosts = 512;
	//static const int kMaxMethods = 64;
	static const int kMaxReplies = 1000;

	int sockfd_to_fpga;		//sending socket
	int sockfd_from_fpga; 	//receiving socket
	struct sockaddr_in from_fpga; //recv messages sent by fpga
    struct sockaddr_in to_fpga; //send messages to fpga
    struct ifreq ifr;

    socklen_t slen_from_fpga;
    socklen_t slen_to_fpga;
    char *cpu_addr; //specify in dotted decimal notation
    char *my_udp_port; //udp port number
    const char *ethInterface; //specify eth0 or eth1 in the FPGA assistant PC to which the board is connected
    //char fpga_ip_addr[50];
    const char *fpga_ip_addr;
    unsigned int from_fpga_len, to_fpga_len;
    int received;

	bool   isSocketActive;
	bool   isActiveFPGAThread; //we need a variable to keep track if we are an FPGA node or not
	bool   fpgaAsstStatus; //a bool var to keep track if the assistant threads need to be active or not
	bool isFPGATerminated;
	int 	packet_count;
	bool 	termCheckInProgress;
	int 	numKeysInTable;
	int		keysRcvdFromFPGA;

	//Data structure to store the registered callbacks for each message type
	FPGACallbackInfo* fpgacallbacks_[20];

	char outgoing_msg[OUT_BUFFSIZE];
	char incoming_msg[IN_BUFFSIZE]; //buffer to store incoming data
	char static_incoming_msg[IN_BUFFSIZE][RCV_QUEUE_SIZE];
	mutable boost::thread *t_;
	mutable boost::thread *termcheck_reply_process_t_;
	mutable boost::thread *data_reply_process_t_;
	mutable boost::thread *flush_reply_process_t_;
	int id_;

	//using namespace std;
	typedef deque<FPGARPCInfo> Queue; //Since the FPGA is sending fast flush data/other responses, its better to enqueue the responses before processing the data
	//Queue replies[kMaxMethods][kMaxHosts];; // A queue to store all the requests that we receive from the FPGA
	//Queue replies[kMaxReplies]; // A queue to store all the requests that we receive from the FPGA
	Queue termcheckReplies; //Queue handles TERMCHECK messages from FPGA - This queue has a higher priority
	Queue dataReplies;
	Queue flushReplies;
	mutable boost::recursive_mutex q_lock; // a mutex for the rcv queue

	void InvokeCallback(FPGACallbackInfo *ci, FPGARPCInfo rpc);

	clock_t begin, end;
	double time_spent;

}; //end class fpga

#ifndef SWIG
//reusing the template from rpc.h
template <class Request, class Response, class Function, class Klass>
void FPGAregisterCallback(int req_type, Request *req, Response *resp, Function function, Klass klass) {
  FPGAThread::Get()->_RegisterCallback(req_type, req, resp, boost::bind(function, klass, boost::cref(*req), resp, _1));
}

#endif


}//end namespace

#endif // FPGA_H
