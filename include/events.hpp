#pragma once 

#include "network/message.hpp"
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <queue>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        enum class Event {
            UserInput,
            NetworkMessage,
            PlayerJoined,
            GameStarted,
            GameReady,
            SynchronizeGame,
            CardPlayed,
            CardReceived,
            JudgeVoted,
            // Define more under...
        };

        class Context;

        class EventHandler {
            public: 
                void push_event(Event event);
                Event pop_event();
                bool empty();

                std::queue<Event> queue(){
                    return this->event_queue;
                }

                void add_callback(Event event, std::function<void()> callback);
                void trigger_event(Event event);
                void store_message(const Network::Message& message);
                Network::Message get_last_message();

            private:
                std::queue<Event> event_queue;
                mutable std::mutex queue_mutex;

                std::queue<Network::Message> message_queue;
                mutable std::mutex message_mutex;

                std::map<Event, std::function<void()>> callbacks;
                
        };
       
    }
}
