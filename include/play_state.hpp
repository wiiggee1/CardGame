#pragma once 

#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>
#include <memory>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        /**
        * @brief PlayerState class which inherits the GameState interface. 
        * This class act as a unique state during the game, and allow only specific actions.
        */
        class PlayingState : public Gameplay::GameState{
            public:
                PlayingState(const PlayingState&) = delete; // remove copy constructor.
                PlayingState& operator=(const PlayingState&) = delete; // not assignable.

                // Singleton pattern - by creating a new unique PlayingState instance
                static std::unique_ptr<PlayingState> create_instance(){
                    std::unique_ptr<PlayingState> state(new PlayingState());
                    return state;
                } 

                void playcard();
                
                /* Whenever in player state, a red apple card is drawn from the pile if less than 7 cards */
                void drawcard();

                void execute_state() override;

                StateTypes active_state() const override{
                    return StateTypes::Playing;
                }

                void idle_state() override;
                void on_event(Context *context, Event event) override;

            private:
                PlayingState() {}
                

            protected:
                
        };
    
    }
}
