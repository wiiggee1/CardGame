#pragma once 

#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>
#include <typeinfo>

namespace Core {
    namespace Gameplay{
       
        class JoinGameState : public GameState{
             public:

                JoinGameState(const JoinGameState&) = delete; // remove copy constructor.
                JoinGameState& operator=(const JoinGameState&) = delete; // not assignable.

                // Singleton pattern - by creating a new unique JoinGameState instance
                static std::unique_ptr<JoinGameState> create_instance(){
                    std::unique_ptr<JoinGameState> state(new JoinGameState());
                    return state;
                }

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
                JoinGameState(){}
                

            protected:
        };
    }
}
