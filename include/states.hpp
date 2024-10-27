#pragma once 

#include "events.hpp"
#include "network/network_component_interface.hpp"
#include "sessiontype.hpp"
#include <algorithm>
#include <iostream>
#include <memory>
#include <typeinfo>
#include <vector>
#include <atomic>

namespace Core{
    namespace Gameplay{

        class Context;

        enum class States{
            PLAYCARD,           // Play red apple from hand (based on green apple)
            ALL_READY,          // All players have played its red apple card (this round)
            PLAYER_WON,         // Check each round if player / client have x green apples 
            REWARD_PLAYER,      // Increment the client player which the judge selected
            IDLE,               // After performing action the players enter a waiting state
        };

        enum class StateTypes {
            WaitingForPlayers,  // This is the joing game wait state, for waiting for all clients to connect.
            Playing,            // This is playing state if you're not in 'judge state'.
            Judge,              // Other playing state but whenever you are the judge.
            Idle,               // Idle state for clients to wait for the new round, this will print status.
            Error,
        };

        struct StateCondition {
            std::atomic<bool> waiting_tostart{false};
            std::atomic<bool> all_connected{false};
            std::atomic<bool> all_played{false};
            std::atomic<bool> judge_has_selected{false};
            std::atomic<bool> is_judge{false};
        };

        class GameState{
            public:
                virtual ~GameState() = default;
              
                /* Handle any ongoing state logic, such as waiting for player's action, etc...*/
                virtual void execute_state() = 0;
                virtual StateTypes active_state() const = 0;
                virtual void on_event(Context* context, Event event) = 0;
                virtual void idle_state() = 0; // idle state should check for conditions iteratively
                
                void set_context(Context *context){
                    this->context = context;
                }
            
            protected:
                Context *context;

        };

        class Context {
            
            public:
                Context(std::unique_ptr<GameState> initial_state){
                    this->set_state(std::move(initial_state));
                }

                /**
                 * The 'set_state' method is for transition between different states, during runtime. 
                 */
                void set_state(std::unique_ptr<GameState> new_state){
                    this->state = std::move(new_state);
                    this->state->set_context(this);
                }

                StateTypes active_state() const {
                    return this->state->active_state(); 
                }

                void execute_state() {
                    this->state->execute_state();
                }

                void idle_state() {
                    this->state->idle_state();
                }

                void event_handler(Event event) {
                    this->state->on_event(this, event);
                }

                StateCondition& get_conditions() {
                    return this->conditions;
                }

                std::string get_current_state(){
                    const std::type_info& type = typeid(this->state);
                    return type.name();
                }

            private:
                std::unique_ptr<GameState> state;
                StateCondition conditions;
        };
        
        constexpr const char* StateTypeToString(StateTypes state_type){
            switch (state_type) {
                case Core::Gameplay::StateTypes::Idle: return "Idle";
                case Core::Gameplay::StateTypes::Judge: return "Judge";
                case Core::Gameplay::StateTypes::Playing: return "Playing";
                case Core::Gameplay::StateTypes::WaitingForPlayers: return "Waiting";
                case Core::Gameplay::StateTypes::Error: return "Error";
            }
        }

        constexpr StateTypes StringToStateType(std::string state_string){
            if (state_string == "Idle"){
                return StateTypes::Idle;
            } else if (state_string == "Judge"){
                return StateTypes::Judge;
            }else if (state_string == "Playing"){
                return StateTypes::Playing;
            }else if (state_string == "Waiting") {
                return StateTypes::WaitingForPlayers;
            }else {
                return StateTypes::Error; 
            }
            
        }

    }

}
