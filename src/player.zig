const std = @import("std");

pub const Player = struct {
    id: u8,
    name: []const u8,
    red_cards: ?std.ArrayList([]const u8) = null,
    green_cards: ?std.ArrayList([]const u8) = null,
    
    // The play fn pointer, is the 'behavioral functionality'.
    // play: *const fn(args: anytype) void, 
};

pub const PlayerManager = struct {
    allocator: std.mem.Allocator,
    // players: std.MultiArrayList(Player),
    players: std.StringArrayHashMap(Player),
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return PlayerManager{
            .allocator = allocator,
            // .players = std.MultiArrayList(Player)
            .players = std.StringArrayHashMap(Player).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.players.deinit(); 
    }

    pub fn add(self: *Self, player: Player) !void {
        try self.players.put(player.name, player); 
    }

    pub fn get(self: *Self, id: []const u8) ?Player {
        return self.players.get(id);
    }
};
