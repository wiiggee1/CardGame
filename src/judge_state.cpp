#include "judge_state.hpp"
#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "states.hpp"

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

       

        void JudgeState::idle_state(){

        }

        void JudgeState::on_event(Context* context, Event event){

        }

    }
}
