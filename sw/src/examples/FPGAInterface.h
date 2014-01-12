/* ---------------------------------------------------------------------------
** This software is in the public domain, furnished "as is", without technical
** support, and with no warranty, express or implied, as to its usefulness for
** any purpose.
**
** FPGAInterface.h
** <FPGA Interface - Provides APIs to transmit table values (key,value pairs to
** FPGA worker>
**
** Author: <Deepak Unnikrishnan>
** -------------------------------------------------------------------------*/


#include <iostream>
#include <deque>
#include <boost/array.hpp>
//#include <boost/bind.hpp>
#include <boost/asio.hpp>
//#include <boost/thread.hpp>
#include <boost/lexical_cast.hpp>
#include <stdio.h>
#include <sstream>
#include <iomanip>
//#include "fpga_message.h"

#define SIZE_OF_INT 4 //in bytes


//Total packet payload size will be 42 * 8 * sizeof(int) (excluding ip/udp header)
#define MESSAGE_BYTES 1280 //Bytes available for payload data including node ID and command (1280bytes - 8 bytes (command) - 8 bytes (node ID) = 1264 bytes (ie. 158 ints)
#define COMMAND_BYTES (8*SIZE_OF_INT) //33 bytes in 32 bit platform
#define NODE_ID_BYTES (8*SIZE_OF_INT)
#define VECTOR_BYTES  (8*SIZE_OF_INT)
#define HEADER_BYTES  (COMMAND_BYTES+NODE_ID_BYTES)


#define WORDS_IN_MSG_PKT MESSAGE_BYTES/VECTOR_BYTES
#define END_WORD 0xFFFFFFFF //A word that indicates end of vector
#define BREAK_WORD 0xFFFFFFFE //A word that indicates rest of link vector continues in the following packet
using boost::asio::ip::udp;

enum FPGAMessageType {
	ERROR					=-1,
	FPGA_PUT_REQUEST_KV 	= 1,
	FPGA_READ_REQUEST_KV 	= 2,
	WNODE_PUT_REQUEST_KV 	= 4,
	WNODE_GET_REQUEST_KV	= 8,
	FPGA_START_COMPUTATION_REQUEST 	= 16,
	FPGA_STOP_COMPUTATION_REQUEST   = 32,
	FPGA_DIR_INFO			= 64,
};

/*
 * PACKET FORMATS
 *
 * FPGA_PUT_REQUEST_KV
 * *******************
 * Sent by:			Worker
 * Received by:		FPGA
 * Sent packet: 	[FPGA_PUT_REQUEST][NODE_ID][LINK1, LINK2,......]
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will update it's local table with nodeId and link information
 *
 * FPGA_READ_REQUEST
 * *******************
 * Sent by:			Worker
 * Received by:		FPGA
 * Sent packet: 	[FPGA_READ_REQUEST]
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will make packets for each entry in the table and send it to manage node
 *
 * FPGA_READ_KV
 * ********************
 * Sent by:			FPGA
 * Received by:		Worker (Dummy)
 * Sent packet: 	[FPGA_READ_KV][NODE_ID]
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will make packets for each entry in the table and send it to manage node
 *
 *
 * WNODE_PUT_REQUEST_KV
 * ********************
 * Sent by:			FPGA
 * Received by:		Worker
 * Sent packet: 	[WNODE_PUT_REQUEST_KV][NODE_ID][LINK1, LINK2,......]
 * Return Expected: No
 * Desc: 			FPGA will populate the packet and and send it with the worker node's ID
 *
 * FPGA_START_COMPUTATION
 * **********************
 * Sent by:			Worker
 * Received by:		FPGA
 * Sent packet: 	[FPGA_START_COMPUTATION_REQUEST]
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will start the iterative computation procedure
 *
 * FPGA_STOP_COMPUTATION
 * **********************
 * Sent by:			Worker
 * Received by:		FPGA
 * Sent packet: 	[FPGA_STOP_COMPUTATION_REQUEST]
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will stop the iterative computation procedure
 *
 * FPGA_DIR_INFO
 * *************
 * Sent by:			Worker (Manage node)
 * Received by:		FPGA
 * Sent packet: 	[FPGA_DIR_INFO][NUM_WORKERS][WORKER1][IP_ADDR][WORKER2][IP_ADDR2]...
 * Return Expected: No
 * Desc: 			When this request is received by FPGA, FPGA will populate it's internal directory of other worker nodes
 *
 *
 */



