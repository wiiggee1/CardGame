#pragma once 

#include "network/network_component_interface.hpp"
#include "states.hpp"
#include <iostream>
#include <map>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        using PlayerID = int;
        using Card = std::string;

        /**
        * @brief JudgeState class which inherits the GameState interface. 
        * This class act as a unique state during the game, and allow only judge specific actions.
        */
        class JudgeState : public Core::Gameplay::GameState{
            public:
              
                JudgeState(const JudgeState&) = delete; // remove copy constructor.
                JudgeState& operator=(const JudgeState&) = delete; // not assignable.

                // Singleton pattern - by creating a new unique JudgeState instance
                static std::unique_ptr<JudgeState> create_instance(){
                    std::unique_ptr<JudgeState> state(new JudgeState());
                    return state;
                }

                void voting_action();

                /* Whenever in judge state, a green apple card is drawn from the pile */
                void drawcard();

                void execute_state() override;

                StateTypes active_state() const override{
                    return StateTypes::Judge;
                }

                /* Await the players for that round to play their red cards. */
                void idle_state() override;
                
                void on_event(Core::Gameplay::Context *context, Event event) override; 

            private:
                std::map<PlayerID, Card> received_cards{};
                JudgeState() {}

            protected:

        };
    
    }
}

