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

    void Player::run_state(){
        /*
         * Handle Inputs from the player.
         * Send the player's actions to the host via the 'Client' member.
         * Receives Updates, by listening for updates from the host and updates the local game state.
         */
        this->state_context->execute_state();
    }

    void Player::switch_state(std::unique_ptr<Gameplay::GameState> new_state){
        this->state_context->set_state(std::move(new_state));
    }

    void Player::setup_context(std::unique_ptr<Gameplay::GameState> state){
        this->state_context = std::make_unique<Gameplay::Context>(std::move(state));
    }

    void Player::send_request(){
        Network::Message msg;
        msg.type = Network::MessageType::Request;
        msg.rpc_type = Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Network::serialize_message(msg);
        get_network_as<Network::Client>()->send_message_test(byte_message);
        
        //this->network->send_message(const std::string &msg_payload)
    }
   

}
