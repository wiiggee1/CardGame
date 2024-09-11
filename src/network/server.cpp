#pragma once

#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "network/session_connections.hpp"
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/local/stream_protocol.hpp>
#include <cstdint>
#include <iostream>
#include <memory>
#include "network/server.hpp"

namespace Core {
    namespace Network {

        using boost::asio::ip::tcp;
        using boost::asio::io_context;
        //Server(boost::asio::io_context& io_context, boost::asio::ip::tcp::endpoint srv_endpoint);

        Server::Server(io_context& iocontext, tcp::endpoint srv_endpoint)
            : host_io_context(iocontext), conn_acceptor(iocontext, srv_endpoint)
        {
         
            uint16_t port = 2048;
            auto endpoint = tcp::endpoint(tcp::v4(), port);

            tcp::endpoint local_endpoint = conn_acceptor.local_endpoint();
            std::cout <<"Server initialized, and listening on: "<< local_endpoint.address().to_string()+":"<<local_endpoint.port()<< std::endl;
            
        }
        
        void Server::initialize(){
            // Runs the neccessary asynchronous server operations
            // WARN: Should be called before Server::run() and io_context.run()!
            std::cout << "initialize (server class) - starting the async listen() loop now!" << std::endl; 
            listen();
        }

        void Server::run(){
            //More info at: https://live.boost.org/doc/libs/1_85_0/doc/html/boost_asio/reference/io_context.html
            try {
                this->host_io_context.run();
                //this->host_io_context.poll();
                //this->host_io_context.post();
            } catch (boost::system::error_code& errcode) {
                std::cerr << "IO Context 'run() method got error: " << errcode << std::endl;
            }
        }
        
        void Server::handle_message(const Core::Network::Message& message){

        }


        void Server::send_message(const std::string& msg_payload){
            std::cout << "This shouldnt be manually controlled, but will send message, to all of the clients" << std::endl;
            for (auto client: this->clients){
                //client->write_to_client(msg_payload);
            }
        }

        void Server::listen(){

            /* Lambda function handler - callable object for handling new server connections */
            auto conn_handle_lambda = [this](boost::system::error_code errcode, tcp::socket socket){
                if (!errcode){
                    auto connection_endpoint = socket.remote_endpoint();
                    auto remote_addr = connection_endpoint.address().to_string();
                    auto remote_port = connection_endpoint.port();
                    std::cout << "New connection session from: " << remote_addr+":" << remote_port << "\n";
                        
                    auto new_connection = std::make_shared<SessionConnection>(std::move(socket), *this);
                    clients.push_back(new_connection);


                    this->trigger_event(); // This triggers the event of a new client has connected, and will call the Game class callback method. 
                
                    /* Callback that is triggered whenever a distinct socket receives a client request. This callback would push the new event to the queue. Which is processed in the gameloop. */
                    new_connection->set_callback([this](Gameplay::Event event){
                        this->event_queue->push_event(event);
                    });

                    new_connection->start_reading();
                        
                }
                listen();
            };

            /* boost asio 'async_accept' takes a lambda handler as argument. 
             * It will automatically pass the necessary arguments to the handler.*/
            conn_acceptor.async_accept(conn_handle_lambda);

            /* Same as above but with std::bind instead of lambda expression:
                acceptor_.async_accept(new_connection->socket(),
                    std::bind(&tcp_server::handle_accept, this, new_connection, std::placeholders::_1));
            */
                
        }

           
    }
}
