//! The cli.zig is a module containing the game config.
//! Which is the arguments passed to the command-line-interface, 
//! whenever executing the game. 
//! ------------------------------------
const std = @import("std");
const server = std.net.Server;
const address = std.net.Address;
const ArgIterator = std.process.ArgIterator;


/// This will provide config options related to the game.
/// It also handles parsing of the arguments passed when executing the game file. 
pub const GameConfig = struct {
    const Self = @This(); // returns the type of the inner most struct.
    pub const DEFAULT_IP: []const u8 = "127.0.0.1"; 
    pub const DEFAULT_PORT: u16 = 0; 

    hosting: bool = false,
    
    /// num_player, option is only valid if you are the host of the game. 
    /// Meaning `hosting` = true. 
    num_players: ?u8 = null,
    
    /// num_bots, option is only valid if you are the host of the game. 
    /// Meaning `hosting` = true. Defining the number of bots, is usally 
    /// done automatically, by checking if the `num_player` is within 
    /// 4-10 players. Else we add the difference as bots. 
    num_bots: u8 = 0,
    
    id: ?[]u8 = null,
    ip: ?[]const u8 = null,
    port: ?u16 = null, // 2048

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

    pub const PrintOptions = enum {
        /// Sets if we should use debug as logging level. 
        DebugLogging,
        /// Compare before and after configuration.
        Compare,
        Default,
    };

    const ArgParsingError = error {
        NeedToBeHost,
        ArgFailed,
        ArgNotValidConfigOption,
        ArgFlagWasNull,
        ArgFlagIsNotStringType,
        FlagWithEmptyValue,
    } || std.fmt.ParseIntError || std.process.GetEnvMapError || std.io.AnyWriter.Error;
    
    pub const default: GameConfig = defaults: {
        break :defaults GameConfig{
            .hosting = false, 
            .ip = "127.0.0.1",
            .port = 2048,
            .num_bots = 0,
        }; 
    };

    /// Checking if parsing is valid, if not it will error. 
    fn check_parsing(self: Self, any: anytype) ArgParsingError!void {
        if(@typeInfo(@TypeOf(any)).@"struct".is_tuple == false){
            @compileError("Passing args to GameConfig needs to be tuple (anonymous struct) type, found " ++ @typeName(@TypeOf(any))); 
        }

        const self_fields = @typeInfo(@TypeOf(self)).@"struct".fields; 
        const arg_fields = @typeInfo(@TypeOf(any)).@"struct".fields; 
        const arg_flag_type = arg_fields[0].type;

        if(arg_flag_type != []const u8) {
            return ArgParsingError.ArgFlagIsNotStringType; 
        }

        const field_exist: bool = exist_blk: {
            inline for(self_fields) |field| {
                const field_name = field.name; 
                if (std.mem.eql(u8, field_name, any[0])){
                    break :exist_blk true; 
                }
            }
            break :exist_blk false; 
        };

        // std.debug.print("field_exist block = {}\n", .{field_exist}); 
        if (!field_exist) return ArgParsingError.ArgNotValidConfigOption; 

        if (self.hosting == false and (std.mem.eql(u8, any[0], "num_players") or std.mem.eql(u8, any[0], "num_bots"))){
            return ArgParsingError.NeedToBeHost; 
        }
                
    }

    /// Should type check the anytype, and map to the correct 
    /// GameCli field based on received type and type name. 
    fn set_field(self: *Self, any: anytype, allocator: std.mem.Allocator) ArgParsingError!void {
        try self.check_parsing(any);

        const flag_name = any.@"0"; 
        const flag_value = any.@"1"; 
        const config_fields = @typeInfo(@TypeOf(self.*)).@"struct".fields; 

        // Iterate through the field names, and check if the passed `any` 
        // has the same name as the field name. If so, we cast, the string 
        // argument to the correct field type. 
        inline for (config_fields) |field| {
            const FieldType: type, const field_name = type_blk: {
                const field_info = @typeInfo(field.type); 
                
                // std.debug.print("Received field type: {any}\n", .{field_info});
                if(field_info == .optional){
                    break :type_blk .{field_info.optional.child, field.name};
                }else {
                    break :type_blk .{field.type, field.name};
                }
            };

            if (std.mem.eql(u8, field_name, flag_name)){
                if(FieldType == bool) {
                    if (std.ascii.eqlIgnoreCase(flag_value, "true")) @field(self, field_name) = true else @field(self, field_name) = false;
                }else if (FieldType == u8 or FieldType == u16){
                    @field(self, field_name) = try std.fmt.parseUnsigned(FieldType, flag_value, 10); 
                }else if (FieldType == []u8){
                    if (std.mem.eql(u8, flag_name, "user") or std.mem.eql(u8, flag_name, "id") or std.mem.eql(u8, flag_name, "username")){
                        self.id = try allocator.dupe(u8, flag_value);
                    }
                }else {
                    @field(self, field_name) = flag_value; 
                }
            }
        }
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if(self.id != null){
            defer allocator.free(self.id.?);
        }
    }

    /// Prints out using stdout the GameConfig and its fields. 
    /// However, using this in a test block, doesnt work with stdout. 
    /// So if we pass the argument parameter `debug_log` as true. 
    /// We would change from stdout filedescriptor to the 
    /// std.log.default type instead. 
    /// ---------------------------------------------
    /// "Don't write to stdout if you are not the main application!"
    /// https://github.com/ziglang/zig/issues/15091#issuecomment-1788192127
    pub fn print(self: Self, options: PrintOptions, comparator: anytype) !void {
        // Use stderr, for error message during debugging and testing. 
        var print_buf: [4096]u8 = undefined;
        var stderr_writer = std.fs.File.stderr().writer(&print_buf);
        const stderr = &stderr_writer.interface;

        const fields = @typeInfo(@TypeOf(self)).@"struct".fields;

        switch(options){
            .DebugLogging => std.log.debug("{s:>5}\n", .{"GameConfig:"}),
            .Compare => {
                if (@TypeOf(comparator) != @TypeOf(self)) return error.TryingToCompareTwoDifferentTypes; 
                try stderr.print("{s:>5}\n", .{"GameConfig - Comparision [BEFORE / AFTER]:"});
                try stderr.flush();
            },
            .Default => {
                try stderr.print("{s:>5}\n", .{"GameConfig:"});
                try stderr.flush();
            },
        }
        

        inline for (fields) |field| {
            const is_modified: bool = outer_blk: {
                if (options == .Compare and @TypeOf(comparator) == @TypeOf(self)){
                    const field_modified: bool = blk: {
                        const is_different = switch (field.type) {
                            []u8, []const u8 => (@field(self, field.name) != @field(comparator, field.name)),
                            ?[]const u8, ?[]u8 => str_blk: {
                                const first = @field(self, field.name) orelse ""; 
                                const second = @field(comparator, field.name) orelse ""; 
                                const same_len = (first.len == second.len);
                                if(same_len and first.len == 0) break :str_blk false; 

                                const match_digit = ((first[0] == second[0]) and (first[first.len - 1] == second[second.len - 1]));
                                break :str_blk if (same_len and match_digit) false else true; 
                            },
                            bool => (@field(self, field.name) != @field(comparator, field.name)),
                            ?u8, ?u16 => case_blk: {
                                const first = @field(self, field.name) orelse 0; 
                                const second = @field(comparator, field.name) orelse 0; 
                                break :case_blk if (first == second) false else true; 
                            },
                            else => (@field(self, field.name) != @field(comparator, field.name)),
                        }; 

                        if (is_different) {
                            break :blk true; 
                        } else {
                            break :blk false; 
                        }
                    };
                    break :outer_blk field_modified; 

                }else {
                    break :outer_blk false; 
                }
            };

            if(is_modified){
                const comparison_format = "\t{s:<15}: " ++ switch (field.type) {
                    []u8, []const u8 => "{s} => {s}\n",
                    ?[]const u8, ?[]u8 => "{?s} => {?s}\n",
                    bool => "{} => {}\n",
                    ?u8, ?u16 => "{?d} => {?d}\n",
                    else => "{any} => {any}\n",
                }; 
                try stderr.print(comparison_format, .{field.name, @field(self, field.name), @field(comparator, field.name)});

            }else {
                const print_format = "\t{s:<15}: " ++ switch (field.type) {
                    []u8, []const u8 => "{s}\n",
                    ?[]const u8, ?[]u8 => "{?s}\n",
                    bool => "{}\n",
                    ?u8, ?u16 => "{?d}\n",
                    else => "{any}\n",
                }; 

                switch(options){
                    .DebugLogging => std.log.scoped(.inner).debug(print_format, .{field.name, @field(self, field.name)}),
                    .Compare => try stderr.print(print_format, .{field.name, @field(self, field.name)}),
                    .Default => try stderr.print(print_format, .{field.name, @field(self, field.name)}),
                }
            }
            try stderr.flush();
        }
    }

    fn help_option() !void {
        var help_buf: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&help_buf);
        const stdout = &stdout_writer.interface;

        try stdout.print("Usage: game setup [options]\n", .{});
        try stdout.print("\t--help\n", .{});
        try stdout.print("\t--hosting <y/n>\n", .{});
        try stdout.print("\t--num_players <int>      Valid number is 1-8+\n", .{});
        try stdout.print("\t--id <str>\n", .{});
        try stdout.print("\t--ip\n", .{});
        try stdout.print("\t--port\n", .{});
        try stdout.flush();
    }

    pub fn parse_args(allocator: std.mem.Allocator) ArgParsingError!Self {
        var args_buf: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&args_buf);
        const stdout = &stdout_writer.interface;

        var args = try std.process.ArgIterator.initWithAllocator(allocator);
        defer args.deinit();
        _ = args.skip(); // First argument is the executable path to file. 

        var game_config = GameConfig{
            // .id = my_username,
            // .ip = "127.0.0.1", 
        }; 
        
        errdefer game_config.deinit(allocator); // if we get an error, we free resources.
        // if (game_config.id != null and game_config.id.? != 0){}
        // std.os.linux.termio{}
         
        while(args.next()) |arg| {
            if (arg.len < 2){
                try stdout.print("No options (flags) passed, using default values!\n", .{});
            }
            if (arg.len < 3){}

            if (std.mem.eql(u8, arg, "--help") or 
                std.mem.eql(u8, arg, "-h") or 
                std.mem.eql(u8, arg, "help")) {
                try help_option(); 
                // allocator.free(env_user); 

                break; 
            }
            
            try stdout.print("arg value: {s}\n", .{arg}); 
            const arg_pair: struct{[]const u8, []const u8} = val_blk: {
                if(std.mem.startsWith(u8, arg, "--")){
                    if (std.mem.containsAtLeastScalar(u8, arg, 1, '=')){
                        var split = std.mem.splitAny(u8, arg, "=");
                        const lhs_flag = split.first(); // Need to call `first()` to advance! 
                        const rhs_value = split.peek();
                        const flag_name = std.mem.trim(u8, lhs_flag, "--");
                        
                        if (rhs_value) |flag_value| {
                            break :val_blk .{flag_name, flag_value};
                        }
                    }else {
                        if(args.next()) |flag_val| {
                            try stdout.print("Found '{s}' flag with associated value: {s}\n", .{arg, flag_val});
                            const flag_name = std.mem.trim(u8, arg, "--");
                            break :val_blk .{flag_name, flag_val};
                        }
                    }
                    return error.FailedRetrevingFlagValue;
                }
                try stdout.flush();
                continue;
            };

            try stdout.print("Resulting flag '{s}' and flag value: '{s}'\n", .{arg_pair.@"0", arg_pair.@"1"});
            try game_config.set_field(arg_pair, allocator);

            // Run different setup depending on if --hosting y or --hosting n. 
            if (std.ascii.eqlIgnoreCase(arg, "--hosting")){}

            try stdout.flush();
        }

        try game_config.update_config(allocator); 
        try game_config.print(.DebugLogging, .{});

        return game_config; 
    }

    //TODO: - Move this, so its not part of the `cli.zig` logic!!!!!!
    pub fn create_socket() !void {
        var stdout_buf: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
        const stdout = &stdout_writer.interface;

        // Setting the port to 0, means the OS will pick the port for us. 
        const addr = try std.net.Address.resolveIp("127.0.0.1", 0); 
        const socket_type = std.posix.SOCK.STREAM;
        const protocol = std.posix.IPPROTO.TCP; 
        const socket = try std.posix.socket(addr.any.family, socket_type, protocol); 
        
        defer std.posix.close(socket); // close the socket (file descriptor). 

        // After socket being closed, we set this socket options so the address-port pair 
        // does not remain in-use. 
        try std.posix.setsockopt(socket, std.posix.SOL.SOCKET, std.posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1))); 
    
        try std.posix.bind(socket, &addr.any, addr.getOsSockLen()); 

        var temp_addr: std.net.Address = undefined; 
        var temp_len: std.posix.socklen_t = @sizeOf(std.net.Address); 

        try std.posix.getsockname(socket, &temp_addr.any, &temp_len);
        try stdout.print("Address: {}\n", .{temp_addr});
        
        const ip_addr = temp_addr.any;
        const addr_port = temp_addr.getPort();
        try stdout.print("Address IP: {}, PORT: {d}\n", .{ip_addr, addr_port});

        try stdout.flush();

    }

    /// This method, should handle missing config fields, by setting them to their default values. 
    /// Or for the case of `num_bots` this is calculated taking the difference. 
    pub fn update_config(self: *Self, allocator: std.mem.Allocator) !void {
        //Set default values below: 
        std.log.info("Trying to Update GameConfig Now!\n", .{}); 

        if(self.id == null and self.hosting == false) {
            // We set the user id initially by searching the env `$USER` on the OS.
            const env_user = try std.process.getEnvVarOwned(allocator, "USER"); //WARN: - Caller owns the returned slice! 
            std.log.debug("Found env variable $USER : {s} as new id.\n", .{env_user}); 
            self.id = env_user; 
        }

        if(self.ip == null) {
            self.ip = GameConfig.DEFAULT_IP; 
        }else {
            if (std.mem.eql(u8, self.ip.?, "localhost")){
                self.ip = GameConfig.DEFAULT_IP; 
            }
        }
        
        if(self.port == null){
            self.port = GameConfig.DEFAULT_PORT;
        }

        if (self.hosting == true){
            try self.add_bots();
            try self.apply_rules();
        }
    }

    fn add_bots(self: *Self) !void {
        if (self.num_players) |num_players|{
            if (num_players < 4){
                const diff: u8 = 4 - num_players; // should not be negative, check if num_players is less than 3 or 4.  
                const clamp_diff: u8 = std.math.clamp(diff, 0, 4);
                if (clamp_diff == 0) self.num_bots = 0 else self.num_bots = clamp_diff; 
            }
        }else {
            return error.NumberPlayersMissing; 
        }
    }

    fn apply_rules(self: *Self) !void {
        if (self.num_players != null){
            const total_playing: u8 = self.num_players.? + self.num_bots;
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
            return error.ConfigMissingPlayerCount; 
        }
    }

};

test "argparsing" {
    const ArgPair = struct {[]const u8, []const u8};
    const allocator = std.testing.allocator;

    var game_conf_failing = GameConfig{
        .hosting = false,
        .id = try allocator.dupe(u8, "my_username"),
    };
    defer game_conf_failing.deinit(allocator); 
     
    const argpairs: []const ArgPair = &.{
        .{"num_players", "2"},
        .{"num_bots", "2"},
        .{"num_botz", "1337"},
        .{"random_flag", "123"},
    }; 
    const expected_err = GameConfig.ArgParsingError.NeedToBeHost; 
    try std.testing.expectError(expected_err, game_conf_failing.check_parsing(argpairs[0])); 
    try std.testing.expectError(expected_err, game_conf_failing.check_parsing(argpairs[1])); 
    
    const expected_err2 = GameConfig.ArgParsingError.ArgNotValidConfigOption; 
    try std.testing.expectError(expected_err2, game_conf_failing.check_parsing(argpairs[2])); 
    try std.testing.expectError(expected_err2, game_conf_failing.check_parsing(argpairs[3])); 

}




