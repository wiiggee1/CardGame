# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.31

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/wiiggee1/Desktop/School/homeexam_d7032e

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/wiiggee1/Desktop/School/homeexam_d7032e

# Include any dependencies generated for this target.
include CMakeFiles/apples2apples.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/apples2apples.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/apples2apples.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/apples2apples.dir/flags.make

CMakeFiles/apples2apples.dir/codegen:
.PHONY : CMakeFiles/apples2apples.dir/codegen

CMakeFiles/apples2apples.dir/src/events.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/events.cpp.o: src/events.cpp
CMakeFiles/apples2apples.dir/src/events.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/apples2apples.dir/src/events.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/events.cpp.o -MF CMakeFiles/apples2apples.dir/src/events.cpp.o.d -o CMakeFiles/apples2apples.dir/src/events.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/events.cpp

CMakeFiles/apples2apples.dir/src/events.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/events.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/events.cpp > CMakeFiles/apples2apples.dir/src/events.cpp.i

CMakeFiles/apples2apples.dir/src/events.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/events.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/events.cpp -o CMakeFiles/apples2apples.dir/src/events.cpp.s

CMakeFiles/apples2apples.dir/src/game.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/game.cpp.o: src/game.cpp
CMakeFiles/apples2apples.dir/src/game.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object CMakeFiles/apples2apples.dir/src/game.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/game.cpp.o -MF CMakeFiles/apples2apples.dir/src/game.cpp.o.d -o CMakeFiles/apples2apples.dir/src/game.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game.cpp

CMakeFiles/apples2apples.dir/src/game.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/game.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game.cpp > CMakeFiles/apples2apples.dir/src/game.cpp.i

CMakeFiles/apples2apples.dir/src/game.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/game.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game.cpp -o CMakeFiles/apples2apples.dir/src/game.cpp.s

CMakeFiles/apples2apples.dir/src/game_cli.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/game_cli.cpp.o: src/game_cli.cpp
CMakeFiles/apples2apples.dir/src/game_cli.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object CMakeFiles/apples2apples.dir/src/game_cli.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/game_cli.cpp.o -MF CMakeFiles/apples2apples.dir/src/game_cli.cpp.o.d -o CMakeFiles/apples2apples.dir/src/game_cli.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game_cli.cpp

CMakeFiles/apples2apples.dir/src/game_cli.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/game_cli.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game_cli.cpp > CMakeFiles/apples2apples.dir/src/game_cli.cpp.i

CMakeFiles/apples2apples.dir/src/game_cli.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/game_cli.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/game_cli.cpp -o CMakeFiles/apples2apples.dir/src/game_cli.cpp.s

CMakeFiles/apples2apples.dir/src/host.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/host.cpp.o: src/host.cpp
CMakeFiles/apples2apples.dir/src/host.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object CMakeFiles/apples2apples.dir/src/host.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/host.cpp.o -MF CMakeFiles/apples2apples.dir/src/host.cpp.o.d -o CMakeFiles/apples2apples.dir/src/host.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/host.cpp

CMakeFiles/apples2apples.dir/src/host.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/host.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/host.cpp > CMakeFiles/apples2apples.dir/src/host.cpp.i

CMakeFiles/apples2apples.dir/src/host.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/host.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/host.cpp -o CMakeFiles/apples2apples.dir/src/host.cpp.s

CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o: src/joingame_state.cpp
CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o -MF CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o.d -o CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/joingame_state.cpp

CMakeFiles/apples2apples.dir/src/joingame_state.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/joingame_state.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/joingame_state.cpp > CMakeFiles/apples2apples.dir/src/joingame_state.cpp.i

CMakeFiles/apples2apples.dir/src/joingame_state.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/joingame_state.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/joingame_state.cpp -o CMakeFiles/apples2apples.dir/src/joingame_state.cpp.s

CMakeFiles/apples2apples.dir/src/judge_state.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/judge_state.cpp.o: src/judge_state.cpp
CMakeFiles/apples2apples.dir/src/judge_state.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object CMakeFiles/apples2apples.dir/src/judge_state.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/judge_state.cpp.o -MF CMakeFiles/apples2apples.dir/src/judge_state.cpp.o.d -o CMakeFiles/apples2apples.dir/src/judge_state.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/judge_state.cpp

