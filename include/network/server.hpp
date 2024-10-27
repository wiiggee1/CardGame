#pragma once

#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "network/session_connections.hpp"
#include <boost/asio.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <functional>
#include <memory>
#include <vector>

namespace Core {
    namespace Network {

        using EventCallback = std::function<void()>;
        using PlayerClient = std::vector<std::shared_ptr<SessionConnection>>;

        class Server : public NetworkComponentInterface {
            public:

                Server(boost::asio::io_context& io_context, boost::asio::ip::tcp::endpoint srv_endpoint);

                /**
                * The abstract initialize() method, will call the neccessary Server network setup. 
                **/
                void initialize() override;
                
                /**
                * The abstract run() method, will invoke or call the io_context.run() boost::asio method. 
                **/
                void run() override;
               
                void handle_message(const Core::Network::Message& message) override;
                void send_message(const std::string& msg_payload) override;

                /* Listen for incoming connections (wait for incoming clients)... */
                void listen();

                PlayerClient& get_clients(){
                    return this->clients;
                }

                unsigned short get_server_id(){
                    return this->server_id;
                }

                std::shared_ptr<SessionConnection> get_target_client(unsigned short connection_id); 

                void set_connection_callback(EventCallback event_callback){
                    this->callback = event_callback;
                }

                /* Trigger the event callback whenever a new connection occurs. */
                void connection_event(){
                    if (callback) {
                        callback();
                    }
                }


            private:
                boost::asio::io_context& host_io_context;
                boost::asio::ip::tcp::acceptor conn_acceptor;
                unsigned short server_id; 
                PlayerClient clients;
                EventCallback callback;

        };
    }
}
