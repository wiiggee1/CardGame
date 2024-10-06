#include <boost/asio.hpp>
#include <iostream>
#include "CLI/App.hpp"
#include "CLI/CLI.hpp"
#include "game_cli.hpp"
#include "states.hpp"
#include "game.hpp"

using namespace Core;

int main(int argc, char **argv){

    /* 
     * -NOTE: --> Check the CLI flags and create the generic 'Game' class depending on 'got_subcommand'
     */

    Game apples2apples; 
    CLI11_PARSE(apples2apples.cli_menu.app, argc, argv);

    /* Will initialize / allocate the network component pointer as either a 'Client' or 'Server' */
    //apples2apples.test_logic();
    apples2apples.create_session();
    apples2apples.setup_game();
    //apples2apples.start_gameloop(); 

    return 0;
}
