#include "game_cli.hpp"
#include <CLI/CLI.hpp>
#include <CLI/App.hpp>
#include <vector>

namespace Core{
    
    void GameCLI::setup_arg_parser(){
        auto host_subcommand = app.add_subcommand("host", "Host a server");
        host_subcommand->add_option("-n, --number-players", num_players, "Number of players for the hosting game");
        host_subcommand->add_option("-b,--number-bots", num_bots, "Number of bots for the hosting game");
        host_subcommand->add_option("--ip", ip_address, "IP address endpoint, for the hosting server");
        host_subcommand->add_option("--port", port, "Server Port, for the hosting game");


        auto join_subcommand = app.add_subcommand("join", "Joining a hosted game server");
        join_subcommand->add_option("-p,--player-id", player_id, "Unique player id for the joining player");        
        join_subcommand->add_option("--ip", ip_address, "IP address endpoint to connect to");
        join_subcommand->add_option("--port", port, "Server Port, for the hosting game");

    }

    void GameCLI::run_parser(int argc, char** argv){
        //CLI11_PARSE(this->app, argc, argv);
    }
}
