#pragma once 

#include "states.hpp"
#include <iostream>
#include <typeinfo>

namespace Core {
    namespace Gameplay{
       
        class JoinGameState : public GameState{
             public:

                void execute_state() override;

                void active_state() override{
                    const std::type_info& type = typeid(this);
                    std::cout << "Active state: " << type.name() << std::endl;
                }

                void idle_state() override;
                void update_state() override;
                void event_handler() override;
                bool enough_players();

            private:
                
                

            protected:
        };
    }
}
