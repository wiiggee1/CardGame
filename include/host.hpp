#pragma once 

#include "network/server.hpp"
#include "network/session_connections.hpp"
#include "sessiontype.hpp"
#include <cstddef>
#include <iostream>
#include <map>
#include <tuple>
#include <vector>

namespace Core {


    enum class CardType{
            RED,             // Red card type 
            GREEN,          // Green card type
    };

    /**
    * @brief Host class, act as a placeholder for different attributes related to a server-side logic.  
    */
    class Host : public SessionType{
        public:
          
            void setup_session() override;
            void run_session() override;
            void run_state() override;

            std::tuple<std::vector<std::string>&, std::vector<std::string>&> get_cards(){
                // std::tie works the same as std::make_tuple but for lvalue references to its arguments. 
                return std::tie(this->red_deck, this->green_deck);
            }

            void add_cards(std::vector<std::string> red, std::vector<std::string> green){
                this->red_deck = red;
                this->green_deck = green;
            }

            void show_cards(CardType card_type){
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

            void add_to_round_deck(const std::string card){
                this->cardplayed_count++;                
                this->round_deck.push_back(card);
            }

            std::vector<std::string> get_round_deck(){
                //auto deck = this->round_deck;
                //this->round_deck.clear();
                return this->round_deck;
            }

            void deal_cards(unsigned short request_id, int request_amount);
            void shuffle_cards();
            void pick_judge();
            
            size_t get_client_count(){
                return this->client_count;
            }

            size_t get_cardplayed_count(){
                return this->cardplayed_count;
            }

            void loadgame_request();
            void startgame_message();
            void next_round_transition(); //Should discard the round_deck and move to the discard deck.

            void lookup_judge(int judge_id);
            void update_judge(); // move the client pointer to the left as the new judge.


        private:
            std::map<unsigned short, Network::PlayerClient> client_reference; // Should act as a pointer to certain players.
            Network::PlayerClient::iterator judge_idx_iter; 
            std::vector<std::string> round_deck;
            std::vector<std::string> red_deck;
            std::vector<std::string> green_deck;
            std::vector<std::string> discard_deck;
            
        protected:
            size_t client_count = 0;
            size_t cardplayed_count = 0; 
    };
    
}
