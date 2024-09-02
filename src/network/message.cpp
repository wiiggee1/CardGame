#pragma once

#include <cstdint>
#include <cstring>
#include <format>
#include <iomanip>
#include <sstream>
#include <iostream>
#include <cstddef>
#include <string>
#include "network/message.hpp"
#include <boost/asio/buffer.hpp>
#include <vector>


namespace Core {
    namespace Network {

        using namespace boost::asio::buffer_literals;
       
        std::vector<uint8_t> serialize_message(const Message& message){
            
            auto header_bytesize = sizeof(message.type) + sizeof(message.rpc_type);
            auto payload_size = message.payload.size();
            std::vector<uint8_t> sending_buffer(header_bytesize + sizeof(uint32_t) + payload_size);
            
            /**
             * void* memcpy( void* dest, const void* src, std::size_t count );
             * Copies count bytes from the object pointed to by src to the object pointed to by dest. 
             * Both objects are reinterpreted as arrays of unsigned char
             */
            std::memcpy(sending_buffer.data(), &message.type, sizeof(message.type));
            std::memcpy(sending_buffer.data() + sizeof(message.type), &message.rpc_type, sizeof(message.rpc_type));
            std::memcpy(sending_buffer.data() + header_bytesize, &payload_size, sizeof(uint32_t));
            std::memcpy(sending_buffer.data() + header_bytesize+sizeof(uint32_t), message.payload.data(), payload_size);

            //TODO: How should I deserialize the sequence of byte of std::vector<uint8_t> to std::string?
            //std::string payload_data(sending_buffer.data()+header_bytesize, message.payload.size()); 

            const unsigned char* msgtype_data = static_cast<const unsigned char*>(sending_buffer.data());
            const unsigned char* rpctype_data = static_cast<const unsigned char*>(sending_buffer.data()+sizeof(message.type));
            //const unsigned char* payload_data = static_cast<const unsigned char*>()

            //print_subsection("Message struct before serialization", "", ANSI_BOLD_BLUE, ANSI_COLOR_RESET);
            print_message(message);
            //print_bytemessage(sending_buffer);

            std::cout << "\nThe serialized message as byte array: " << std::endl;
            std::cout << "[";            
            for (uint8_t byte : sending_buffer) {
                //std::cout << static_cast<char>(byte);
                std::cout << static_cast<int>(byte) << " ";
            }
            std::cout << "]" << std::endl;       
            

            return sending_buffer;
        }


        Message deserialize_message(const std::vector<uint8_t>& data_bytes){
            Message msg;
            size_t header_bytesize = sizeof(msg.type) + sizeof(msg.rpc_type);
            uint32_t payload_size;

            //const unsigned char* byte_as_char = static_cast<const unsigned char*>(data_bytes.data());
            std::string byte_as_str(data_bytes.begin(), data_bytes.end());
            std::vector<uint8_t> header_slice(data_bytes.begin(), data_bytes.begin() + header_bytesize);

            std::memcpy(&msg.type, data_bytes.data(), sizeof(msg.type));
            std::memcpy(&msg.rpc_type, data_bytes.data() + sizeof(msg.type), sizeof(msg.rpc_type));
            std::memcpy(&payload_size, data_bytes.data() + header_bytesize, sizeof(uint32_t));

            std::string payload_slice(data_bytes.begin() + header_bytesize + sizeof(uint32_t), data_bytes.end());
            std::string payload_slicez(data_bytes.begin() + header_bytesize + sizeof(uint32_t), data_bytes.begin() + header_bytesize + sizeof(uint32_t) + payload_size);

            msg.payload = payload_slice;
            //std::cout << "Received Message struct after deserialization: " << std::endl;  
            //print_subsection("Received Message struct after deserialization", "", ANSI_BOLD_BLUE, ANSI_COLOR_RESET);
            print_message(msg);

            return msg;
        }

        void print_message(const Message &msg){
            //std::cout << "MessageType: " << static_cast<int>(msg.type) << std::endl;
            //std::cout << "RPCType: " << static_cast<int>(msg.rpc_type) << std::endl;
            //std::cout << "Payload: " << msg.payload << std::endl;
            const std::string title_colorcode = ANSI_BOLD_CYAN;
            const std::string content_colorcode = ANSI_COLOR_WHITE;
            
            print_subsection("MsgType", 
                    std::to_string(static_cast<int>(msg.type)), 
                    title_colorcode,
                    content_colorcode);
            
            print_subsection("RPCType", 
                    std::to_string(static_cast<int>(msg.rpc_type)),
                    title_colorcode,
                    content_colorcode);
            
            print_subsection("Payload", 
                    msg.payload,
                    title_colorcode,
                    content_colorcode);

            //std::string hex_value = std::format("{:02X}", static_cast<unsigned char>(char_byte));
            //std::cout << "Char: " << char_byte << ", Hex (byte value): 0x" << hex_value << std::endl;
        }

        void print_subsection(const std::string &title, std::string content, const std::string &title_color = ANSI_BOLD, const std::string &content_color = ANSI_COLOR_RED){

            std::istringstream iss(content);
            std::string line;
            std::cout << std::setw(10) << std::left << title_color << title << ": " << ANSI_COLOR_RESET;

            while (std::getline(iss, line)) {
                //std::cout << std::setw(15) << ANSI_COLOR_RED << line << ANSI_COLOR_RESET << std::endl;
                if (!content.empty()){
                    std::cout << std::setw(15) << content_color << line << ANSI_COLOR_RESET << std::endl;
                }
            }
        }

        std::string get_string_message(const Message &message){
            std::string msg_str = std::format("MessageType: {}\nRPCType: {}\nPayload: {}",
                    static_cast<int>(message.type), 
                    static_cast<int>(message.rpc_type), 
                    message.payload);
            return msg_str;
        }

        void print_bytemessage(const std::vector<uint8_t> &data_bytes){
            std::ostringstream oss;
            const int bytes_per_line = 16; 

            oss << "[";
            for (size_t i = 0; i < data_bytes.size(); ++i) {
                oss << static_cast<int>(data_bytes[i]) << " ";
                if ((i + 1) % bytes_per_line == 0) {
                    int title_content_width = 10+15+6;
                    oss << "...\n" << std::setw(title_content_width) << "... ";
                }
            }
            oss << "]" << std::endl;
            
            std::string byte_message = oss.str();
            
            const std::string title_colorcode = ANSI_BOLD_YELLOW;
            const std::string content_colorcode = ANSI_COLOR_WHITE;
            
            print_subsection("Byte array of size", 
                    std::to_string(data_bytes.size()),
                    title_colorcode,
                    content_colorcode);            
            
            print_subsection("Received Byte array", 
                    byte_message,
                    title_colorcode,
                    content_colorcode);
        }
    }
}
