#include "play_state.hpp"
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

        void PlayerState::update_state(){

        }

        void PlayerState::idle_state(){

        }

        void PlayerState::event_handler(){

        }
    }
}
