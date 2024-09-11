#pragma once

#include "events.hpp"
#include "network/network_component_interface.hpp"
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/local/stream_protocol.hpp>
#include <boost/asio/streambuf.hpp>
#include <cstdint>
#include <vector>
namespace Core {
    namespace Network {
        class Client : public NetworkComponentInterface {
            public:
                Client(boost::asio::io_context& ctx, const std::string& host_addr, unsigned short port);
                
                void initialize() override;
                void run() override;
                void handle_message(const Core::Network::Message& message) override;
                void send_message(const std::string& msg_payload) override;
                void send_message_test(const std::vector<uint8_t>& msg_payload);


                /* Establish communication with a destination server address (endpoint) */
                void connect();

                void start_reading();

                 

            protected:

            private:
                boost::asio::io_context& io_ctx;
                boost::asio::ip::tcp::socket client_socket;
                //boost::asio::ip::tcp::resolver resolv;
                //NOTE: Should I use 'streambuf' or fixed buffer like an char array?
                char client_buffer[1024];
                std::shared_ptr<Gameplay::EventHandler> event_queue;
                //std::vector<char> client_buffer(1024);
               
                  
        };
    }
}
