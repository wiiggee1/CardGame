#pragma once 

#include "network/client.hpp"
#include "network/message.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <boost/asio/buffer.hpp>
#include <cstddef>
#include <iostream>
#include <memory>
#include <sstream>
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
        if (this->state_context){
            this->state_context->execute_state();
        }
    }

    std::string Player::show_cards(){
        std::stringstream ss;
        for (auto card : this->red_cards){
            ss << card <<"\n";
        }
        return ss.str();
    }

    void Player::switch_state(std::unique_ptr<Gameplay::GameState> new_state){
        this->state_context->set_state(std::move(new_state));
    }

    void Player::setup_context(std::unique_ptr<Gameplay::GameState> state){
        this->state_context = std::make_unique<Gameplay::Context>(std::move(state));
    }

    void Player::synchronize_game(){
        //1. First we send RPCType::DealCard to obtain the individual player cards.
        //2. Secondly 
        auto msg = Network::create_message(Network::MessageType::Request, Network::RPCType::DealCard, "7");
        auto byte_message = Network::serialize_message(msg);
        get_network_as<Network::Client>()->send_message_test(byte_message);
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

    bool Player::is_in_state(Gameplay::StateTypes state_type) const {
        if (this->state_context){
            return this->state_context->active_state() == state_type;
        }
        return false; 
    }
   

}
