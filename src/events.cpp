#include "events.hpp"

namespace Core {
    namespace Gameplay{


        void EventHandler::push_event(Event event){
            std::lock_guard<std::mutex> lock(queue_mutex);
            this->event_queue.push(event);
        }

        Event EventHandler::pop_event(){
            std::lock_guard<std::mutex> lock(queue_mutex);
            if (event_queue.empty()) {
                throw std::runtime_error("No events to process");
            }

            Event event = event_queue.front();
            this->event_queue.pop();
            return event;
        }

        bool EventHandler::empty() {
            std::lock_guard<std::mutex> lock(queue_mutex);
            return this->event_queue.empty();
        }

        void EventHandler::add_callback(Event event, std::function<void()> callback) {
            this->callbacks[event] = callback;
        }

        void EventHandler::trigger_event(Event event) {
            if (this->callbacks.find(event) != this->callbacks.end()){
                this->callbacks[event]();
            }
        }

    } 
}