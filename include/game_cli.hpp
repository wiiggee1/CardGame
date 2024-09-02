#pragma once

#include <string>
#include "CLI/App.hpp"
#include "CLI/CLI.hpp"

namespace Core{

    struct GameCLI{
        CLI::App app;
        bool host_server = false;
        int num_players = 0;
        int num_bots = 0;
        std::string player_id;
        std::string ip_address;
        int port;
        
        void setup_arg_parser();
        void run_parser(int argc, char** argv);
    };

}
