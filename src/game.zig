//! The game.zig is a module containing the `game` components and APIs to the application.
//! This Card game, interact with the exposed APIs defined in the sub-module (namespace).
//!
//! If it's not defined in here, it means its private and should not be exposed to the user!
//! ------------------------------------

const std = @import("std");
// pub const game_state = @import("game_state");
const game_state = @import("game_state");
const settings = @import("settings");

const log = std.log.scoped(.game_logic);

pub const GameConfig = settings.GameConfig;
pub const SessionType = settings.SessionType;
pub const Session = settings.Session;

const InternalEvent = game_state.InternalEvent; 
const UserInput = game_state.UserInput; 
const NetworkEvent = game_state.NetworkEvent; 
const Event = game_state.Event; 

const GameState = game_state.GameState; 
const TaskScheduler = game_state.TaskScheduler(Event); 
const TaskCallback = game_state.TaskCallback; 

pub fn Game(comptime Config: type) type{
    if(!std.mem.eql(u8, @typeName(Config), @typeName(GameConfig))){
        @compileError("Passing args to GameConfig needs to be tuple (anonymous struct) type, found " ++ @typeName(Config)); 
    }
    return struct {
        const Self = @This(); 
        allocator: std.mem.Allocator,

        // players: PlayerManager,
        
        /// The game instance is the main owner of the loaded `cards`. 
        /// Whenever cards is dealt to a player, that player becomes 
        /// the new owner of that card. 
        cards: std.StringHashMap(std.ArrayList([]const u8)),
        
        /// The `config` field, represent the args provided when running 
        /// the game. It contains the neccessary data, to setup the game. 
        config: Config,

        state: ?GameState,
        callback_manager: TaskScheduler,
        session: Session,

        pub fn init(allocator: std.mem.Allocator, options: Config) !Self {
            const hashmap = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
            //try hashmap.put("red_apples", null);
            //try hashmap.put("green_apples", null);
            // const new_session = try Session.create(options, allocator);
            
            return Self{
                .allocator = allocator,
                // .players = PlayerManager.init(allocator),
                .cards = hashmap,
                .config = options,
                .state = null,
                .callback_manager = .init(allocator),
                .session = try Session.create(options, allocator), 
            };
        }

        pub fn deinit(self: *Self) void {
            self.config.deinit(self.allocator); 
            self.cards.deinit();
        }


        pub fn setup(self: *Self, allocator: std.mem.Allocator) !void {
            const session_kind = self.session.get_sessiontype(); 

            switch (session_kind) {
                .Host => {
                    if (self.config.points_to_win == null){
                        try self.config.update_config(allocator);
                    }else {
                        log.warn("Game Config has already been updated. Continuing!\n", .{});
                    }
                    // self.session = .create(SessionType.Host, self.config, self.allocator);
                },
                .Client => {
                    // Client and player setup below...
                    // self.session = .create(SessionType.Client, self.config, self.allocator);
                }
            }

        }


        /// Handles external input events. Should iterate or switch over
        /// a dedicated `UserInput` event type. Thus map an external input 
        /// event into an internal event that should trigger a task(callback + context). 
        /// ---------------------------
        /// External Input Event → Action → Internal Event → Task(callback + context) → `run_task()`. 
        pub fn handle_input(self: *Self, input: UserInput) !void {
            const event = try Event.parse(input);
            try self.state.?.handle_event(Game(GameConfig), self, event);
        }

        /// Static callback function setup. 
        pub fn setup_callback(self: *Self) !void {
            const event_fields: []const std.builtin.Type.UnionField = std.meta.fields(Event);
            _ = self; 
            _ = event_fields; 
            // inline for (event_fields) |event_kind| {
            //     // const info = @typeInfo(event_kind.type);
            //     switch (event_kind.type) {
            //         InternalEvent => {
            //             const field_names = std.meta.fieldNames(InternalEvent);
            //             for (field_names) |event_name| {
            //                 const name: []const u8 = event_name; 
            //                 const internal_event = InternalEvent.fromString(name);
            //                 if (internal_event) |event| {
            //                     switch (event) {
            //
            //                     }
            //                 }
            //             }
            //         },
            //
            //     }
            // }
            // self.callback_manager.register(., cb: TaskCallback)
        }

        //TODO: - Delegate and move this logic to GameState - self.state.handle_event()
        pub fn dispatchTask(ctx: *anyopaque, input_kind: anytype) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            const input_event: ?Event = try Event.parse(input_kind) orelse null; 

            if (input_event) |event| {
                switch (event) {
                    .event => |internal_event| {
                        switch (internal_event) {
                            .StartGame => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = start_game, 
                                });
                            },
                            .StartAsJudge => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = new_judge, 
                                });
                            },
                            .ClientConnected => {
                                // try self.session.Host.players.?.add(Player{.name = "", .id = 1337}); 
                                try self.session.Host.net.notify_clients("Client Connected!"); 
                            },
                            .ClientExited => {
                                try self.session.Host.net.notify_clients("Client disconnected!"); 
                            }, 
                            .PlayedCard => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = play_card, 
                                });
                            },
                            .ReceivedCard => {
                                self.session.Client.player.?.add_card("Random Card: ..."); 
                            },
                            .JudgeVoted => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = vote_callback, 
                                });
                            },
                            .GameOver => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = gameover, 
                                });
                            }, 
                            .NextRound => {
                                self.callback_manager.enqueue_task(TaskCallback{
                                    .ctx = self,
                                    .func = next_round, 
                                });
                            },
                        }
                        
                    },
                    .user_input => |user_action| {
                        user_action.parse();
                    },
                    .network => |network_event| {
                        const event_id = network_event.id; 
                        const payload = network_event.payload; 
                        _ = event_id; 
                        _ = payload; 
                    }
                }
            }
        }

        pub fn play_card(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'play_card' Callback!\n", .{});
        }

        pub fn vote_callback(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'vote_callback' Callback!\n", .{});
        }
        
        pub fn start_game(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'start_game' Callback!\n", .{});
        }

        pub fn gameover(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'gameover' Callback!\n", .{});
        }

        pub fn new_judge(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'new_judge' Callback!\n", .{});
        }
        
        pub fn next_round(ctx: *anyopaque) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            _ = &self; 
            log.debug("Running 'next_round' Callback!\n", .{});
        }

        /// This is the main gameloop when running the game. It should execute in the following order:
        /// 1. Listen for user inputs (process inputs). 
        /// 2. Update game state (modify player object instance).
        /// 3. Render / Draw terminal / GUI. 
        pub fn gameloop(self: *Self) void {
            const stdout = std.io.getStdOut().writer();
            const stdin = std.io.getStdIn().reader(); 
            _ = stdout; 
            _ = stdin; 
            _ = self; 
            // while(true)...
        }

        /// Read game config files, passing string as path.
        /// The `key` arg, represent the type of card you want to load. 
        /// E.g., "red_apples" or "green_apples"...
        /// -------------------------------
        /// File descriptor serve as the communication channel
        /// between the kernel-space system calls for I/O operations.
        /// - A file descriptor (FD) is a process-unique identifier
        ///   (handle) for a file or other input/output resource.
        ///   Such as a pipe or network socket.
        pub fn read_config(self: *Self, path: []const u8, key: []const u8) !void {
            var card_buf = std.ArrayList([]const u8).init(self.allocator); 

            defer {
                if (!self.cards.contains(key)) {
                    card_buf.deinit();
                }
            }
            
            if (!self.cards.contains(key)) {
                try self.cards.put(key, card_buf);
            }

            const file_handler = try std.fs.cwd().openFile(path, .{});
            defer file_handler.close();

            var buf_reader = std.io.bufferedReader(file_handler.reader());
            var in_stream = buf_reader.reader();

            var temp_buf: [1024]u8 = undefined; // temporary line buffer.

            while (try in_stream.readUntilDelimiterOrEof(&temp_buf, '\n')) |line| {
                const line_str = try self.allocator.dupe(u8, line);
                log.debug("Card line: {s}\n", .{line_str});
                try card_buf.append(line_str);
                // Ownership of `line_str` now belongs to `card_buffer`.
            }

            // const hashmap_size = self.cards.count();
            // return card_buffer.*;
        }


    };

}


