#include "network/network_component_interface.hpp"
#include "play_state.hpp"
#include "states.hpp"
#include <joingame_state.hpp>
#include <memory>
#include <ostream>
#include <iostream>
#include <thread>

namespace Core {
    namespace Gameplay{

        void JoinGameState::execute_state(){
            // Here you might poll or receive continuous updates from the server
            // Check if any status update is needed or if any other condition has been met
            
            std::string space_char = " ";
            bool blink_flag = true;

            auto& state_conditions = this->context->get_conditions();
            state_conditions.waiting_tostart = true;
           
            if (state_conditions.all_connected){
                this->context->set_state(std::make_unique<PlayerState>());
            }

            //std::cout << "\033[2J\033[H" << std::flush; // clear the screen
            std::system("clear"); 
            
            
        }

        void JoinGameState::idle_state(){

        }

       
        void JoinGameState::on_event(Context* context, Event event, NetworkComponentInterface& network){
            auto& state_conditions = this->context->get_conditions();
            if (event == Event::UserInput) {

            }else if (event == Event::StartGame) {
                // TODO: - Send request with RPC message type DealCard, should also transition  
            }
        }

        bool JoinGameState::enough_players(){
            auto& state_conditions = this->context->get_conditions();
            return state_conditions.all_connected.load() == true;
        }

    }
}
