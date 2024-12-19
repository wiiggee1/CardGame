#pragma once

#include "events.hpp"
#include "game_cli.hpp"
#include "network/client.hpp"
#include "network/network_component_interface.hpp"
#include "network/server.hpp"
#include "player.hpp"
#include "sessiontype.hpp"
#include "states.hpp"
#include <atomic>
#include <boost/asio/ip/tcp.hpp>
#include <cstddef>
#include <map>
#include <memory>
#include <queue>
namespace Core {
  
    //TODO: - Wrap into own header file...
    
    /// Game Rules settings: 
    struct GameRules{
        /// Number of non bot players
        int expected_players;
        int num_bots;
        int points_to_win; 
        std::string game_mode;
    };
    GameRules new_gamerules(int num_player, int num_bots, std::string game_mode);

    /// Game round data.
    struct GameData{
        /// If a player/bot has played its card of the round. 
        bool card_played = false;
        /// Flag if a certain player/bot is a judge. 
        bool is_judge = false;
        /// total collected points (for all the rounds). 
        int points = 0;
        /// Current round number. 
        int round_number = 0;
    };

    struct GameState{
        std::map<unsigned short, GameData> player_data; // The key = client port
    };

    class Game{
        
        private:
            std::unique_ptr<SessionType> session;
            static std::shared_ptr<Gameplay::EventHandler> event_handler;
            static GameRules rules;
            static GameState game_state;

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

            template<typename T, typename... Args>
            T* create_session_as(Args&&... args) {
                this->session = std::make_unique<T>(std::forward<Args>(args)...);
                return dynamic_cast<T*>(session.get());
            }

            /* Static method to access shared EventHandler resource during the liftime of program running. */
            static std::shared_ptr<Gameplay::EventHandler> getEventHandler(){
                return event_handler;
            }

            static GameRules& getGameRules(){
                return rules;
            }

            static GameState& getGameState(){
                return game_state;
            }
            

            /**
             * Method for setting up the game, such as calling various setup-related methods like loading cards.
             * @brief Setup method.
             * @see setup_game()
             */
            void setup_game();
            void apply_gamerules(GameRules game_rules);

            /**
             * Method for creating a game session, by adding game and network components. 
             * As either a hosting server or as a client (player).
             * @brief Game session creation method.
             * @see create_session()
             */
            void create_session();

            //TODO: - Create a bot entitiy
            void add_bots(int num_bots);

            void test_logic();

            boost::asio::ip::tcp::endpoint create_endpoint();

            /**
             * Method that act as a pass by reference for loading the game config data to a specific target_data. 
             * Where 'target_data' is our game cards. 
             */
            void load_config_to(const std::string config_filepath, std::vector<std::string>& target_data);

            void setup_eventcallbacks();
            //void setup_game_callbacks();

            void process_events();

            void render_game(const std::string &update_string, const std::string &update_value);

            void process_input();

            void start_gameloop();

            bool startgame_condition(size_t num_client) {
                return num_client >= 4;
            }

    };
    
}
