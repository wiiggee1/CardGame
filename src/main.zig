const std = @import("std");
const settings = @import("settings");
const logging = @import("log.zig");

// const GameConfig = @import("game").GameConfig; 
// const Game = @import("game").Game(GameConfig);
const GameConfig = @import("game.zig").GameConfig; 
const Game = @import("game.zig").Game(GameConfig);

// pub const log_level: std.log.Level = .debug; 
pub const std_options: std.Options = logging.custom_log_options; 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit(); 
    
    // var game_obj = try setup_game(allocator);
    var game_obj = try setup_game_v2(allocator);
    defer game_obj.deinit();
    game_obj.gameloop();
    
    // try game.read_config("data/redApples.txt", "red_apples");
}

fn setup_game(allocator: std.mem.Allocator) !Game{
    std.log.info("Setting up the GameConfig Now!\n", .{});
    var game_config = try GameConfig.parse_args(allocator);

    // defer game_config.deinit(allocator); // This would free the allocated `id` field. 
    try game_config.print(.DebugLogging, .{});

    var game_obj = try Game.init(allocator, game_config); 
    try game_obj.setup(allocator);
    return game_obj;
}

fn setup_game_v2(allocator: std.mem.Allocator) !Game{
    std.log.info("Setting up the GameConfig Now!\n", .{});

    var game_obj = try Game.init_v2(allocator); 
    try game_obj.setup(allocator);
    return game_obj;
}

test {
    // _ = @import("game.zig");
    _ = @import("game.zig"); 
    _ = @import("game_state/game_state.zig"); 
    std.testing.refAllDecls(@This()); 

    // _ = game_state; 
    // std.testing.refAllDeclsRecursive(@This()); 
}