//APIs to operate on packet data

/*Returns a string of packet message from the packet*/
/*
 * @func: encodeToString
 * @desc: Constructs and returns a packet message
 * Packet format is
 * [COMMAND(4 bytes)][NODEID(4 bytes)][MESSAGE(360 bytes)]
 *
 */
std::string encodeToString(FPGAMessageType command, int nodeId, std::vector<int> links, bool isFinal) {
	using namespace std;

	// For sprintf and memcpy.
	//char message[HEADER_BYTES + MESSAGE_BYTES + 1];

	std::ostringstream oss(std::ostringstream::out);
	oss << std::setw(COMMAND_BYTES) << std::setfill('0') << command << std::setw(NODE_ID_BYTES) << std::setfill('0') << nodeId;

	vector<int>::iterator it;
	for (it=links.begin(); it!=links.end(); it++) {
		cout<<" Link value is "<<*it<<" \n";
		oss << std::setw(VECTOR_BYTES) << std::setfill('0') << *it;
	}

	if(!isFinal)
		oss << endl;
	else
		oss << std::setw(VECTOR_BYTES) << std::setfill('0') << END_WORD;

	std::string message = oss.str();

	return message;

}

/*
 * @func: decodeCommand
 * @desc: Reconstructs the command from the message (first 4 bytes)
 *
 */
FPGAMessageType decodeCommand(std::string message) {
	using namespace std;
	istringstream buffer(message.substr(0,COMMAND_BYTES));
	int command;
	buffer >> command;

	if(command==FPGA_PUT_REQUEST_KV) {
		cout<<"Received a put request \n";
		return FPGA_PUT_REQUEST_KV;
	}
	else if(command==FPGA_READ_REQUEST_KV) {
		cout<<"Received a read request \n";
		return FPGA_READ_REQUEST_KV;
	}
	else {
		cout<<"Received an error \n";
		return ERROR;
	}

}

/*
 * @func: decodeNodeId
 * @desc: Reconstructs the nodeId from the message (bytes 4-8 in message)
 *
 */
int decodeNodeId(std::string message) {
	using namespace std;
	istringstream buffer(message.substr(0+COMMAND_BYTES,NODE_ID_BYTES));
	int nodeId;
	buffer >> nodeId;
	cout<<"Received node id is "<< nodeId <<"\n";
	return nodeId;
}

/*
 * @func: decodeLinks
 * @desc: Reconstructs the link vector from the message (bytes 8 onwards..)
 *
 */
std::vector<int> decodeLinks(std::string message) {
	using namespace std;
	unsigned int link, i=0;
	vector<int> links;
	links.clear();

	while(true) {

		istringstream buffer(message.substr(HEADER_BYTES+i*VECTOR_BYTES,VECTOR_BYTES));
		buffer >> link;

		if(link==END_WORD || link==BREAK_WORD)
			break;
		else {
			cout<<"Received Link is "<<link<<"\n";
			links.push_back(link);
		}
		i=i+1;
	};
	return links;
}

/*
 * @func: getTransmitMessages
 * @desc: Given a Key value table entry, return a vector of
 * messages to be transmitted to fpga node
 *
 */
