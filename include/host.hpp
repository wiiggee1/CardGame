#pragma once 

#include "network/server.hpp"
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

            void deal_cards();
            void shuffle_cards();
            void randomize_judgeplayer();
            
            size_t get_client_count(){
                return this->client_count;
            }

            void loadgame_request();
            void startgame_message();

            void lookup_judge(int judge_id);


        private:
            std::map<int, Network::PlayerClient> judge_connection;
            std::vector<std::string> red_deck;
            std::vector<std::string> green_deck;
            std::vector<std::string> discard_red;
            std::vector<std::string> discard_green;
            
        protected:
            size_t client_count = 0;
            size_t cardplayed_count = 0; 
    };
    
}
