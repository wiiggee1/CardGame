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
#include <string>
#include "network/session_connections.hpp"
#include "events.hpp"
#include "game.hpp"
#include "network/message.hpp"

namespace Core {
    namespace Network {

        using boost::asio::ip::tcp;
        using boost::asio::buffer;

        SessionConnection::SessionConnection(tcp::socket socket, Server& server)
            : tcp_socket(std::move(socket)), server_ref(server){
                this->connection_id = (unsigned short)this->tcp_socket.remote_endpoint().port();
                std::cout << "New SessionConnection was created with ID: " << connection_id << std::endl;
        }

        void SessionConnection::start_reading(){
            
            auto self = shared_from_this();  // Keep the connection alive during the async operation
            
            auto read_handler_lambda = [this, self](const boost::system::error_code errcode, size_t byte_size){
                if (!errcode && byte_size > 0){
                    std::time_t now = std::time(0);
                    //std::string received_data(socket_buffer, byte_size);
                    std::string received_data(socket_buffer, this->socket_buffer+byte_size);
                    std::vector<uint8_t> received_bytes(this->socket_buffer, this->socket_buffer+byte_size);

                    
                    std::cout << std::setw(1) << std::left << ANSI_BOLD << ANSI_COLOR_GREEN <<  get_endpoint_stringz() << ANSI_COLOR_RESET << "" <<  std::endl;
                    
                    //print_bytemessage(received_bytes);

                    //WARN: Only for testing sending back response to the client sender. 
                    auto msg = deserialize_message(received_bytes);
                    

                    // USE THIS as unique ID for pushing to the EventHandler queue. 
                    
                    handle_request(msg); 
                    //trigger_callback(Gameplay::Event::);
                    
                    //auto response_msg = serialize_message(msg);
                    //write_to_client(response_msg);
                    
                
                }else if (errcode == boost::asio::error::eof){
                    std::cout << "Client socket " << get_endpoint_stringz() << ", disconnected!" << std::endl;
                }else {
                    std::cerr << "Received Error: " << errcode.message() << std::endl;
                }

                // Continue reading from the socket... Recalling itself!
                //start_reading();
                if (!errcode) {
                    start_reading();
                } else {
                    std::cout << "[DEBUG] Not continuing read due to error: " << errcode.message() << std::endl;
                }
                
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

        void SessionConnection::handle_request(const Message& message){
            auto event_queue = Core::Game::getEventHandler();
            
            switch (message.rpc_type){
                case Core::Network::RPCType::NewConnection: {
                    std::cout << "RPC NewConnection" << std::endl;
                    //event_queue->store_eventmessage(Gameplay::Event::GameStarted, message);
                    break; 
                }
                case Core::Network::RPCType::StartGame: {
                    //event_queue->push_event(Gameplay::Event::GameStarted);
                    std::cout << "RPC StartGame" << std::endl;
                    event_queue->store_eventmessage(Gameplay::Event::GameStarted, message);
                    break;
                }
                case Core::Network::RPCType::NewRound: {
                    //event_queue->push_event(Gameplay::Event::GameStarted);
                    event_queue->store_eventmessage(Gameplay::Event::NextRound, message);
                    break;
                }                                        
                case Core::Network::RPCType::DealCard: {
                    //event_queue->push_event(Gameplay::Event::CardRequest);
                    std::cout << "RPC DealCard" << std::endl;
                    event_queue->store_eventmessage(Gameplay::Event::CardRequest, message);
                    break;
                }
                case Core::Network::RPCType::LoadGame: {
                    event_queue->store_eventmessage(Gameplay::Event::SynchronizeGame, message);
                    break;
                }
                case Core::Network::RPCType::EnterWaiting: {
                    break;
                }                                       
                case Core::Network::RPCType::PlayCard: {
                    //event_queue->push_event(Gameplay::Event::CardReceived);
                    event_queue->store_eventmessage(Gameplay::Event::CardPlayed, message);
                    break;
                }
                case Core::Network::RPCType::Vote: {
                    event_queue->store_eventmessage(Gameplay::Event::JudgeVoted, message);
                    break;
                }
                case Core::Network::RPCType::DontCare: {
                    //event_queue->store_eventmessage(Gameplay::Event::NetworkMessage, DontCare(unsigned short msg_id));
                    break;
                }
            }
        }
       

           
    }
}
