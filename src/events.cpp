#include "events.hpp"
#include <memory>
#include <mutex>
#include <tuple>

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

        bool EventHandler::eventmsg_empty(){
            std::lock_guard<std::mutex> lock(eventmsg_mutex);
            return this->eventmsg_queue.empty();
        }

        void EventHandler::add_callback(Event event, std::function<void()> callback) {
            this->callbacks[event] = callback;
        }

        void EventHandler::trigger_event(Event event) {
            if (this->callbacks.find(event) != this->callbacks.end()){
                this->callbacks[event]();
            }
        }

        void EventHandler::store_message(const Network::Message& message){
            std::lock_guard<std::mutex> lock(message_mutex);
            message_queue.push(message);
        }

        void EventHandler::store_eventmessage(Event event, const Network::Message& message){
            std::lock_guard<std::mutex> lock(eventmsg_mutex);
            auto event_message = std::make_tuple(event, message);
            this->eventmsg_queue.push(event_message);
        }

        void EventHandler::pop_eventmessage(){
            std::lock_guard<std::mutex> lock(eventmsg_mutex);
            if(!eventmsg_queue.empty()){
                eventmsg_queue.pop();
            }
        }

        std::tuple<Event, Network::Message> EventHandler::get_eventmessage(){
            std::lock_guard<std::mutex> lock(eventmsg_mutex);
            if(!eventmsg_queue.empty()){
                auto [event, message] = eventmsg_queue.front();
                eventmsg_queue.pop();
                return std::make_tuple(event, message);
            }
            return {};
        }

        Network::Message EventHandler::get_last_message(){
            std::lock_guard<std::mutex> lock(message_mutex);
            if (!message_queue.empty()){
                auto msg = message_queue.front();
                message_queue.pop();
                return msg;
            }
            return {};
        }

        Event EventHandler::read_latest_event(){
            std::lock_guard<std::mutex> lock(eventmsg_mutex);
            if(!eventmsg_queue.empty()){
                auto [event, message] = eventmsg_queue.front();
                return event;
            }
            return {};
        }


    } 
}
