#pragma once

#include "events.hpp"
#include "network/message.hpp"
#include <boost/asio.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <cstdint>
#include <memory>
namespace Core {
    namespace Network {

        using NetworkEventCallback = std::function<void(Gameplay::Event)>;


        class Server; // IS THIS FORWARD DECLARATION CORRECT?

        class SessionConnection : public std::enable_shared_from_this<SessionConnection> {
            public:

                SessionConnection(boost::asio::ip::tcp::socket socket, Server& server);

                void start_reading();
                void write_to_client(const std::vector<uint8_t>& response_msg);
                std::string get_endpoint_stringz();

                void set_callback(NetworkEventCallback event_callback){
                    this->network_callback = event_callback;
                }

                void trigger_callback(Gameplay::Event event_type){
                    if (network_callback) {
                        network_callback(event_type);
                    }
                }

                void handle_request(const Message& message);

            private:
                boost::asio::ip::tcp::socket tcp_socket;
                char socket_buffer[1024];
                Server& server_ref;
                NetworkEventCallback network_callback; //On network message callback 
                
        };
    }
}
