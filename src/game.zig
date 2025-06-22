//! The game.zig is a module containing the `game` components and APIs to the application.
//! This Card game, interact with the exposed APIs defined in the sub-module (namespace).
//!
//! If it's not defined in here, it means its private and should not be exposed to the user!
//! ------------------------------------

const std = @import("std");
const player = @import("player");
const events = @import("events"); 
const states = @import("states");
const scheduler = @import("task_scheduler");
const cli = @import("cli");

pub const GameConfig = cli.GameConfig; // Should be public for exposing to main.zig. 
pub const SessionType = cli.SessionType;
pub const Session = cli.Session;

// The player related API, should be private and only exposed within the Game Module. 
const Player = player.Player;
const PlayerManager = player.PlayerManager;

const InternalEvent = events.InternalEvent; 
const UserInput = events.UserInput; 
const NetworkEvent = events.NetworkEvent; 
const Event = events.Event; 
const GameState = states.GameState; 

const TaskScheduler = scheduler.TaskScheduler(Event); 
const TaskCallback = scheduler.TaskCallback; 


pub fn Game(comptime Config: GameConfig) type{
    return struct {
        const Self = @This(); 

        allocator: std.mem.Allocator,

        players: PlayerManager,
        
        /// The game instance is the main owner of the loaded `cards`. 
        /// Whenever cards is dealt to a player, that player becomes 
        /// the new owner of that card. 
        cards: std.StringHashMap(std.ArrayList([]const u8)),
        
        /// The `config` field, represent the args provided when running 
        /// the game. It contains the neccessary data, to setup the game. 
        config: Config,

        state: GameState,
        callback_manager: TaskScheduler,
        session: Session,

        /// This field is dependent on the GameConfig instance.
        /// -------------------------------------------------
        /// It depend on the number of total players (num_players + num_bots).
        /// You win the game according to the following cases: 
        /// • 4 players → 8 green apples win. 
        /// • 5 players → 7 green apples. 
        /// • 6 players → 6 green apples. 
        /// • 7 players → 5 green apples. 
        /// • 8+ players → 4 green apples. 
        /// -------------------------------------------------
        points_to_win: ?u8 = null,

        pub fn init(allocator: std.mem.Allocator, options: Config) !Self {
            const hashmap = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
            //try hashmap.put("red_apples", null);
            //try hashmap.put("green_apples", null);
            
            return Self{
                .allocator = allocator,
                .players = PlayerManager.init(allocator),
                .cards = hashmap,
                .config = options,
                .session = Session.create(options, allocator), 
            };
        }

        pub fn deinit(self: *Self) void {
            self.config.deinit(self.allocator); 
            self.cards.deinit();
        }

        fn add_bots(self: *Self) !void {
            if (self.config.num_players) |num_players|{
                if (num_players < 4){
                    const diff: u8 = 4 - num_players; // should not be negative, check if num_players is less than 3 or 4.  
                    const clamp_diff: u8 = std.math.clamp(diff, 0, 4);
                    std.debug.print("diff: {d} vs clamp diff: {d}\n", .{diff, clamp_diff}); 
                    if (clamp_diff == 0) self.config.num_bots = 0 else self.config.num_bots = clamp_diff; 
                }
            }else {
                return error.NumberPlayersMissing; 
            }
        }

        fn apply_rules(self: *Self) !void {
            if (self.config.num_players != null){
                const total_playing: u8 = self.config.num_players.? + self.config.num_bots.?;
                std.debug.print("total_playing = {d}\n", .{total_playing}); 
                std.debug.print("num_bots = {d}\n", .{self.config.num_bots.?}); 
                std.debug.print("num_players = {d}\n", .{self.config.num_players.?}); 
                std.debug.print("====================================\n", .{});
                self.points_to_win = switch (total_playing) {
                    0, 1, 2, 3 => return error.TooFewPlayers,
                    4 => 8,
                    5 => 7,
                    6 => 6,
                    7 => 5,
                    8...10 => 4,
                    else => return error.TooManyPlayers,
                };

            }else {
                // try self.config.print();
                return error.ConfigMissingPlayerCount; 
            }
        }

        pub fn setup(self: *Self) !void {
            const session_kind = self.session.get_sessiontype(); 
            // const session_kind = try SessionType.try_from(self.config); 

            switch (session_kind) {
                .Host => {
                    try self.add_bots(); 
                    try self.apply_rules();  
                    self.session = .create(SessionType.Host, self.config, self.allocator);
                },
                .Client => {
                    // Client and player setup below...
                    self.session = .create(SessionType.Client, self.config, self.allocator);
                }
            }

        }


        /// Handles external input events. Should iterate or switch over
        /// a dedicated `UserInput` event type. Thus map an external input 
        /// event into an internal event that should trigger a task(callback + context). 
        /// ---------------------------
        /// External Input Event → Action → Internal Event → Task(callback + context) → `run_task()`. 
        pub fn handle_input(self: *Self, input: UserInput) !void {
            _ = self; 
            _ = input; 
        }

        /// Static callback function setup. 
        pub fn setup_callback(self: *Self) !void {
            const event_fields: []const std.builtin.Type.UnionField = std.meta.fields(Event);

            for (event_fields) |event_kind| {
                // const info = @typeInfo(event_kind.type);
                switch (event_kind.type) {
                    InternalEvent => {
                        const field_names = std.meta.fieldNames(InternalEvent);
                        for (field_names) |event_name| {
                            const name: []const u8 = event_name; 
                            const internal_event = InternalEvent.fromString(name);
                            if (internal_event) |event| {
                                switch (event) {
                                    
                                }
                            }
                        }
                    },
                    
                }
                // Event.tryIntoInternalEvent(self: Event) 
                // Event.parse();
            }

            
            // self.callback_manager.create_task(Session, ctx: ?*anyopaque)
            // self.callback_manager.register(., cb: TaskCallback)
        }

        //TODO: - Can I use input argument as anytype here??????
        pub fn run_task_any(ctx: *anyopaque, any_input: anytype) !void {
            // var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 
            var self: *Self = @ptrCast(@alignCast(ctx)); 
            
            const event = try Event.parse(any_input);
            const internal_event = event.tryIntoInternalEvent() orelse return error.MappingInputToInternalEventFailed;
            switch (internal_event) {
                .StartGame => void, 
                .StartAsJudge => void, 
                .ClientConnected => void,
                .ClientExited => void, 
                .PlayedCard => self.play_card(), 
                .ReceivedCard => void,
                .JudgeVoted => self.vote_callback(), 
                .GameOver => void, 
                .NextRound => void,
            }
            
        }
        

        pub fn run_task(ctx: *anyopaque, event: Event) !void {
            var self: *Game(Config) = @ptrCast(@alignCast(ctx)); 

            //WARN: - Do I need to register static callbacks like this? 
            // self.callback_manager.register(event: E, cb: TaskCallback)

            
            //WARN: - Or should I create new TaskCallback for each cases 
            // in the switch statement? Then add to queue. (SEE BELOW!)

            const new_task = TaskCallback{.ctx = self, .func = self.start_game};
            // TaskCallback.from(Game(Config), ctx: ?*anyopaque)

            self.callback_manager.task_queue.append(.{ .data =  .{ .task =  new_task}}); 

            switch (event) {
                .event => |internal_event| {
                    switch (internal_event) {
                        .StartGame => self.start_game(), 
                        .StartAsJudge => self.new_judge(), 
                        .ClientConnected => {
                            try self.session.Host.players.?.add(Player{.name = "", .id = 1337}); 
                            try self.session.Host.net.notify_clients("Client Connected!"); 
                        },
                        .ClientExited => void, 
                        .PlayedCard => self.play_card(), 
                        .ReceivedCard => self.session.Client.player.?.add_card("Random Card: ..."),
                        .JudgeVoted => self.vote_callback(), 
                        .GameOver => self.gameover(), 
                        .NextRound => self.next_round(),
                    }
                    
                },
                .user_input => |user_action| {
                    user_action.parse();
                }
            }
        }

        pub fn play_card(self: *Self) !void {
            _ = self; 
        }

        pub fn vote_callback(self: *Self) !void {
            _ = self; 
        }
        
        pub fn start_game(self: *Self) !void {
            _ = self; 
        }

        pub fn gameover(self: *Self) !void {
            _ = self; 
        }

        pub fn new_judge(self: *Self) !void {
            _ = self; 
        }
        
        pub fn next_round(self: *Self) !void {
            _ = self; 
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
                std.debug.print("Card line: {s}\n", .{line_str});
                try card_buf.append(line_str);
                // Ownership of `line_str` now belongs to `card_buffer`.
            }

            // const hashmap_size = self.cards.count();
            // return card_buffer.*;
        }
    };
}

