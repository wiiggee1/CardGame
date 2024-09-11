#pragma once

#include "events.hpp"
#include "game_cli.hpp"
#include "host.hpp"
#include "network/client.hpp"
#include "network/network_component_interface.hpp"
#include "network/server.hpp"
#include "player.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <atomic>
#include <boost/asio/ip/tcp.hpp>
#include <memory>
#include <queue>
namespace Core {
    
    class Game{
        
        private:
            std::unique_ptr<SessionType> session;
            std::shared_ptr<Gameplay::EventHandler> event_queue;
            std::atomic<int> player_count = 0;

        protected:
            
        public:
            Game();
            GameCLI cli_menu;

             /**
             * Method for getting the pointer of a specific SessionType derived class (Player, Host).
             * @brief Dynamic type casting for accessing derived class methods.
             * @see get_session_as()
             */
            template<typename T>
            T* get_session_as() {
                return dynamic_cast<T*>(session.get());
            }

            template<typename T>
            T* create_session_as() {
                this->session = std::make_unique<T>();
                return dynamic_cast<T*>(session.get());
            }


            /**
             * Method for setting up the game, such as calling various setup-related methods like loading cards.
             * @brief Setup method.
             * @see setup_game()
             */
            void setup_game();

            /**
             * Method for creating a game session, by adding game and network components. 
             * As either a hosting server or as a client (player).
             * @brief Game session creation method.
             * @see create_session()
             */
            void create_session();

            boost::asio::ip::tcp::endpoint create_endpoint();

            /**
             * Method that act as a pass by reference for loading the game config data to a specific target_data. 
             * Where 'target_data' is our game cards. 
             */
            void load_config_to(const std::string config_filepath, std::vector<std::string>& target_data);

            /**
             * Sets atomic varible to true and create a std::thread that runs waiting for player logic
             */
            void enter_game();

            void setup_eventcallbacks();

            void process_events();

            void process_input();

            void start_gameloop();

            void increment_playercount() {
                this->player_count++;
            }

            bool playercount_condition() {
                return player_count.load() >= 4;
            }

    };
    
}
