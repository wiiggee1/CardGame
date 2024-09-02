#include "judge_state.hpp"

namespace Core {
    namespace Gameplay{
        
        void JudgeState::voting_action(){
            std::cout << "Vote Action!" << std::endl;

        }

        void JudgeState::drawcard(){
            std::cout << "Draw Card Action [JUDGE STATE]!" << std::endl;

        }

        void JudgeState::execute_state(){
            std::cout << "Executing Judge State" << std::endl;
        }

        void JudgeState::update_state(){

        }

        void JudgeState::idle_state(){

        }

        void JudgeState::event_handler(){

        }

    }
}
