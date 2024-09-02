#pragma once 

#include "sessiontype.hpp"
#include "states.hpp"
#include <condition_variable>
#include <iostream>
#include <memory>
#include <vector>

namespace Core {

    /**
    * @brief Player class, act as a placeholder for different attributes related to a client player.  
    */
    class Player : public SessionType{
        public:
            
            std::vector<std::string>& get_cards(){
                return this->red_cards;
            }

            std::unique_ptr<Gameplay::Context>& get_context(){
                return state_context;
            }

            void setup_session() override;
            void run_session() override;

            void switch_state(std::unique_ptr<Gameplay::GameState> new_state);

            void test_readwrite_communication();
            void test_serialization();

        private:
            int player_id; 
            //TODO: Add data buffers for reading and output stream between the hosting server. 
            std::vector<std::string> red_cards; // This should be the unique player's hand of cards
            std::vector<std::string> green_cards; // Green cards act as the points of the player. 
            
        protected:
            /**
             * Unique pointer context, for managing game states (Player or Judge states).
             */
            std::unique_ptr<Gameplay::Context> state_context;
            //std::mutex mtx;
            //std::condition_variable cv;
            //std::atomic<bool> condition_met(false);
    };
    
}
