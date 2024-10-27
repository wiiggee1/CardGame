#pragma once 

#include "joingame_state.hpp"
#include "network/client.hpp"
#include "network/message.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <boost/asio/buffer.hpp>
#include <cstddef>
#include <iostream>
#include <memory>
#include <ostream>
#include <sstream>
#include <vector>
#include "player.hpp"
#include "game.hpp"

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
        std::cout << "Red cards: \n" << ss.str() << std::endl;
        return ss.str();
    }

    void Player::switch_state(std::unique_ptr<Gameplay::GameState> new_state){
        this->state_context->set_state(std::move(new_state));
    }

    void Player::setup_context(std::unique_ptr<Gameplay::GameState> state){
        //this->state_context = std::make_unique<Gameplay::Context>(std::move(state));
        if (!state_context) {
            this->state_context = std::make_unique<Gameplay::Context>(std::move(state));
        } else {
            this->state_context->set_state(std::move(state));
        }
    }

    void Player::setup_player_callbacks(){

        //NOTE: - Its important to pop the event message queue, to mark it as handle. 
        //        Even though, you dont need to read anything. To prevent infinite loops!

        Game::getEventHandler()->add_callback(Gameplay::Event::PlayerJoined, [this](){
            std::cout << "PlayerJoined Event Callback!" << std::endl;            
            auto [event, update_msg] = Game::getEventHandler()->get_eventmessage();
            playerjoined_update(update_msg);
            // runt event trigger methods here...
            //1. Read received event message, and print out the connected count.
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::SynchronizeGame, [this](){
            auto [event, received_msg] = Game::getEventHandler()->get_eventmessage();
            update_round_card(received_msg.payload); 
            synchronize_game();
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::CardReceived, [this](){
            std::cout << "CardReceived Event Callback invoked by Player!" << std::endl;
            auto [event, received_msg] = Game::getEventHandler()->get_eventmessage();
            cards_response(received_msg);
        });
    }

    void Player::update_round_card(std::string open_card){
        this->round_card = open_card;
    }

    void Player::synchronize_game(){
        //1. First we send RPCType::DealCard to obtain the individual player cards.
        //2. Secondly 
        request_cards(7);
        send_request(Network::RPCType::StartGame, "I am ready, and have received my cards!"); 
    }

    void Player::cards_response(Network::Message response_msg){
        //Network::print_message(received_msg);
        if(!response_msg.payload.empty() && response_msg.rpc_type == Network::RPCType::DealCard){
            auto cards = Network::split_string(response_msg.payload, ',');
            add_cards(cards);
            show_cards();
        }   
    }

    void Player::playerjoined_update(Network::Message update_msg){
        std::string waiting_screen = std::format("Waiting to start the game!\nConnected players: {}", update_msg.payload);
        std::cout << waiting_screen << std::endl;
    }

    void Player::request_cards(int num_cards){
        auto msg_id = get_network_as<Network::Client>()->get_client_id();
        int modified_num_cards = num_cards;

        while(true){
            if (this->red_cards.size() + modified_num_cards <= 7){
                break; 
            }else{
                modified_num_cards--;
            }
        }
        
        std::cout << "In 'request_cards' logic, modified_num_cards: " << modified_num_cards << std::endl;
        auto amount_payload = std::to_string(static_cast<int>(modified_num_cards));
        auto msg = Network::create_message(Network::MessageType::Request, msg_id, Network::RPCType::DealCard, amount_payload);
        auto byte_message = Network::serialize_message(msg);
        get_network_as<Network::Client>()->send_message_test(byte_message);
    }

    void Player::send_request(Network::RPCType rpc_type, std::string payload){
        auto msg_id = get_network_as<Network::Client>()->get_client_id();
        auto request_msg = Network::create_message(Network::MessageType::Request, msg_id, rpc_type, payload);
        auto byte_message = Network::serialize_message(request_msg);
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
