#pragma once 

#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        /**
        * @brief PlayerState class which inherits the GameState interface. 
        * This class act as a unique state during the game, and allow only specific actions.
        */
        class PlayerState : public Gameplay::GameState{
            public:
                void playcard();
                
                /* Whenever in player state, a red apple card is drawn from the pile if less than 7 cards */
                void drawcard();

                void execute_state() override;

                void active_state() override{
                    const std::type_info& type = typeid(this);
                    std::cout << "Active state: " << type.name() << std::endl;
                }

                void idle_state() override;
                void on_event(Context *context, Event event,  NetworkComponentInterface& network) override;

            private:
                

            protected:
                
        };
    
    }
}
