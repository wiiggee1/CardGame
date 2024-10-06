#include <memory>
#define BOOST_TEST_MODULE MyTest

#include <boost/test/included/unit_test.hpp>
#include <boost/test/tools/interface.hpp>
#include <boost/test/unit_test_suite.hpp>
#include <boost/test/unit_test.hpp>

#include "CLI/App.hpp"
#include <CLI/CLI.hpp>
#include "game.hpp"
#include "events.hpp"
#include "game_cli.hpp"
#include "host.hpp"
#include "joingame_state.hpp"
#include "judge_state.hpp"
#include "network/client.hpp"
#include "network/server.hpp"
#include "network/message.hpp"
#include "play_state.hpp"
#include "player.hpp"
#include "states.hpp"
#include "config.h"

#include <iostream>
#include <typeinfo>

using namespace boost::unit_test;
using namespace Core::Gameplay;

BOOST_AUTO_TEST_SUITE(test1_suite)


    BOOST_AUTO_TEST_CASE(PlayerStateTransistionTest){

        // DEBUGGING THE STATE TRANSITION LOGIC BELOW:
        //Core::Player player;
        //player.setup_context(std::make_unique<PlayingState>());
        //BOOST_CHECK_EQUAL(player.get_context(), std::make_unique<PlayerState>());

        /*
        Core::Game apples2apples;
        auto state = apples2apples.get_session_as<Core::Player>();
        std::cout << "Current Player session has a ptr value of: " << state << std::endl;
        //BOOST_CHECK_EQUAL(apples2apples.get_session_as<Core::Player>(), typeid(Core::Player));

        state->get_context() = std::make_unique<Context>(std::make_unique<PlayerState>());
        std::cout << "Initialized context to Playing state, with a ptr value of: " << state->get_context().get() << std::endl;
        state->get_context()->active_state();
        state->get_context()->execute_state();

        // --------------------------------
        auto* player = state->get_context().get();
        BOOST_CHECK_EQUAL(state, nullptr);

        player->set_state(std::make_unique<JudgeState>());
        std::cout << "Changing to Judge state, with a Context ptr value of: " << player << std::endl;
       
        player->active_state();
        player->execute_state();
        
        player->set_state(std::make_unique<PlayerState>());
        std::cout << "Changing state back to Playing state, with a Context ptr value of: " << player << std::endl;
        player->active_state();
        player->execute_state();
        */
    }

    BOOST_AUTO_TEST_CASE(PlayerTestReadWrite){
        std::cout << "Attempting to write to Server..." << std::endl;
        //network->send_message("This is a Player message TEST!");

        /*
        boost::asio::const_buffer buffer_test = "this is a test payload"_buf;
        std::cout << "byte array data:" << buffer_test.data() << std::endl;
        std::cout << "byte array data size:" << buffer_test.size() << std::endl;
        
        auto byte_array = boost::asio::buffer("this is a test payload!");
        std::cout << "byte array data: " << byte_array.data() << std::endl;
        const char* char_data = static_cast<const char*>(byte_array.data());
        std::string buffer_info = std::format("Byte data: {}, Char data: {}", byte_array.data(), char_data);
        std::cout << buffer_info << std::endl;
        */
        
        /*
        Network::Message msg;
        msg.type = Network::MessageType::Request;
        msg.rpc_type = Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Network::serialize_message(msg);
        get_network_as<Network::Client>()->send_message_test(byte_message);
        //get_network_as<Network::Client>()->send_message("This is a Player message TEST!");
        */
    }

    BOOST_AUTO_TEST_CASE(MessageSerializationTest){
       
        /*
        std::cout << "Running test_serialization logic: \n" << std::endl;
        Core::Network::Message msg;
        msg.type = Core::Network::MessageType::Request;
        msg.id = 1234;
        msg.rpc_type = Core::Network::RPCType::DealCard;
        msg.payload = "This is a Player message test!";
        auto byte_message = Core::Network::serialize_message(msg);

        std::cout << "Testing deserialization logic: \n" << std::endl;
        auto decoded_msg = Core::Network::deserialize_message(byte_message);
        */
        
    }


BOOST_AUTO_TEST_SUITE_END()

