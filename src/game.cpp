#include "game.hpp"
#include "CLI/App.hpp"
#include "events.hpp"
#include "game_cli.hpp"
#include "host.hpp"
#include "joingame_state.hpp"
#include "judge_state.hpp"
#include "network/client.hpp"
#include "network/message.hpp"
#include "network/server.hpp"
#include "play_state.hpp"
#include "player.hpp"
#include "states.hpp"
#include "config.h"

#include <boost/asio/executor_work_guard.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/address.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace Core{
 
    std::shared_ptr<Gameplay::EventHandler> Game::event_handler = std::make_shared<Gameplay::EventHandler>();
    GameRules Game::rules;
    GameState Game::game_state;

    GameRules new_gamerules(int num_player, int num_bots, std::string game_mode){
        GameRules rules; 
        rules.expected_players = num_player;
        rules.num_bots = num_bots;
        rules.game_mode = game_mode;
        auto total_players = num_player + num_bots;

        if (total_players == 4){
            rules.points_to_win = 8;
        }else if (total_players == 5){
            rules.points_to_win = 7;
        }else if (total_players == 6){
            rules.points_to_win = 6;
        }else if (total_players == 7){
            rules.points_to_win = 5;
        }else if (total_players > 7){
            rules.points_to_win = 4;
        }
        return rules;
    } 

    Game::Game() {
        cli_menu.setup_arg_parser();
        //setup_eventcallbacks();
    }

    void Game::setup_game(){
        std::cout << "Setting up the game, and game rules. Please wait for players to connect..." << std::endl;
        GameRules rules;  
        auto active_subcommand = this->cli_menu.app.get_subcommand("host");

        if (!(active_subcommand->get_option("--number-players")->empty())){
            if (this->cli_menu.num_players < 4){
                if (this->cli_menu.num_players == 1){
                    rules = new_gamerules(this->cli_menu.num_players, 3, "default");
                }else if (this->cli_menu.num_players == 2){
                    rules = new_gamerules(this->cli_menu.num_players, 2, "default");
                }else if (this->cli_menu.num_players == 3){
                    rules = new_gamerules(this->cli_menu.num_players, 1, "default");
                }
                
            }else{
                // Number of players flag > 4, then num_bots = 0
                rules = new_gamerules(this->cli_menu.num_players, 0, "default");
            }
        }else{
            rules = new_gamerules(1, 3, "default");  
        }

        if (this->cli_menu.app.got_subcommand("host")){
            apply_gamerules(rules);
        }
    }

    void Game::apply_gamerules(GameRules game_rules){
        std::string rules_string = std::format("Game Rules: \nNumber of player = {}\nNumber of bots = {}\nPoints to win = {}\nMode = {}", 
                game_rules.expected_players, 
                game_rules.num_bots, 
                game_rules.points_to_win, 
                game_rules.game_mode);
        
        std::cout << rules_string << std::endl;
        this->rules = game_rules;

        add_bots(game_rules.num_bots);
    }

    void Game::add_bots(int num_bots){
        // TODO: - Fix add_bots logic, maybe define a struct containing: 
        // a 'GameData' field, bot id, red_cards, and green_cards.
    }

    void Game::test_logic(){
        std::cout << "Running test_serialization logic: \n" << std::endl;
        Core::Network::Message msg;
        msg.type = Core::Network::MessageType::Request;
        msg.id = 1234;
        msg.rpc_type = Core::Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Core::Network::serialize_message(msg);

        std::cout << "Testing deserialization logic: \n" << std::endl;
        auto decoded_msg = Core::Network::deserialize_message(byte_message);
    }

    void Game::create_session(){

         if (this->cli_menu.app.got_subcommand("host")){
            std::cout << "Welcome to Apples 2 Apples - Hosting server now [SERVER]..." << std::endl;
            this->cli_menu.host_server = true;
            
            // TODO: Fix parse logic for the port, now hard coded to 2048...
            this->cli_menu.port = 2048;

            boost::asio::io_context io_context_;
            auto* host = create_session_as<Host>();
            auto endpoint = create_endpoint();
            host->add_network_component(std::make_unique<Network::Server>(io_context_, endpoint));
            

            auto [red_cards, green_cards] = host->get_cards();
            std::string config_path = CONFIG_FILE_PATH;
            load_config_to(config_path+"redApples.txt", red_cards);
            load_config_to(config_path+"greenApples.txt", green_cards);
            host->shuffle_cards();

            /* Setting up the host session, by calling neccessary async operations for the Server */
            //host->setup_session();
            session->setup_session();

            /* Starts the session by running the io_context.run() in a separate thread */
            std::thread server_thread([this](){
                //auto host = get_session_as<Host>();
                this->session->run_session();
            });
            
            setup_eventcallbacks();
            start_gameloop();

            server_thread.join();

        } else if (this->cli_menu.app.got_subcommand("join")){
            std::cout << "Welcome to Apples 2 Apples - Joining game, please wait [CLIENT]..." << std::endl;
            this->cli_menu.host_server = false;
             // TODO: Fix parse logic for the port, now hard coded to 2048...
            this->cli_menu.port = 2048;
            
            //auto host_address = this->cli_menu.ip_address;
            boost::asio::io_context io_context_;
            auto host_address = create_endpoint().address().to_string();
            
            //auto* player = create_session_as<Player>();
            auto* player = create_session_as<Player>(Gameplay::JoinGameState::create_instance());

            player->add_network_component(std::make_unique<Network::Client>(io_context_, host_address, this->cli_menu.port));

            //player->get_context() = std::make_unique<Gameplay::Context>(std::make_unique<Gameplay::JoinGameState>());
            //player->setup_context(std::make_unique<Gameplay::JoinGameState>());
            //player->setup_context(Gameplay::JoinGameState::create_instance());
            //player->get_context()->set_state(Gameplay::JoinGameState::create_instance());
            
            //player->setup_context(Gameplay::JoinGameState::create_instance());

            //player->setup_session();
            session->setup_session();

            /* Starts the session by running the io_context.run() in a separate thread */
            std::thread client_thread([this](){
                this->session->run_session();
            });

            //player->request_cards(7);
            setup_eventcallbacks();
            start_gameloop();

            client_thread.join();
        }

    }

    boost::asio::ip::tcp::endpoint Game::create_endpoint(){
        auto subcommand = [this]() -> CLI::App*{
            auto host_subcommand = this->cli_menu.app.get_subcommand("host");
            auto join_subcommand = this->cli_menu.app.get_subcommand("join");

            if (host_subcommand->parsed()){
                return host_subcommand; 
            }else if (join_subcommand->parsed()){
                return join_subcommand;
            }
            return nullptr;
        };

        auto active_subcommand = subcommand();
        if (!(active_subcommand->get_option("--ip")->empty())){
            // If the option --ip was passed we create a specific endpoint to this address 
            if (this->cli_menu.ip_address == "localhost"){
                this->cli_menu.ip_address = "127.0.0.1";
            }
            std::cout << "--ip option was passed as hosting address: " << this->cli_menu.ip_address << std::endl; 
            auto endpoint_addr = boost::asio::ip::make_address(this->cli_menu.ip_address); 
            return boost::asio::ip::tcp::endpoint(endpoint_addr, this->cli_menu.port);

        }else {
            // This would listen on all IPv4 addresses (e.g., '0.0.0.0:port')
            std::cout << "--ip flag was empty, so listening on all v4 addresses (0.0.0.0:PORT) at specifed port... " << std::endl; 
            return boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v4(), this->cli_menu.port);
        }
    }

    void Game::load_config_to(const std::string config_filepath, std::vector<std::string>& target_data){
        std::filesystem::path config_path = config_filepath;
        std::ifstream config_file(config_path);
        std::vector<std::string> cards;
        
        if (!config_file.is_open()){
            std::cerr << "Failed to load game config file: " << config_path << std::endl;
        }

        std::string card_string; 
        while (std::getline(config_file, card_string)){
            cards.push_back(card_string);
            target_data.push_back(card_string);
        }
        config_file.close();
    }

    //TODO: - Wrap the event callback logic to Player or Host method for more clean code:

    void Game::setup_eventcallbacks(){
        if(this->cli_menu.host_server == true){
            auto session = get_session_as<Host>();
            session->setup_host_callbacks();
            
        }else if (this->cli_menu.host_server == false){
            auto player = this->get_session_as<Player>();
            player->setup_player_callbacks();
        }
    }

    void Game::process_events(){
        while (!this->event_handler->eventmsg_empty()) {
            std::cout << "Event message Queue is not empty, processing events..." << std::endl;
            //auto [event, message] = event_handler->get_eventmessage(); // This would pop from the queue. 
            auto event = event_handler->read_latest_event(); // Do not pop, just read front of queue.
            if(this->cli_menu.host_server == true){
                auto session = get_session_as<Host>();
                // Define event handling for the Host class
                this->event_handler->trigger_event(event); // Requries to add_callback to map first.
                std::cout << "Event in queue: " << Gameplay::EventToString(event) << std::endl;
            }else {
                //NOTE: - Should I handle the events here in 'process_event()' or in each unique state?                
                std::cout << "Event in queue: " << Gameplay::EventToString(event) << std::endl;                
                auto session = get_session_as<Player>();
                auto& context = session->get_context();
                context->event_handler(event);
                //this->event_handler->trigger_event(event);
            }
        }
    }

    void Game::render_game(const std::string &update_string, const std::string &update_value){
        //std::cout << std::setw(1) << std::left << ANSI_BOLD << ANSI_COLOR_GREEN <<  get_endpoint_stringz() << ANSI_COLOR_RESET << "" <<  std::endl;

        std::stringstream ss;
        std::string status_string = std::format("{}: {}", update_string, update_value);
        ss << "| GAME MENU | \n";
        ss << "1. Play Card\n" << "2. Show Cards\n";
        ss << "Game points: " << this->get_session_as<Player>()->get_points() << "\n";
        ss << status_string;

        std::cout << ss.str() << std::endl;
    }

    //TODO: - Add a double buffering for current and next frame.
    // So in the background the next frame is being loaded and updated. 
    // Once the next frame is fully rendered the two buffers are swapped. 

    void Game::process_input(){
        //TODO: - Handle user inputs, where user input generate events that are processed by the game loop.
        //std::cout << "In 'process_input'" << std::endl;
        auto player = get_session_as<Player>();

        char input;
        std::cin >> input;
        if (!std::cin.fail()){
            switch (input) {
                case '1':{
                    // Should move to a new submenu showing the available cards... 
                    
                    break;
                }
                case '2':{
                    // Outputs the red cards in the array.
                    std::string red_cards = player->show_cards();
                    render_game("Red apple cards", red_cards);
                    break;
                }
                default: 
                    std::cout << "Invalid option, try again!" << std::endl;
            }
        }
        std::cin.clear();
    }

    void Game::start_gameloop(){
        while(true) {

            //std::cout << "\033[2J\033[H"; // Clear screen and move cursor to top

            // This method should push input events to the event queue. By polling and capturing input events
            
            if(this->cli_menu.host_server == false){
                //process_input();
                
                // This method should handle the core logic of the current game state. Its called every frame.
                session->run_state();
            }

            process_events();
        }
    }
}