test {
    std.testing.refAllDecls(@This()); 
    _ = @import("game_state"); 
    // _ = game_state; 
    // std.testing.refAllDeclsRecursive(@This()); 
}

test "apply_config" {
    log.info("Testing applying the config!\n", .{});
    const allocator = std.testing.allocator;

    const test_cases: []const u8 = &.{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}; 
    for(test_cases) |test_count| {
        const test_config = GameConfig{
            .hosting = true,
            .ip = GameConfig.DEFAULT_IP,
            .port = GameConfig.DEFAULT_PORT,
            .num_players = test_count,
        };
        std.log.scoped(.itr_start).debug("\nGameConfig Before...\n", .{});
        var game = try Game(GameConfig).init(allocator, test_config);
        try game.config.print(true);

        defer game.deinit(); 
        try game.setup(allocator); 

        std.log.scoped(.str_part).debug("\nGameConfig After Setup...\n", .{});
        try game.config.print(true);
        std.log.scoped(.str_part).debug("num_players (test_count) = {d}, yields num_bots = {d}, and points_to_win: {?d}\n", .{test_count, game.config.num_bots, game.config.points_to_win}); 
        std.log.scoped(.itr_end).debug("====================================\n", .{});
    }
    try std.testing.expect(true);

}

test "read_cards" {
    const expected: u32 = 4; 
    log.info("Testing reading the config!\n", .{});
    try std.testing.expectEqual(expected, 2 + 2); 
    const allocator = std.testing.allocator;
    _ = allocator; 

    // var test_config = GameConfig.default; 
    // test_config.hosting = true;  
    // test_config.num_players = 2; 

    // const test_args = GameConfig{
    //     .hosting = true,
    //     // .id = "TheVeryBest",
    //     .ip = GameConfig.DEFAULT_IP,
    //     .port = GameConfig.DEFAULT_PORT,
    //     // .num_bots = 0,
    //     .num_players = 2,
    // };
    
    // var game = try Game(GameConfig).init(allocator, test_config);
    // defer game.deinit();

    // try game.read_config("data/redApples.txt", "red_apples");
    //
    // for (game.cards.get("red_apples").?.items) |card| {
    //     std.debug.print("Card as slice: {s}\n", .{card});
    // }
    try std.testing.expect(true);

}

test "simple sanity check" {
    try std.testing.expect(true);
}