std::vector<std::string> getTransmitMessages(int nodeId, std::vector<int> links) {

	using namespace std;
	//First determine how many messages will this row need to be encoded
	int totalLinks = links.size();
	int availableBytes = MESSAGE_BYTES - HEADER_BYTES;

	//Calculate links per packet
	int maxLinksPerPacket = (MESSAGE_BYTES-HEADER_BYTES)/VECTOR_BYTES;
	int maxPackets = totalLinks*VECTOR_BYTES/availableBytes;
	int linksInLastPacket = totalLinks*VECTOR_BYTES%availableBytes;

	std::vector<std::string> messages;
	messages.clear();

	std::cout<<"Maximum links per packet is "<<maxLinksPerPacket<<"\n";

	std::ostringstream oss(std::ostringstream::out);
	oss.clear();

	std::vector<int>::iterator it;
	int vector_count=0;
	FPGAMessageType command = FPGA_PUT_REQUEST_KV; //hardcode for now

	for (it=links.begin(); it!=links.end(); it++) {
		//Insert a header everytime a new packet starts
		if(vector_count==0) {
			cout<<" Starting a new packet..\n";
			oss << std::setw(COMMAND_BYTES) << std::setfill('0') << command << std::setw(NODE_ID_BYTES) << std::setfill('0') << nodeId;
			oss << std::setw(VECTOR_BYTES) << std::setfill('0') << *it;
			vector_count++;
		}
		//If the given packet is full, the message is complete and save it into array to be returned
		else if(vector_count==(maxLinksPerPacket-1)) {
			//cout<<" Link value is "<<*it<<" \n";
			cout<<" Packet is full\n";
			oss << std::setw(VECTOR_BYTES) << std::setfill('0') << BREAK_WORD;

			//Save message and reset the stream
			std::string msg = oss.str();
			messages.push_back(msg);
			vector_count = 0;
			oss.clear();
		}
		else {
			cout<<"Appending vector "<<vector_count<<"\n";
			oss << std::setw(VECTOR_BYTES) << std::setfill('0') << *it;
			vector_count++;
		}

	}//end for

	//If we reached end of packet, insert the END_WORD and save the message into array to be returned
	if (it == links.end()) {
		oss << std::setw(VECTOR_BYTES) << std::setfill('0') << END_WORD;

		//Save message and reset the stream
		std::string msg = oss.str();
		messages.push_back(msg);
		vector_count = 0;
		oss.clear();
	}

	return messages;
}


/*
 * @func: sendToFPGA
 * @desc: API Interface to send a key value table entry to the FPGA
 * worker node. Internally, this API will open a UDP socket, packetize
 * the table entry and push all packets through the socket
 *
 */
int sendToFPGA(int node, std::vector<int> links) {
	//fpga_message msg;

	try {
		//std::cerr << "Usage: chat_client <host> <port>\n";

		boost::asio::io_service io_service;
		char host[10] = "localhost";
		char port[10] = "1000";

		udp::resolver resolver(io_service);
		udp::resolver::query query(udp::v4(), host, port);
		udp::endpoint receiver_endpoint = *resolver.resolve(query);

		udp::socket socket(io_service);
		socket.open(udp::v4());

		//boost::array<char, 1450> send_buf = { node };//{0};
		//string send_data = boost::lexical_cast<string>(node);
		std::vector<std::string> packets;
		packets.clear();

		packets = getTransmitMessages(node,links);

		std::cout << "Sending to FPGA value is " << node << "\n";//<< " and the data is <<" << send_data << "\n";

		for(unsigned int i=0;i<packets.size();i++) {
			std::string packet = packets.at(i);
			std::cout << "Packet ["<<i<<"]\n";//data is " << packet << "\n";
			socket.send_to(boost::asio::buffer(packet), receiver_endpoint);
			sleep(1);
		}
		//udp::resolver::iterator iterator = resolver.resolve(query);

		//fpga_client c(io_service, iterator);

		//boost::thread t(boost::bind(&boost::asio::io_service::run, &io_service));

		//char line[fpga_message::max_body_length + 1];
		//line = "Hello World";

		/*
		 while (std::cin.getline(line, fpga_message::max_body_length + 1))
		 {
		 using namespace std; // For strlen and memcpy.
		 fpga_message msg;
		 msg.body_length(strlen(line));
		 memcpy(msg.body(), line, msg.body_length());
		 msg.encode_header();
		 c.write(msg);
		 }
		 */

		//c.close();
		//t.join();
	} catch (std::exception& e) {
		std::cerr << "Exception: " << e.what() << "\n";
	}

	return 0;

}
