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
        class JudgeState : public Gameplay::GameState{
            public:
               
                void voting_action();

                /* Whenever in judge state, a green apple card is drawn from the pile */
                void drawcard();

                void execute_state() override;

                StateTypes active_state() const override{
                    return StateTypes::Judge;
                }

                /* Await the players for that round to play their red cards. */
                void idle_state() override;
                
                void on_event(Context *context, Event event) override; 

            private:
                std::map<PlayerID, Card> received_cards;
                

            protected:

        };
    
    }
}

