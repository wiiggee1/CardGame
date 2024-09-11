#pragma once 

#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>
#include <typeinfo>

namespace Core {
    namespace Gameplay{
       
        class JoinGameState : public GameState{
             public:

                 // Here you might poll or receive continuous updates from the server.
                // Check if any status update is needed or if any other condition has been met
                void execute_state() override;

                void active_state() override{
                    const std::type_info& type = typeid(this);
                    std::cout << "Active state: " << type.name() << std::endl;
                }

                void idle_state() override;
                void on_event(Context *context, Event event, NetworkComponentInterface& network) override;
                bool enough_players();

            private:
                
                

            protected:
        };
    }
}
