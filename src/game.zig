//! The game.zig is a module containing the `game` components and APIs to the application.
//! This Card game, interact with the exposed APIs defined in the sub-module (namespace).
//!
//! If it's not defined in here, it means its private and should not be exposed to the user!
//! ------------------------------------

const std = @import("std");
const player = @import("player");
const states = @import("states");

pub const GameConfig = @import("cli").GameConfig; // Should be public for exposing to main.zig. 

// The player related API, should be private and only exposed within the Game Module. 
const Player = player.Player;
const PlayerManager = player.PlayerManager;

pub fn Game() type{
    return struct {
        const Self = @This(); 

        allocator: std.mem.Allocator,
        players: PlayerManager,
        /// The game instance is the main owner of the loaded `cards`. 
        /// Whenever cards is dealt to a player, that player becomes 
        /// the new owner of that card. 
        cards: std.StringHashMap(std.ArrayList([]const u8)),
        config: GameConfig,

        pub fn init(allocator: std.mem.Allocator, options: GameConfig) !Self {
            const hashmap = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
            //try hashmap.put("red_apples", null);
            //try hashmap.put("green_apples", null);
            
            return Self{
                .allocator = allocator,
                .players = PlayerManager.init(allocator),
                .cards = hashmap,
                .config = options,
            };
        }

        pub fn deinit(self: *Self) void {
            self.cards.deinit();
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

test "read_config" {
    const expected: u32 = 4; 
    std.debug.print("Testing reading the config!\n", .{});
    try std.testing.expectEqual(expected, 2 + 2); 
    const allocator = std.testing.allocator;


    const test_args = GameConfig{
        .hosting = false,
        .id = "TheVeryBest",
        .ip = "192.168.1.1",
        .port = 3001,
        .num_bots = 0,
        .num_player = 2,
    };

    var game = try Game().init(allocator, test_args);
    defer game.deinit();
    try game.read_config("data/redApples.txt", "red_apples");
    
    for (game.cards.get("red_apples").?.items) |card| {
        std.debug.print("Card as slice: {s}\n", .{card});
    }
}
