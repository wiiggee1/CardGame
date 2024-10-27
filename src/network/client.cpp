#pragma once

#include "events.hpp"
#include "game.hpp"
#include "network/message.hpp"
#include "network/network_component_interface.hpp"
#include <array>
#include <boost/asio/buffer.hpp>
#include <boost/asio/connect.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/local/stream_protocol.hpp>
#include <boost/asio/read.hpp>
#include <boost/asio/write.hpp>
#include <boost/system/detail/error_code.hpp>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <string>
#include "network/client.hpp"

namespace Core {
    namespace Network {
       
        Client::Client(boost::asio::io_context& ctx, const std::string& host, unsigned short port) : io_ctx(ctx), client_socket(ctx){
            
            // Default constructor, that initialize the io_context and socket class objects.
            
            boost::asio::ip::tcp::resolver rslv(ctx);
            boost::asio::ip::tcp::resolver::results_type endpoints;
            boost::system::error_code errcode;
            auto socket_err = client_socket.open(boost::asio::ip::tcp::v4(), errcode);

            if (!socket_err) {
                try {
                    boost::asio::connect(client_socket, rslv.resolve(host, std::to_string(port)));

                    auto local_endpoint = client_socket.local_endpoint();
                    auto addr = local_endpoint.address().to_string();
                    auto port = local_endpoint.port();
                    this->client_id = (unsigned short)port;

                    std::cout << "Client created, with Local Endpoint: " << addr+":" << port << std::endl;
                    std::cout << "Connected to Server Endpoint: " << get_endpoint_string(client_socket) << std::endl;
                    

                }catch(boost::system::error_code& connection_error) {
                    std::cerr << "Error Connecting to Server: " << connection_error.message() << std::endl;
                } 
            }
            else {
                std::cerr << "Error opening socket: " << socket_err.message() << std::endl;
            }

        }
                
        void Client::initialize(){
            std::cout << "initialize (client class) - starting the async start_reading() loop now!" << std::endl; 
            start_reading();
        }

        void Client::run(){
            try {
                this->io_ctx.run();
                //this->io_ctx.poll();
            } catch (boost::system::error_code& errcode) {
                std::cerr << "IO Context 'run() method got error: " << errcode << std::endl;
            }
        }

        void Client::handle_message(const Core::Network::Message& message){
            /* Map external RPC message events to internal events, and add to shared event queue. */ 
            auto event_queue = Core::Game::getEventHandler();
            switch (message.rpc_type){
                case Core::Network::RPCType::NewConnection: {
                    //event_queue->push_event(Gameplay::Event::PlayerJoined); 
                    event_queue->store_eventmessage(Gameplay::Event::PlayerJoined, message);
                    break; 
                }
                case Core::Network::RPCType::StartGame: {
                    //event_queue->push_event(Gameplay::Event::GameStarted);
                    event_queue->store_eventmessage(Gameplay::Event::GameStarted, message);
                    break;
                }
                                                     
                case Core::Network::RPCType::NewRound: {
                    //event_queue->push_event(Gameplay::Event::GameStarted);
                    event_queue->store_eventmessage(Gameplay::Event::NextRound, message);
                    break;
                }
                case Core::Network::RPCType::DealCard: {
                    //event_queue->push_event(Gameplay::Event::CardReceived);
                    //event_queue->store_message(message);
                    std::cout << "RPC DealCard" << std::endl;
                    event_queue->store_eventmessage(Gameplay::Event::CardReceived, message);
                    break;
                }
                case Core::Network::RPCType::LoadGame: {
                    //event_queue->push_event(Gameplay::Event::SynchronizeGame);
                    event_queue->store_eventmessage(Gameplay::Event::SynchronizeGame, message);     
                    break;
                }
                case Core::Network::RPCType::EnterWaiting: {
                    break;
                }                                       
                case Core::Network::RPCType::PlayCard: {
                    break;
                }
                case Core::Network::RPCType::Vote: {
                    event_queue->store_eventmessage(Gameplay::Event::StartVote, message);     
                    break;
                }
                case Core::Network::RPCType::DontCare: {
                    event_queue->store_eventmessage(Gameplay::Event::NetworkMessage, message);     
                    break;
                }                                   
            }
        }


        void Client::send_message(const std::string& msg_payload){

            auto write_handle = [this](const boost::system::error_code& errcode, std::size_t bytes_to_send){
                if (!errcode && bytes_to_send > 0){
                    std::cout << "Message was sent to the server, with no errors!" << std::endl;
                }else {
                    std::cerr << "Error sending message to the server: " << errcode.message() << std::endl;
                }
            };

            boost::asio::async_write(
                    this->client_socket, 
                    boost::asio::buffer(msg_payload), 
                    write_handle);
        }

        void Client::send_message_test(const std::vector<uint8_t>& msg_payload){
            auto write_handle = [this](const boost::system::error_code& errcode, std::size_t bytes_to_send){
                if (!errcode && bytes_to_send > 0){
                    std::cout << "Message was sent to the server, with no errors!" << std::endl;
                }else {
                    std::cerr << "Error sending message to the server: " << errcode.message() << std::endl;
                }
            };

            boost::asio::async_write(
                    this->client_socket, 
                    boost::asio::buffer(msg_payload), 
                    write_handle); 
        }


        void Client::connect(){

        }

        void Client::start_reading(){
            //TODO: 
            //  1. Define and use the `async_read`
            //  2. Pass socket, buffer and std::bind or lambda for callback handling of the async read.  
          
            // Is the below neccessary to pass to the capture block of the below lambda handler? 
            //auto self = shared_from_this();  // Keep the connection alive during the async operation

            auto read_handler = [this](const boost::system::error_code& errcode, std::size_t byte_size){
                if(!errcode && byte_size > 0){
                    //std::string received_data(this->client_buffer, byte_size);
                    std::string received_data(this->client_buffer, this->client_buffer+byte_size);
                    std::vector<uint8_t> received_bytes(this->client_buffer, this->client_buffer+byte_size);

                    std::cout << std::setw(1) << std::left << ANSI_BOLD << ANSI_COLOR_GREEN << get_endpoint_string(this->client_socket) << ANSI_COLOR_RESET << "" <<  std::endl;
                    
                    //std::cout << get_endpoint_string(this->client_socket) << std::endl;
                    //std::cout << get_endpoint_string(this->client_socket) << received_data << std::endl;

                    print_bytemessage(received_bytes); 
                    auto msg = deserialize_message(received_bytes);
                    handle_message(msg);

                }else {
                    std::cerr << errcode.message() << std::endl;
                }
                
                // Recursively call itself for continously reading data from the established socket connection.
                start_reading();
            };

            this->client_socket.async_read_some(boost::asio::buffer(this->client_buffer, 1024), read_handler);
            //boost::asio::async_read(client_socket, boost::asio::buffer(client_buffer, 1024))
        }

           
    }
}
