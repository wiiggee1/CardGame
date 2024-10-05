#pragma once

#include <cstdint>
#include <string>
#include <sstream>
#include <iostream>
#include <vector>

namespace Core {
    namespace Network {

        #define ANSI_BOLD "\x1b[1m"
        #define ANSI_COLOR_RESET "\x1b[0m"
        #define ANSI_COLOR_GREEN "\x1b[32m"
        #define ANSI_COLOR_RED "\x1b[31m"
        #define ANSI_COLOR_BLUE "\x1b[34m"
        #define ANSI_COLOR_YELLOW "\x1b[33m"
        #define ANSI_COLOR_CYAN "\x1b[36m"
        #define ANSI_COLOR_WHITE "\x1b[37m"

        #define ANSI_UNDERLINE_GREEN "\x1b[4;32m"
        #define ANSI_UNDERLINE_RED "\x1b[4;31m"
        #define ANSI_UNDERLINE_BLUE "\x1b[4;34m"
        #define ANSI_UNDERLINE_YELLOW "\x1b[4;33m"
        #define ANSI_UNDERLINE_CYAN "\x1b[4;36m"

        #define ANSI_BOLD_GREEN "\x1b[1;32m"
        #define ANSI_BOLD_RED "\x1b[1;31m"
        #define ANSI_BOLD_BLUE "\x1b[1;34m"
        #define ANSI_BOLD_YELLOW "\x1b[1;33m"
        #define ANSI_BOLD_CYAN "\x1b[1;36m"
        
        //NOTE: - Should I add additional types such as if its a 'Card' = string type, or int type...?
        enum class MessageType : uint8_t {
            Request = 1, 
            Response = 2
        };

        enum class RPCType : uint8_t {
            DealCard,
            Vote,
            NewConnection,
            StartGame,
            PlayCard,
            LoadGame, //Initializing the game, server send cards to players.
            EnterWaiting, // Enter waiting (idle) state for waiting for judge to vote.
        };

        struct Message{
            MessageType type;
            RPCType rpc_type;
            std::string payload;
        };

        Message create_message(MessageType msg_type, RPCType rpc_type, std::string payload);

        std::vector<uint8_t> serialize_message(const Message& message);

        /** 
         * This method will parse the string and return a valid Message struct object...
         * */
        Message deserialize_message(const std::vector<uint8_t>& data_bytes);

        void print_message(const Message& message);
        void print_subsection(const std::string &title, std::string content, const std::string &title_color, const std::string &content_color);

        std::string get_string_message(const Message& message);
        void print_bytemessage(const std::vector<uint8_t>& data_bytes);
        std::string join_strings(const std::vector<std::string>& vec, char delimiter);
        std::vector<std::string> split_string(const std::string& str, char delimiter);
    }
}



