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

                StateTypes active_state() const override{
                    return StateTypes::WaitingForPlayers;
                }

                void idle_state() override;
                void on_event(Context *context, Event event) override;
                bool enough_players();

            private:
                
                

            protected:
        };
    }
}
