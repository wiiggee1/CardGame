#include "play_state.hpp"
#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>

namespace Core {
    namespace Gameplay{

        void PlayerState::drawcard(){
            std::cout << "Draw Card Action! [PLAYING STATE]" << std::endl;
        }

        void PlayerState::playcard(){
            std::cout << "Play Card Action! [PLAYING STATE]" << std::endl;
        }

        void PlayerState::execute_state(){
            std::cout << "Executing Playing State" << std::endl;

        }

        void PlayerState::idle_state(){

        }

        void PlayerState::on_event(Context* context, Event event, NetworkComponentInterface& network){

        }
    }
}
