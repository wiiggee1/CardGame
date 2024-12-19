#pragma once 

#include "events.hpp"
#include "game.hpp"
#include "network/message.hpp"
#include "network/server.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <algorithm>
#include <array>
#include <format>
#include <iostream>
#include <memory>
#include <numeric>
#include <random>
#include <string>
#include <vector>
#include "host.hpp"

namespace Core {

    void Host::setup_session(){
        std::cout << "Setting up the Host-Session - by calling network->initialize()..." << std::endl;
        network->initialize();
    } 

    void Host::run_session(){
        std::cout << "Starting the Host-Session..." << std::endl;
        //get_network_as<Network::Server>()->run();
        network->run(); 
    }

    void Host::run_state(){

    }

    void Host::show_cards(CardType card_type){
         if (card_type == CardType::RED){
            for (auto card : this->red_deck){
                std::cout << card << std::endl;
            }
            
        }else if (card_type == CardType::GREEN){
            for (auto card : this->green_deck){
                std::cout << card << std::endl;
            }
        }
    }

    void Host::setup_host_callbacks(){
        get_network_as<Network::Server>()->set_connection_callback([this](){
            std::cout << "This callback is invoked whenever a new client has joined!" << std::endl;
            auto clients = get_network_as<Network::Server>()->get_clients();
            auto latest_client = clients.back();
            auto client_id = latest_client->get_id();
            
            Game::getGameState().player_data[client_id] = GameData{false, false, 0, 0};

            //Game::getEventHandler()->push_event(Gameplay::Event::PlayerJoined);            
            std::cout << "Number of connected Clients: " << clients.size() << std::endl;
            Game::getEventHandler()->store_eventmessage(Gameplay::Event::PlayerJoined, Network::DontCare());            
            //Game::getEventHandler()->trigger_event(Gameplay::Event::PlayerJoined);            
             
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::PlayerJoined, [this](){
            Game::getEventHandler()->pop_eventmessage();
            playerjoined_event();
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::GameReady, [this](){
            std::cout << "GameReady Event - executing loadgame_request!" << std::endl;
            //Game::getEventHandler()->pop_eventmessage();
            loadgame_request();
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::CardRequest, [this](){
            std::cout << "Trying to execute: 'card_request_event()'" << std::endl;            
            auto [event, message] = Game::getEventHandler()->get_eventmessage();
            card_request_event(message); 
            std::cout << "Successfully executed: 'card_request_event()'" << std::endl;            
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::SynchronizeGame, [this](){
            synchronize_game(); 
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::GameStarted, [this](){
            // pop or process event msg here...
            auto [event, message] = Game::getEventHandler()->get_eventmessage();
            std::cout << "GameStarted Event - executing: 'startgame_message()'" << std::endl;
            startgame_message();
            std::cout << "Successfully - executed: 'startgame_message()'" << std::endl;
            
            //server->get_target_client(request_id)->write_to_client(byte_msg);
        });

        Game::getEventHandler()->add_callback(Gameplay::Event::CardPlayed, [this](){
            card_played_event(); 
        });
    }

    void Host::card_request_event(Core::Network::Message message){
        auto request_id = message.id;
        std::string card_amount = message.payload;
        //std::cout << "Received message.payload: " << card_amount << std::endl;
                
        int requested_card_amount = std::stoi(message.payload);
        //std::cout << "Player requested: " << requested_card_amount << " cards." << std::endl;
                
        auto [red_cards, green_cards] = get_cards();
        //std::cout << "Size of red cards deck: " << red_cards.size() << std::endl;
               
        //shuffle_cards();

        deal_cards(request_id, requested_card_amount); 
        //std::cout << "Size of red cards deck after dealing cards: " << red_cards.size() << std::endl; 
    }

    void Host::card_played_event(){
        auto [event, message] = Game::getEventHandler()->get_eventmessage();   
        auto game_rules = Game::getGameRules();        
        auto server = get_network_as<Network::Server>();
        auto sender_id = server->get_server_id();
         
        //TODO: - Add some hashmap or identifier for the associated client with the played card!
        //E.g., Creating a 'GameRound' struct, for checking which player, has played, who is judge etc...
        add_to_round_deck(message.payload);
        size_t expected_played_cards = get_client_count() + game_rules.num_bots;

        if (get_cardplayed_count() == expected_played_cards){
            auto played_cards = get_round_deck();
            auto cards_payload = Network::join_strings(played_cards, '/');
            auto msg = Network::create_message(Network::MessageType::Request, server->get_server_id(), Network::RPCType::Vote, cards_payload); 
        }
    }

    void Host::playerjoined_event(){
        // Logic for whenever, player joined event has occured. 
        this->client_count++;
        auto game_rules = Core::Game::getGameRules();
        int num_clients = (int)this->client_count;
        auto server = get_network_as<Network::Server>();        
        auto sender_id = server->get_server_id();
        auto total_players = get_client_count() + game_rules.num_bots;

        if (num_clients == game_rules.expected_players){
            //startgame_message();          
            //std::cout << "Trying to invoke GameReady Event!" << std::endl;
            //Game::getEventHandler()->store_eventmessage(Gameplay::Event::GameReady, Network::DontCare());
            Game::getEventHandler()->trigger_event(Gameplay::Event::GameReady);
            
        }else {
            // Send update of count to Clients
            auto update_msg = Network::create_message(Network::MessageType::Response, sender_id, Network::RPCType::NewConnection, std::to_string(num_clients));
            send_update(update_msg); 
        }
    }

    void Host::send_update(Network::Message msg){
        auto server = get_network_as<Network::Server>();        
        auto sender_id = server->get_server_id();
        auto byte_msg = Network::serialize_message(msg);

        for(auto& client : server->get_clients()){
            client->write_to_client(byte_msg);
        }
    }

    void Host::deal_cards(unsigned short request_id, int request_amount){
        std::cout << "Inside Host::deal_cards() logic!" << std::endl;
        
        auto server = get_network_as<Network::Server>();
        auto sender_id = server->get_server_id();
        std::vector<std::string> cards_to_send;

        for (int i = 0; i < request_amount; i++){
            auto card = this->red_deck[0];
            this->red_deck.erase(this->red_deck.begin());
            cards_to_send.push_back(card);
        }
        
        auto response_payload = Network::join_strings(cards_to_send, '/');
        //std::cout << "In 'deal_cards' logic, cards to send as payload: " << response_payload << std::endl;
        auto response_msg = Network::create_message(Network::MessageType::Response, sender_id, Network::RPCType::DealCard, response_payload);
        auto byte_msg = Network::serialize_message(response_msg);
        server->get_target_client(request_id)->write_to_client(byte_msg);
        std::cout << "In 'deal_cards' logic - Successful! " << std::endl;
        
    }

    std::string Host::take_card(CardType card_type){
        std::string card; 
        if (card_type == CardType::GREEN){
            card = std::move(this->green_deck[0]);
            this->green_deck.erase(this->green_deck.begin());
        }else {
            card = std::move(this->red_deck[0]);
            this->red_deck.erase(this->red_deck.begin());
        }
        return card; 
    }

    void Host::shuffle_cards(){
        std::cout << "Shuffling the Red- & -Green Apple decks" << std::endl;
        std::random_device rdevice;
        std::mt19937 generator(rdevice());
        std::shuffle(this->red_deck.begin(), this->red_deck.end(), generator);
        std::shuffle(this->green_deck.begin(), this->green_deck.end(), generator);
    }

    void Host::loadgame_request(){
        std::cout << "Inside loadgame_request()!" << std::endl;
        
        auto server = this->get_network_as<Network::Server>();
        std::string visable_round_card = take_card(CardType::GREEN);
        auto msg = Network::create_message(
                Network::MessageType::Request, 
                server->get_server_id(),
                Network::RPCType::LoadGame, 
                visable_round_card);
        auto byte_message = Network::serialize_message(msg);

        for(auto& client : server->get_clients()){
            client->write_to_client(byte_message);
        }
        std::cout << "Inside loadgame_request() - Successful" << std::endl;
        
    }

    void Host::synchronize_game(){
        std::cout << "Starting Loading and Synchronizing of the Game!" << std::endl;
    }

    void Host::startgame_message(){
        std::cout << "Inside Start game message logic!" << std::endl;
        
        pick_judge();
        
        auto server = this->get_network_as<Network::Server>();
        std::string judge_payload = Gameplay::StateTypeToString(Gameplay::StateTypes::Judge);
        std::string playing_payload = Gameplay::StateTypeToString(Gameplay::StateTypes::Playing);

        auto judge_msg = Network::create_message(
                Network::MessageType::Response,
                server->get_server_id(),
                Network::RPCType::StartGame, 
                judge_payload);

        auto playing_msg = Network::create_message(
                Network::MessageType::Response,
                server->get_server_id(),
                Network::RPCType::StartGame, 
                playing_payload);

        for(auto& client: server->get_clients()){
            //std::cout << "Inside Start game message logic and in the for loop!" << std::endl;
            //std::cout << "client id: " << client->get_id() << std::endl;
            //std::cout << "judge_idx_iter -> client id: " << (*judge_idx_iter) << std::endl;
             
            if (client->get_id() == (*this->judge_idx_iter)->get_id()){
                std::cout << "Found Judge index iterator ID" << std::endl;
                auto byte_message = Network::serialize_message(judge_msg); 
                client->write_to_client(byte_message);
            }else {
                std::cout << "In else branch for sending 'Playing' start state!" << std::endl;
                auto byte_message = Network::serialize_message(playing_msg); 
                client->write_to_client(byte_message);
            }

        }
        std::cout << "Inside Start game message logic, successfully ran all!" << std::endl;

        //update_judge();
    }

    void Host::next_round_transition(){
        // 1. Append all played card in the round_card vector.
        // 2. Check if all players have sent a "PlayCard" request. 
        // 3. If all have played, send RPC message to judge iterator to perform voting event action.
        // 4. Listen for whenever judge client have sent RPC JudgeVote then send point to winner... and repeat...
        // 5. Also draw a new green apple card every new round.
        auto server = this->get_network_as<Network::Server>();
        

        update_judge();
        auto new_judge = this->judge_idx_iter->get()->get_id();
        auto new_round_msg = Network::create_message(Network::MessageType::Request, server->get_server_id(), Network::RPCType::NewRound, "judge/nojudge");
    }

    void Host::pick_judge(){
        // 1. Pick randomized judge. 
        // 2. Update the judge_ptr_idx iterator position
        // 3. After sending, update the judge_ptr_idx for the next upcoming round.
        
        std::cout << "Executing: 'pick_judge'!" << std::endl;
        
        auto server = this->get_network_as<Network::Server>();
        auto& clients = server->get_clients();
        std::vector<int> range_vec(clients.size());
        std::iota(range_vec.begin(), range_vec.end(), 0);
         
        std::random_device rdevice;
        std::mt19937 generator(rdevice());
        std::uniform_int_distribution<int> distribution(0, clients.size() - 1);
        
        int iterator_offset = distribution(generator);
        //std::cout << "iterator offset: " << iterator_offset << std::endl;
        auto jdg_idx = clients.begin() + iterator_offset;
        //std::cout << "jdg_idx client id: " << (*jdg_idx)->get_id() << std::endl;
        this->judge_idx_iter = clients.begin() + iterator_offset;
    
        /*
        if (clients.size() == 1){
            this->judge_idx_iter = clients.begin();
        }else {
            this->judge_idx_iter = clients.begin() + iterator_offset;
        }
        */
    }

    void Host::update_judge(){
        auto server = this->get_network_as<Network::Server>();
        auto clients = server->get_clients();
        if (this->judge_idx_iter != clients.end()){
            this->judge_idx_iter++;
        }else {
            // Go back to beginning of vector
            this->judge_idx_iter = clients.begin();
        }
    }
    
}
