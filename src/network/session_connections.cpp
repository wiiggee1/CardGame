#pragma once

#include <boost/asio/buffer.hpp>
#include <boost/asio/error.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/local/stream_protocol.hpp>
#include <boost/asio/write.hpp>
#include <boost/date_time/time_clock.hpp>
#include <boost/system/detail/error_code.hpp>
#include <cstddef>
#include <cstdint>
#include <ctime>
#include <format>
#include <iostream>
#include "network/session_connections.hpp"
#include "network/message.hpp"

namespace Core {
    namespace Network {

        using boost::asio::ip::tcp;
        using boost::asio::buffer;

        SessionConnection::SessionConnection(tcp::socket socket, Server& server)
            : tcp_socket(std::move(socket)), server_ref(server){
            
                // Constructor body here...
        }

        void SessionConnection::start_reading(){
            
            auto self = shared_from_this();  // Keep the connection alive during the async operation
            
            auto read_handler_lambda = [this, self](const boost::system::error_code errcode, size_t byte_size){
                if (!errcode && byte_size > 0){
                    std::time_t now = std::time(0);
                    //std::string received_data(socket_buffer, byte_size);
                    std::string received_data(socket_buffer, this->socket_buffer+byte_size);
                    std::vector<uint8_t> received_bytes(this->socket_buffer, this->socket_buffer+byte_size);

                    //std::cout << get_endpoint_stringz() << received_data << std::endl;
                    //std::cout << get_endpoint_stringz() << std::endl;
                    //std::cout << std::setw(1) << std::left << ANSI_BOLD <<  get_endpoint_stringz() << ANSI_COLOR_RESET << "\n" <<  std::endl;
                    std::cout << std::setw(1) << std::left << ANSI_BOLD << ANSI_COLOR_GREEN <<  get_endpoint_stringz() << ANSI_COLOR_RESET << "" <<  std::endl;
                    
                    print_bytemessage(received_bytes);

                    // TODO: Add message handler processing of incoming requests below...
                    // Add here... 
                   
                    //WARN: Only for testing sending back response to the client sender. 
                    auto msg = deserialize_message(received_bytes);
                    msg.type = MessageType::Response;
                    msg.payload = "Received OK";
                    
                    auto response_msg = serialize_message(msg);
                    write_to_client(response_msg);
                    
                
                }else if (errcode == boost::asio::error::eof){
                    std::cout << "Client socket " << get_endpoint_stringz() << ", disconnected!" << std::endl;
                }else {
                    std::cerr << "Received Error: " << errcode.message() << std::endl;
                }

                // Continue reading from the socket... Recalling itself!
                start_reading();
                
            };
            /* Completion token, is the final argument to an asynchronous operation's initiating function.
             * E.g., if the user passes a lambda (or function object) as the completion token, the asynchronous operation begins and when completed the result is passed to the lambda.
             *
             * Reference: https://beta.boost.org/doc/libs/1_82_0/doc/html/boost_asio/overview/model/completion_tokens.html 
             * */
            this->tcp_socket.async_read_some(buffer(this->socket_buffer, 1024), read_handler_lambda);
            
        
        }

        void SessionConnection::write_to_client(const std::vector<uint8_t>& response_msg){
            std::cout << "Trying to call `write_to_client`" << std::endl; 
            auto write_handler = [this](const boost::system::error_code& errcode, std::size_t byte_size){
                if(!errcode && byte_size > 0){
                    std::cout << "Message was successfully sent to the client" << std::endl;
                }else {
                    std::cerr << "Error sending to client, with error: " << errcode.message() << std::endl;
                }
            };

            boost::asio::async_write(
                    this->tcp_socket, 
                    boost::asio::buffer(response_msg), 
                    write_handler);
        }

        std::string SessionConnection::get_endpoint_stringz(){
            auto client_endpoint = std::format("[{}:{}]: ",
                    tcp_socket.remote_endpoint().address().to_string(), 
                    tcp_socket.remote_endpoint().port()
            );
            return client_endpoint;
        }
       

           
    }
}
