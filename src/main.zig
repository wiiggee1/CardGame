const std = @import("std");
const base = @import("game");

const Game = base.Game(); 
const GameConfig = base.GameConfig; 
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit(); 

    var game_config = try GameConfig.parse_args(allocator);
    defer game_config.deinit(allocator); // This would free the allocated `id` field. 
    try game_config.print();

    // std.debug.print("Args received: hosting={}, id={s}, ip={s}, num_bots={d}, num_player={d}, port={d}\n", .{ args.hosting, args.id, args.ip, args.num_bots, args.num_player, args.port });
    
    // var game = try Game.init(allocator, args);
    // defer game.deinit();
    // try game.read_config("data/redApples.txt", "red_apples");

}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    std.debug.print("Before list.deinit: {*}\n", .{&list.allocator});
    defer {
        list.deinit(); // try commenting this out and see if zig detects the memory leak!
    }
    std.debug.print("After list.deinit: {*}\n", .{&list.allocator});
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
