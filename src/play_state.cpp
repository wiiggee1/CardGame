#include "play_state.hpp"
#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>

namespace Core {
    namespace Gameplay{

        void PlayingState::drawcard(){
            std::cout << "Draw Card Action! [PLAYING STATE]" << std::endl;
        }

        void PlayingState::playcard(){
            std::cout << "Play Card Action! [PLAYING STATE]" << std::endl;
        }

        void PlayingState::execute_state(){
            std::cout << "Executing Playing State" << std::endl;

        }

        void PlayingState::idle_state(){

        }

        void PlayingState::on_event(Context* context, Event event){

        }
    }
}
