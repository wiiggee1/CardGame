#pragma once 

#include "events.hpp"
#include "game.hpp"
#include "network/message.hpp"
#include "network/server.hpp"
#include "sessiontype.hpp"
#include <algorithm>
#include <format>
#include <iostream>
#include <memory>
#include <random>
#include <vector>
#include "host.hpp"

namespace Core {

    void Host::setup_session(){
        std::cout << "Setting up the Host-Session - by calling network->initialize()..." << std::endl;

        get_network_as<Network::Server>()->set_connection_callback([this](){
            std::cout << "This callback is invoked whenever a new client has joined!" << std::endl;
            auto clients = get_network_as<Network::Server>()->get_clients();
            this->client_count++;
            std::cout << "Number of connected Clients: " << clients.size() << std::endl;
            Game::getEventHandler()->push_event(Gameplay::Event::PlayerJoined);

            //TODO: - Send num_players update back to the client... Fix this logic to send to all sockets
            
            //std::string player_count = std::format("Connected players: {}", client_count);
            //get_network_as<Network::Server>()->send_message(player_count);
        });

        network->initialize();
    } 

    void Host::run_session(){
        std::cout << "Starting the Host-Session..." << std::endl;
        //get_network_as<Network::Server>()->run();
        network->run(); 
    }

    void Host::run_state(){

    }

    void Host::deal_cards(){
        /*
        auto clients = get_network_as<Network::Server>()->get_clients();
        for (auto player : clients){
            // WARN: 
            //       1. Deal 7 red apples to each player including the judge. 
            //       2. Pop all of the dealt card from the main red apples deck (so we dont get any duplicates).
        }
        */
    }

    void Host::shuffle_cards(){
        std::cout << "Shuffling the Red- & -Green Apple decks" << std::endl;
        std::random_device rdevice;
        std::mt19937 generator(rdevice());
        std::shuffle(this->red_deck.begin(), this->red_deck.end(), generator);
        std::shuffle(this->green_deck.begin(), this->green_deck.end(), generator);

        // TODO: --> Add unit test for checking the shuffling logic...

    }

    void Host::loadgame_request(){
        auto server = this->get_network_as<Network::Server>();
        
        std::string payload = "We will randomize who will start as Judge";
        auto msg = Network::create_message(
                Network::MessageType::Request, 
                Network::RPCType::LoadGame, 
                payload);

        auto byte_message = Network::serialize_message(msg);

        for(auto& client : server->get_clients()){
            client->write_to_client(byte_message);
        }
    }

    void Host::startgame_message(){
        auto server = this->get_network_as<Network::Server>();
        
        std::string payload = "We will randomize who will start as Judge";
        auto msg = Network::create_message(
                Network::MessageType::Request, 
                Network::RPCType::StartGame, 
                payload);

        auto byte_message = Network::serialize_message(msg); 

        for(auto& client : server->get_clients()){
            client->write_to_client(byte_message);
        }
    }
    
}
