#pragma once 

#include "network/message.hpp"
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <queue>
#include <tuple>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        enum class Event {
            UserInput,
            NetworkMessage,
            PlayerJoined,
            GameStarted,
            NextRound,
            GameReady,
            SynchronizeGame,
            CardPlayed,
            CardReceived,
            StartVote,
            JudgeVoted, // Received Vote
            CardRequest,
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

                bool eventmsg_empty();

                void add_callback(Event event, std::function<void()> callback);
                void trigger_event(Event event);
                void store_message(const Network::Message& message);
                void store_eventmessage(Event event, const Network::Message& message);
                std::tuple<Event, Network::Message> get_eventmessage();
                Network::Message get_last_message();
                Event read_latest_event();

            private:
                std::queue<Event> event_queue;
                mutable std::mutex queue_mutex;

                //WARN: Remove below if eventmsg_queue would not work. 
                std::queue<Network::Message> message_queue;
                mutable std::mutex message_mutex;

                //TODO: - Add a std::queue, with tuple for storing associated message with that event.
                std::queue<std::tuple<Event, Network::Message>> eventmsg_queue;
                mutable std::mutex eventmsg_mutex;

                std::map<Event, std::function<void()>> callbacks;
                
        };
       
    }
}
