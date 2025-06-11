const std = @import("std");
const server = std.net.Server;
const address = std.net.Address;
const ArgIterator = std.process.ArgIterator;

/// This will provide config options related to the game.
/// It also handles parsing of the arguments passed when executing the game file. 
pub const GameConfig = struct {
    const Self = @This(); // returns the type of the inner most struct.
    const DEFAULT_IP: []const u8 = "127.0.0.1"; 
    const DEFAULT_PORT: u16 = 0; 

    hosting: bool = false,
    /// num_player, option is only valid if you are the host of the game. 
    /// Meaning `hosting` = true. 
    num_players: ?u8 = null,
    /// num_bots, option is only valid if you are the host of the game. 
    /// Meaning `hosting` = true. Defining the number of bots, is usally 
    /// done automatically, by checking if the `num_player` is within 
    /// 4-10 players. Else we add the difference as bots. 
    num_bots: ?u8 = null,
    id: []u8,
    ip: ?[]const u8 = null,
    port: ?u16 = null, // 2048

    const ArgParsingError = error {
        NeedToBeHost,
        ArgFailed,
        ArgNotValidConfigOption,
        ArgFlagWasNull,
        ArgFlagIsNotStringType,
        FlagWithEmptyValue,
    } || std.fmt.ParseIntError || std.process.GetEnvMapError || std.io.AnyWriter.Error;
    
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

        std.debug.print("field_exist block = {}\n", .{field_exist}); 
        if (!field_exist) return ArgParsingError.ArgNotValidConfigOption; 

        if (self.hosting == false and (std.mem.eql(u8, any[0], "num_player") or std.mem.eql(u8, any[0], "num_bots"))){
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
                        allocator.free(self.id);
                        self.id = try allocator.dupe(u8, flag_value);
                    }
                }else {
                    @field(self, field_name) = flag_value; 
                }
            }
        }
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        defer allocator.free(self.id);
    }

    fn help_option() !void {
        const stdout = std.io.getStdOut().writer(); 
        try stdout.print("Usage: game setup [options]\n", .{});
        try stdout.print("  --help\n", .{});
        try stdout.print("  --hosting <y/n>\n", .{});
        try stdout.print("  --num_players <int>      Valid number is 1-8+\n", .{});
        try stdout.print("  --id <str>\n", .{});
        try stdout.print("  --ip\n", .{});
        try stdout.print("  --port\n", .{});
    }

    pub fn parse_args(allocator: std.mem.Allocator) ArgParsingError!Self {
        const stdout = std.io.getStdOut().writer(); 
        var args = try std.process.ArgIterator.initWithAllocator(allocator);
        defer args.deinit();

        _ = args.skip(); // First argument is the executable path to file. 

        // std.os.linux.termio{}

        // We set the user id initially by searching the env `$USER` on the OS.
        const env_user = try std.process.getEnvVarOwned(allocator, "USER"); //WARN: - Caller owns the returned slice, and need to free it! 
        std.debug.print("Found user id: {s} with type: {}\n", .{env_user, @TypeOf(env_user)}); 

        var game_config = GameConfig{
            .id = env_user,
            // .ip = "127.0.0.1", 
        }; 
         
        while(args.next()) |arg| {
            if (arg.len < 2){
                try stdout.print("No options (flags) passed, using default values!\n", .{});
                // Return with default values
            }
            if (arg.len < 3){}

            if (std.mem.eql(u8, arg, "--help") or 
                std.mem.eql(u8, arg, "-h") or 
                std.mem.eql(u8, arg, "help")) {
                try help_option(); 
            }
            
            try stdout.print("arg value: {s}\n", .{arg}); 
            const arg_pair: struct{[]const u8, []const u8} = val_blk: {
                if(std.mem.startsWith(u8, arg, "--")){
                    if (std.mem.containsAtLeastScalar(u8, arg, 1, '=')){
                        var split = std.mem.splitAny(u8, arg, "=");
                        const lhs_flag = split.first(); // Need to call `first()` to advance! 
                        const rhs_value = split.peek();
                        const flag_name = std.mem.trim(u8, lhs_flag, "--");
                        
                        if (rhs_value) |flag_value| break :val_blk .{flag_name, flag_value};
                    }else {
                        if(args.next()) |flag_val| {
                            try stdout.print("Found '{s}' flag with associated value: {s}\n", .{arg, flag_val});
                            const flag_name = std.mem.trim(u8, arg, "--");
                            break :val_blk .{flag_name, flag_val};
                        }
                    }
                    return error.FailedRetrevingFlagValue;
                }
                continue;
            };

            try stdout.print("Resulting flag '{s}' and flag value: '{s}'\n", .{arg_pair.@"0", arg_pair.@"1"});
            try game_config.set_field(arg_pair, allocator);

            // Run different setup depending on if --hosting y or --hosting n. 
            if (std.ascii.eqlIgnoreCase(arg, "--hosting")){}
        }

        game_config.update_config(); 

        return game_config; 
    }

    //TODO: - Move this, so its not part of the `cli.zig` logic!!!!!!
    pub fn create_socket() void {
        const stdout = std.io.getStdOut().writer(); 

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

    }

    /// This method, should handle missing config fields, by setting them to their default values. 
    /// Or for the case of `num_bots` this is calculated taking the difference. 
    fn update_config(self: *Self) void {
        //Set default values below: 
        if(self.ip == null) {
            self.ip = GameConfig.DEFAULT_IP; 
        }
        
        if(self.port == null){
            self.port = GameConfig.DEFAULT_PORT;
        }
        if (self.num_players) |num_players|{
            if (num_players < 4){
                const diff: u8 = 4 - num_players; 
                if (diff == 0) self.num_bots = 0 else self.num_bots = diff; 
            }
        }
    }
};