CMakeFiles/apples2apples.dir/src/judge_state.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/judge_state.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/judge_state.cpp > CMakeFiles/apples2apples.dir/src/judge_state.cpp.i

CMakeFiles/apples2apples.dir/src/judge_state.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/judge_state.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/judge_state.cpp -o CMakeFiles/apples2apples.dir/src/judge_state.cpp.s

CMakeFiles/apples2apples.dir/src/main.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/main.cpp.o: src/main.cpp
CMakeFiles/apples2apples.dir/src/main.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object CMakeFiles/apples2apples.dir/src/main.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/main.cpp.o -MF CMakeFiles/apples2apples.dir/src/main.cpp.o.d -o CMakeFiles/apples2apples.dir/src/main.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/main.cpp

CMakeFiles/apples2apples.dir/src/main.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/main.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/main.cpp > CMakeFiles/apples2apples.dir/src/main.cpp.i

CMakeFiles/apples2apples.dir/src/main.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/main.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/main.cpp -o CMakeFiles/apples2apples.dir/src/main.cpp.s

CMakeFiles/apples2apples.dir/src/network/client.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/network/client.cpp.o: src/network/client.cpp
CMakeFiles/apples2apples.dir/src/network/client.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building CXX object CMakeFiles/apples2apples.dir/src/network/client.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/network/client.cpp.o -MF CMakeFiles/apples2apples.dir/src/network/client.cpp.o.d -o CMakeFiles/apples2apples.dir/src/network/client.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/client.cpp

CMakeFiles/apples2apples.dir/src/network/client.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/network/client.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/client.cpp > CMakeFiles/apples2apples.dir/src/network/client.cpp.i

CMakeFiles/apples2apples.dir/src/network/client.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/network/client.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/client.cpp -o CMakeFiles/apples2apples.dir/src/network/client.cpp.s

CMakeFiles/apples2apples.dir/src/network/message.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/network/message.cpp.o: src/network/message.cpp
CMakeFiles/apples2apples.dir/src/network/message.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Building CXX object CMakeFiles/apples2apples.dir/src/network/message.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/network/message.cpp.o -MF CMakeFiles/apples2apples.dir/src/network/message.cpp.o.d -o CMakeFiles/apples2apples.dir/src/network/message.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/message.cpp

CMakeFiles/apples2apples.dir/src/network/message.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/network/message.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/message.cpp > CMakeFiles/apples2apples.dir/src/network/message.cpp.i

CMakeFiles/apples2apples.dir/src/network/message.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/network/message.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/message.cpp -o CMakeFiles/apples2apples.dir/src/network/message.cpp.s

CMakeFiles/apples2apples.dir/src/network/server.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/network/server.cpp.o: src/network/server.cpp
CMakeFiles/apples2apples.dir/src/network/server.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_10) "Building CXX object CMakeFiles/apples2apples.dir/src/network/server.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/network/server.cpp.o -MF CMakeFiles/apples2apples.dir/src/network/server.cpp.o.d -o CMakeFiles/apples2apples.dir/src/network/server.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/server.cpp

CMakeFiles/apples2apples.dir/src/network/server.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/network/server.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/server.cpp > CMakeFiles/apples2apples.dir/src/network/server.cpp.i

CMakeFiles/apples2apples.dir/src/network/server.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/network/server.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/server.cpp -o CMakeFiles/apples2apples.dir/src/network/server.cpp.s

CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o: src/network/session_connections.cpp
CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_11) "Building CXX object CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o -MF CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o.d -o CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/session_connections.cpp

CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/session_connections.cpp > CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.i

CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/network/session_connections.cpp -o CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.s

CMakeFiles/apples2apples.dir/src/play_state.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/play_state.cpp.o: src/play_state.cpp
CMakeFiles/apples2apples.dir/src/play_state.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_12) "Building CXX object CMakeFiles/apples2apples.dir/src/play_state.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/play_state.cpp.o -MF CMakeFiles/apples2apples.dir/src/play_state.cpp.o.d -o CMakeFiles/apples2apples.dir/src/play_state.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/play_state.cpp

