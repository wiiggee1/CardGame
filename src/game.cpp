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

    Game::Game() {
        cli_menu.setup_arg_parser();
    }

    void Game::setup_game(){
        std::cout << "Setting up the game, please wait for all players to connect..." << std::endl;
       
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


            /* Setting up the host session, by calling neccessary async operations for the Server */
            //host->setup_session();
            session->setup_session();

            /* Starts the session by running the io_context.run() in a separate thread */
            std::thread server_thread([this](){
                //auto host = get_session_as<Host>();
                this->session->run_session();
            });
            
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

            //TODO: - Fix how to initialize the starting context state. 
            
            //player->get_context()->set_state(std::make_unique<Gameplay::JoinGameState>());
            //player->get_context() = std::make_unique<Gameplay::Context>(std::make_unique<Gameplay::JoinGameState>());
            player->setup_context(std::make_unique<Gameplay::JoinGameState>());

            //player->setup_session();
            session->setup_session();

            /* Starts the session by running the io_context.run() in a separate thread */
            std::thread client_thread([this](){
                this->session->run_session();
            });

            std::cout << "Tests for serialization, state transition, readwrite operation after running io_context.run()" << std::endl;

            /* Just testing writing and reading payload messages between server and client */
            //player->test_serialization();
            //test_state_transitions();            
            //player->test_readwrite_communication();

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


    void Game::enter_game(){
        
    }

    void Game::setup_eventcallbacks(){
        //auto event_queue = Game::getEventHandler();
        event_handler->add_callback(Gameplay::Event::PlayerJoined, [this](){
                if(this->cli_menu.host_server == true){
                    auto session = get_session_as<Host>();
                    auto server = session->get_network_as<Network::Server>();
                    auto clients = server->get_clients();
                    auto client_count = session->get_client_count();

                    if(startgame_condition(clients.size()) == true){
                        this->event_handler->push_event(Gameplay::Event::GameReady); 
                    }else{
                        auto count_str = std::format("Current player count: {}", clients.size());
                        for (auto client : clients){
                            auto msg = Network::create_message(
                                    Network::MessageType::Request,
                                    Network::RPCType::NewConnection,
                                    count_str);
                            auto byte_message = Network::serialize_message(msg);
                            client->write_to_client(byte_message);
                        }
                    } 
                }else if (this->cli_menu.host_server == false){

                }
        });
        event_handler->add_callback(Gameplay::Event::GameReady, [this](){
            if(this->cli_menu.host_server == true){
                auto session = get_session_as<Host>();
                session->loadgame_request(); //host sends RPCType::LoadGame to all clients
            }
        });

        event_handler->add_callback(Gameplay::Event::CardPlayed, [this](){

        });

        event_handler->add_callback(Gameplay::Event::SynchronizeGame, [this](){
            if(this->cli_menu.host_server == false){
                auto player = this->get_session_as<Player>();
                player->synchronize_game(); 
            }
        });

        event_handler->add_callback(Gameplay::Event::CardReceived, [this](){
            if(this->cli_menu.host_server == false){
                auto player = this->get_session_as<Player>();
                auto received_msg = this->event_handler->get_last_message();

                if(!received_msg.payload.empty() && received_msg.rpc_type == Network::RPCType::DealCard){
                    auto cards = Network::split_string(received_msg.payload, ',');
                    for (std::string card: cards){
                        player->add_card(card); 
                    }
                }
                
            }
        });


        // Add more under... But should trigger these in process_event or should it be triggered using:
        // context->event_handler() = state->on_event()... 
    }

    void Game::process_events(){
        while (!this->event_handler->empty()) {
            Gameplay::Event event = event_handler->pop_event();

            if(this->cli_menu.host_server == true){
                auto session = get_session_as<Host>();
                // Define event handling for the Host class
                this->event_handler->trigger_event(event); // Requries to add_callback to map first.

            }else {
                auto session = get_session_as<Player>();
                auto& context = session->get_context();
                //session->get_context()->event_handler(event);
                
                // Dereference the sessions unique_ptr<Network>
                context->event_handler(event);
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
        //WARN: 
        // - Should periodically checks for updates, and monitor conditions or atomic variables.
        // - Transitions to another state when the condition is met.
        
        while(true) {

            //std::cout << "\033[2J\033[H"; // Clear screen and move cursor to top

            // This method should push input events to the event queue. By polling and capturing input events
            process_input();

            // This method should handle the core logic of the current game state. Its called every frame.
            session->run_state();

            process_events();

            //Dereference of the unique pointer, to get the context and the current state. 
            //this->event_handler.process_event(*session->get_context());
           
            
        }
    }
}
