#pragma once 

#include <functional>
#include <iostream>
#include <map>
#include <mutex>
#include <queue>
#include <typeinfo>

namespace Core {
    namespace Gameplay{

        enum class Event {
            UserInput,
            NetworkMessage,
            PlayerJoined,
            StartGame,
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

            private:
                std::queue<Event> event_queue;
                mutable std::mutex queue_mutex;
                std::map<Event, std::function<void()>> callbacks;
                /*
                 *  while (!eventQueue.empty()) {
                        Event event = eventQueue.front();
                        eventQueue.pop();
                        context->getState()->handle(context, event);
                    }
                 */
                //std::thread listener(eventListener, &context);

        };
    }
}