CMakeFiles/apples2apples.dir/src/play_state.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/play_state.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/play_state.cpp > CMakeFiles/apples2apples.dir/src/play_state.cpp.i

CMakeFiles/apples2apples.dir/src/play_state.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/play_state.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/play_state.cpp -o CMakeFiles/apples2apples.dir/src/play_state.cpp.s

CMakeFiles/apples2apples.dir/src/player.cpp.o: CMakeFiles/apples2apples.dir/flags.make
CMakeFiles/apples2apples.dir/src/player.cpp.o: src/player.cpp
CMakeFiles/apples2apples.dir/src/player.cpp.o: CMakeFiles/apples2apples.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_13) "Building CXX object CMakeFiles/apples2apples.dir/src/player.cpp.o"
	ccache /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/apples2apples.dir/src/player.cpp.o -MF CMakeFiles/apples2apples.dir/src/player.cpp.o.d -o CMakeFiles/apples2apples.dir/src/player.cpp.o -c /home/wiiggee1/Desktop/School/homeexam_d7032e/src/player.cpp

CMakeFiles/apples2apples.dir/src/player.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/apples2apples.dir/src/player.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/wiiggee1/Desktop/School/homeexam_d7032e/src/player.cpp > CMakeFiles/apples2apples.dir/src/player.cpp.i

CMakeFiles/apples2apples.dir/src/player.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/apples2apples.dir/src/player.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/wiiggee1/Desktop/School/homeexam_d7032e/src/player.cpp -o CMakeFiles/apples2apples.dir/src/player.cpp.s

# Object files for target apples2apples
apples2apples_OBJECTS = \
"CMakeFiles/apples2apples.dir/src/events.cpp.o" \
"CMakeFiles/apples2apples.dir/src/game.cpp.o" \
"CMakeFiles/apples2apples.dir/src/game_cli.cpp.o" \
"CMakeFiles/apples2apples.dir/src/host.cpp.o" \
"CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o" \
"CMakeFiles/apples2apples.dir/src/judge_state.cpp.o" \
"CMakeFiles/apples2apples.dir/src/main.cpp.o" \
"CMakeFiles/apples2apples.dir/src/network/client.cpp.o" \
"CMakeFiles/apples2apples.dir/src/network/message.cpp.o" \
"CMakeFiles/apples2apples.dir/src/network/server.cpp.o" \
"CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o" \
"CMakeFiles/apples2apples.dir/src/play_state.cpp.o" \
"CMakeFiles/apples2apples.dir/src/player.cpp.o"

# External object files for target apples2apples
apples2apples_EXTERNAL_OBJECTS =

apples2apples: CMakeFiles/apples2apples.dir/src/events.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/game.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/game_cli.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/host.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/joingame_state.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/judge_state.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/main.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/network/client.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/network/message.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/network/server.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/network/session_connections.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/play_state.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/src/player.cpp.o
apples2apples: CMakeFiles/apples2apples.dir/build.make
apples2apples: CMakeFiles/apples2apples.dir/compiler_depend.ts
apples2apples: CMakeFiles/apples2apples.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles --progress-num=$(CMAKE_PROGRESS_14) "Linking CXX executable apples2apples"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/apples2apples.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/apples2apples.dir/build: apples2apples
.PHONY : CMakeFiles/apples2apples.dir/build

CMakeFiles/apples2apples.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/apples2apples.dir/cmake_clean.cmake
.PHONY : CMakeFiles/apples2apples.dir/clean

CMakeFiles/apples2apples.dir/depend:
	cd /home/wiiggee1/Desktop/School/homeexam_d7032e && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/wiiggee1/Desktop/School/homeexam_d7032e /home/wiiggee1/Desktop/School/homeexam_d7032e /home/wiiggee1/Desktop/School/homeexam_d7032e /home/wiiggee1/Desktop/School/homeexam_d7032e /home/wiiggee1/Desktop/School/homeexam_d7032e/CMakeFiles/apples2apples.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/apples2apples.dir/depend

