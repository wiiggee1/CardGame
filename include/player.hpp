#pragma once 

#include "network/message.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <condition_variable>
#include <iostream>
#include <memory>
#include <vector>
#include "game.hpp"



namespace Core {

    /**
    * @brief Player class, act as a placeholder for different attributes related to a client player.  
    */
    class Player : public SessionType{
        public:
            
          
            Player(std::unique_ptr<Core::Gameplay::GameState> init_state) 
                : state_context(std::make_unique<Core::Gameplay::Context>(std::move(init_state), this)){}

            std::vector<std::string>& get_cards(){
                return this->red_cards;
            }

            void add_card(std::string card){
                this->red_cards.push_back(card);
            }

            void add_cards(std::vector<std::string> cards){
                std::cout << "Player number of cards before adding: " << this->red_cards.size() << std::endl;
                std::cout << "Cards arg size before: " << cards.size() << std::endl;
                
                for (auto card: cards){
                    //std::cout << "Adding card:\n" << card << std::endl;
                    this->red_cards.push_back(card);
                }
                std::cout << "Number of cards after adding: " << this->red_cards.size() << std::endl;
            }

            std::unique_ptr<Gameplay::Context>& get_context(){
                return state_context;
            }

            int get_points(){
                return this->green_cards.size();
            }

            std::string get_round_card(){
                return this->round_card;
            }

            void update_round_card(std::string round_card);

            std::string show_cards();

            void setup_session() override;
            void run_session() override;
            void run_state() override;
           
            void setup_player_callbacks();
            //void setup_context(std::unique_ptr<Gameplay::GameState> state);
            //void switch_state(std::unique_ptr<Gameplay::GameState> new_state);
            void send_rpc(Network::MessageType msg_type, Network::RPCType rpc_type, std::string payload);

            //bool is_in_state(Gameplay::StateTypes state_type) const;
            void synchronize_game(); // This is a request for loading and synchronizing the game state.
            void cards_response(Network::Message response_msg); // Handle the response of the requested cards.
            void request_cards(int num_cards);
            void playerjoined_update(Network::Message update_msg);

        private:
            int player_id;
            bool judge = false;
            //TODO: Add data buffers for reading and output stream between the hosting server. 
            std::vector<std::string> red_cards; // This should be the unique player's hand of cards
            std::vector<std::string> green_cards; // Green cards act as the points of the player. 
            std::string round_card; // This is the green card shown to everyone, each round. 

        protected:
            /**
             * Unique pointer context, for managing game states (Player or Judge states).
             * Recall that a unique pointer maintains exclusive ownership and can only be moved.
             * This field manages the Context lifecycle.
             */
            std::unique_ptr<Core::Gameplay::Context> state_context;
            


    };
    
}
