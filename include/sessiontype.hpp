#pragma once

#include "network/network_component_interface.hpp"
#include <memory>
#include <utility>
namespace Core {
   
     /** 
      * Interface class for adding/initializing what session type and priveleges, the current running game session should have. E.g., if it has Player/Client memebers or Server priveleges. 
      */
    class SessionType{

        public:
            virtual ~SessionType() = default;
            virtual void setup_session() = 0;
            virtual void run_session() = 0;

            template<typename T>
            T* get_network_as() {
                return dynamic_cast<T*>(network.get());
            }

            SessionType& add_network_component(std::unique_ptr<NetworkComponentInterface> network_component){
                this->network = std::move(network_component);
                return *this;
            }

        protected:
            /* Either as a client- or server network component. */
            std::unique_ptr<NetworkComponentInterface> network; 
    };
}
