#include "game.hpp"
#include "CLI/App.hpp"
#include "game_cli.hpp"
#include "host.hpp"
#include "joingame_state.hpp"
#include "judge_state.hpp"
#include "network/client.hpp"
#include "network/server.hpp"
#include "play_state.hpp"
#include "player.hpp"
#include "states.hpp"
#include "config.h"

#include <boost/asio/executor_work_guard.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/address.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <thread>
#include <vector>

namespace Core{
   
    Game::Game(){
        cli_menu.setup_arg_parser();
        //this->state_context = nullptr;
    }

    void Game::setup_game(){
        std::cout << "Setting up the game, please wait for all players to connect..." << std::endl;
       
    }

    //WARN: This is only for testing the state transitions and how the pointers behave and change during runtime!
    void Game::test_state_transitions(){
        // DEBUGGING THE STATE TRANSITION LOGIC BELOW: 

        std::cout << "session ptr address: " << session.get() << std::endl;


        auto state = get_session_as<Player>();
        std::cout << "Current Player session has a ptr value of: " << state << std::endl;

        state->get_context() = std::make_unique<Gameplay::Context>(std::make_unique<Gameplay::PlayerState>());
        std::cout << "Initialized context to Playing state, with a ptr value of: " << state->get_context().get() << std::endl;
        state->get_context()->active_state();
        state->get_context()->execute_state();

        // --------------------------------
        auto* player = state->get_context().get();
        
        player->set_state(std::make_unique<Gameplay::JudgeState>());
        std::cout << "Changing to Judge state, with a Context ptr value of: " << player << std::endl;
        player->active_state();
        player->execute_state();
        
        player->set_state(std::make_unique<Gameplay::PlayerState>());
        std::cout << "Changing state back to Playing state, with a Context ptr value of: " << player << std::endl;
        player->active_state();
        player->execute_state();
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
            host->get_network_as<Network::Server>()->set_callback([this](){
                    std::cout << "This callback is invoked whenever a new client has joined!" << std::endl;
                    auto nr_clients = this->session->get_network_as<Network::Server>()->get_clients().size();
                    std::cout << "Number of connected Clients: " << nr_clients << std::endl;
            });

            auto [red_cards, green_cards] = host->get_cards();
            std::string config_path = CONFIG_FILE_PATH;
            load_config_to(config_path+"redApples.txt", red_cards);
            load_config_to(config_path+"greenApples.txt", green_cards);

            //host->show_cards(CardType::RED);
            //std::cout << "Green apple cards stored: " << std::endl;
            //host->show_cards(CardType::GREEN);

            /* Setting up the host session, by calling neccessary async operations for the Server */
            //host->setup_session();
            session->setup_session();

            
            std::thread server_thread([this](){
                //auto host = get_session_as<Host>();
                this->session->run_session();
            });
            
            
            /* Starts the session by running the io_context.run() */
            //host->run_session();
            //session->run_session();
           
            std::cout << "This is an IO output after running io_context.run()..." << std::endl;
            server_thread.join();


        } else if (this->cli_menu.app.got_subcommand("join")){
            std::cout << "Welcome to Apples 2 Apples - Joining game, please wait [CLIENT]..." << std::endl;
            this->cli_menu.host_server = false;
             // TODO: Fix parse logic for the port, now hard coded to 2048...
            this->cli_menu.port = 2048;
            
            //auto host_address = this->cli_menu.ip_address;
            boost::asio::io_context io_context_;
            auto host_address = create_endpoint().address().to_string();
            auto* player = create_session_as<Player>();
            player->add_network_component(std::make_unique<Network::Client>(io_context_, host_address, this->cli_menu.port));

            player->get_context()->set_state(std::make_unique<Gameplay::JoinGameState>()); 

            test_state_transitions();

            //player->setup_session();
            session->setup_session();

            //player->test_readwrite_communication();
            //player->test_serialization();

            std::thread client_thread([this](){
                this->session->run_session();
            });

            /* Starts the session by running the io_context.run() */
            //player->run_session();

            std::cout << "This is an IO test to server after running io_context.run()..." << std::endl;

            /* Just testing writing and reading payload messages between server and client */
            player->test_readwrite_communication();

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

    void Game::request_number_of_joined(){
        //TODO: 
        //  1. Send message to server to get number of clients 
        //  2. Update the atomic player_count for the Game class 
        //  3. Check if the number of players condition is satisfied

        while (!start_condition.load()){
            if (playercount_condition()){
                // All players have joined 
                auto& conditions = this->get_session_as<Player>()->get_context()->get_conditions();
                conditions.all_connected = true;
                start_condition = true;
            }else {
                // Request player count again from the server
            }
        }
    }

    void Game::enter_game(){
        //TODO: 
        //1. Send message to host for incrementing player count value
        //2. Check bool for enough players (minimum number of players to start the game)
        
        this->waiting = true;
        this->waitingplayers_thread = std::thread(&Game::await_players, this);
        //WARN: - Should I add another thread for checking the number of players condition?
    }

    void Game::await_players(){
        auto state = get_session_as<Player>();
        //increment_playercount();
        state->get_context()->execute_state();
        // When atomic bool 'waiting' is false run 'start_gameloop'
        start_gameloop();
    }

    void Game::start_gameloop(){
        //WARN: 
        // - Should periodically checks for updates, and monitor conditions or atomic variables.
        // - Transitions to another state when the condition is met.
        while(!start_condition.load()){

        }
    }
}
