#include "play_state.hpp"
#include <joingame_state.hpp>
#include <memory>

namespace Core {
    namespace Gameplay{

        void JoinGameState::execute_state(){
            std::cout << "Executing JoinGame State" << std::endl;
            auto& state_conditions = this->context->get_conditions();
            state_conditions.waiting_tostart = true;
            
            while(state_conditions.waiting_tostart) {
                event_handler(); 
            }
            this->update_state();

        }

        void JoinGameState::idle_state(){

        }

        void JoinGameState::update_state(){
            
            auto& state_conditions = this->context->get_conditions();
            if (!state_conditions.is_judge){
                this->context->set_state(std::make_unique<Gameplay::PlayerState>());

            }else if (state_conditions.is_judge) {
                // is in judge state
            }

        }
        void JoinGameState::event_handler(){
            auto& state_conditions = this->context->get_conditions();
            
            if (this->enough_players()){
                std::cout << "Enough players have joined. Switching to Starting Game State!" << std::endl;
                //state->get_context()->set_state(std::unique_ptr<GameState> new_state)
                //state->switch_state(std::make_unique<Gameplay::PlayerState>());
                state_conditions.waiting_tostart = false;

            }else {
                std::cout << "Printout of status of num of clients that has connected" << std::endl;
            }
        }

        bool JoinGameState::enough_players(){
            auto& state_conditions = this->context->get_conditions();
            return state_conditions.all_connected.load() == true;
        }

    }
}