test "apply_config" {
    const allocator = std.testing.allocator;
    const test_cases: []const u8 = &.{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}; 
    for(test_cases) |test_count| {
        const test_config = GameConfig{
            .hosting = true,
            // .id = "TheVeryBest",
            .ip = GameConfig.DEFAULT_IP,
            .port = GameConfig.DEFAULT_PORT,
            // .num_bots = 0,
            .num_players = test_count,
        };
        try test_config.print();
        var game = try Game().init(allocator, test_config);
        defer game.deinit(); 
        try game.setup(); 

        std.debug.print("num_players (test_count) = {?d}, gave points_to_win: {?d}\n", .{test_config.num_players, game.points_to_win}); 
    }


}

test "setup_session" {

}

test "read_cards" {
    const expected: u32 = 4; 
    std.debug.print("Testing reading the config!\n", .{});
    try std.testing.expectEqual(expected, 2 + 2); 
    const allocator = std.testing.allocator;

    const test_args = GameConfig{
        .hosting = true,
        // .id = "TheVeryBest",
        .ip = GameConfig.DEFAULT_IP,
        .port = GameConfig.DEFAULT_PORT,
        // .num_bots = 0,
        .num_players = 2,
    };

    var game = try Game().init(allocator, test_args);
    defer game.deinit();
    // try game.read_config("data/redApples.txt", "red_apples");
    //
    // for (game.cards.get("red_apples").?.items) |card| {
    //     std.debug.print("Card as slice: {s}\n", .{card});
    // }
}
