#pragma once 

#include "network/client.hpp"
#include "network/message.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <boost/asio/buffer.hpp>
#include <cstddef>
#include <iostream>
#include <memory>
#include <vector>
#include "player.hpp"

namespace Core {

    using namespace boost::asio::buffer_literals;
    

    void Player::setup_session(){
        std::cout << "Setting up the Player Session - by calling network->initialize()..." << std::endl;
        network->initialize();
    }

    void Player::run_session(){
        std::cout << "Starting the Player Session..." << std::endl;
        network->run();
    }

    void Player::switch_state(std::unique_ptr<Gameplay::GameState> new_state){
        this->state_context->set_state(std::move(new_state));
    }

    void Player::test_readwrite_communication(){
        std::cout << "Attempting to write to Server..." << std::endl;
        //network->send_message("This is a Player message TEST!");

        /*
        boost::asio::const_buffer buffer_test = "this is a test payload"_buf;
        std::cout << "byte array data:" << buffer_test.data() << std::endl;
        std::cout << "byte array data size:" << buffer_test.size() << std::endl;
        
        auto byte_array = boost::asio::buffer("this is a test payload!");
        std::cout << "byte array data: " << byte_array.data() << std::endl;
        const char* char_data = static_cast<const char*>(byte_array.data());
        std::string buffer_info = std::format("Byte data: {}, Char data: {}", byte_array.data(), char_data);
        std::cout << buffer_info << std::endl;
        */

        Network::Message msg;
        msg.type = Network::MessageType::Request;
        msg.rpc_type = Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Network::serialize_message(msg);
        get_network_as<Network::Client>()->send_message_test(byte_message);
        //get_network_as<Network::Client>()->send_message("This is a Player message TEST!");
    }

    void Player::test_serialization(){
        std::cout << "Running test_serialization logic: \n" << std::endl;
        Network::Message msg;
        msg.type = Network::MessageType::Request;
        msg.rpc_type = Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Network::serialize_message(msg);

        std::cout << "Testing deserialization logic: \n" << std::endl;
        auto decoded_msg = Network::deserialize_message(byte_message);
    }
}
