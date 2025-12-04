const std = @import("std");

pub const Player = struct {
    id: ?u16,
    name: ?[]const u8,
    red_cards: std.ArrayList([]const u8) = .empty,
    green_cards: std.ArrayList([]const u8) = .empty,
    
    pub fn new(id: ?u16, name: ?[]const u8, allocator: std.mem.Allocator) Player {
        _ = allocator;
        return Player{
            .id = id,
            .name = name,
            // .red_cards = std.ArrayList([]const u8).init(allocator), 
            // .green_cards = std.ArrayList([]const u8).init(allocator), 
            .red_cards = .empty, 
            .green_cards = .empty, 
        }; 
    }

    // pub fn add_card(self: *Player, card: []const u8, allocator: std.mem.Allocator) !void {
    //     _ = self; 
    //     _ = card; 
    // }

    pub fn add_red(self: *Player, card: []const u8, allocator: std.mem.Allocator) !void {
        self.red_cards.append(allocator, card);
    }

    pub fn add_green(self: *Player, card: []const u8, allocator: std.mem.Allocator) !void {
        self.green_cards.append(allocator, card);
    }
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
