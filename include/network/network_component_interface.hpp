#pragma once

#include <boost/asio/ip/tcp.hpp>
#include <string>
class NetworkComponentInterface {
    public:
        virtual void initialize() = 0;
        virtual void run() = 0;
        virtual void request_handle() = 0;
        virtual void response_handle() = 0;
        virtual void send_message(const std::string& msg_payload) = 0;

        std::string get_endpoint_string(boost::asio::ip::tcp::socket& tcp_socket){
            auto client_endpoint = std::format("[{}:{}]: ",
                tcp_socket.remote_endpoint().address().to_string(), 
                tcp_socket.remote_endpoint().port()
            );
            return client_endpoint;
        }

        virtual ~NetworkComponentInterface() = default;

};
