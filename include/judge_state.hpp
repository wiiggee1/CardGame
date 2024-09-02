#pragma once 

#include "states.hpp"
#include <iostream>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        /**
        * @brief JudgeState class which inherits the GameState interface. 
        * This class act as a unique state during the game, and allow only judge specific actions.
        */
        class JudgeState : public Gameplay::GameState{
            public:
               
                void voting_action();

                /* Whenever in judge state, a green apple card is drawn from the pile */
                void drawcard();

                void execute_state() override;

                void active_state() override{
                    const std::type_info& type = typeid(this);
                    std::cout << "Active state: " << type.name() << std::endl;
                }

                /* Await the players for that round to play their red cards. */
                void idle_state() override;
                
                void update_state() override;
                void event_handler() override;

            private:
                

            protected:

        };
    
    }
}

