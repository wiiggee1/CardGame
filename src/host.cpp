#pragma once 

#include "network/server.hpp"
#include "sessiontype.hpp"
#include <algorithm>
#include <iostream>
#include <memory>
#include <random>
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
    
}
