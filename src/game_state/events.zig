//! The `events.zig` is part of the game module, and highly associated (coupled) with the 
//! state design pattern. Generally we can describe states and events according to: 
//! ------------------------------------
//! "A state is a condition of an object that satisfy a specific condition.
//! That often performs a certain activity or execution. States waits for some
//! event, that cause a state transition."
//! ------------------------------------
//! Further, this file contains logic for parsing input to defined and valid event kinds. 
//! An event can be either labeled as "external" or "internal" and that occur during 
//! gameplay. External events could be of type `UserInput` or `NetworkEvent`, and
//! is usally mapped into an internal event type. Internal events are the event types 
//! that trigger a state transition. 
//! ------------------------------------

const std = @import("std"); 
// const log = std.log.scoped(.gamestate_events);

pub const InternalEvent = enum {
    StartGame,
    StartAsJudge,
    StartAsPlayer,
    ClientConnected,
    PlayedCard, 
    ReceivedCard,
    JudgeVoted, 
    GameOver, 
    NextRound,
    ClientDisconnected, 

    pub fn toString(self: InternalEvent) []const u8 {
        const event_name: []const u8 = @tagName(self); 
        return event_name; 
    }
    
    pub fn fromString(str: []const u8) ?InternalEvent {
        return std.meta.stringToEnum(InternalEvent, str) orelse return null; 

    }

};

/// Anonomyous struct or tuple for associating an InternalEvent to a payload message. 
pub const EventMessage = struct {event: InternalEvent, message: []const u8};

/// The `UserInput` should represent external user triggered events. 
/// It should have functionality for mapping from UserInput to Event, 
/// and vice-versa. 
pub const UserInput = enum(u8) {
    PickCard = 1 , 
    Vote = 2,
    Show = 3,
    Exit = 4, 

    const log = std.log.scoped(.UserInput);

    pub fn toString(self: UserInput) []const u8 {
        const input_name: []const u8 = @tagName(self); 
        return input_name; 
    }

    pub fn toEvent(self: UserInput) ?InternalEvent {
        return switch(self) {
            .PickCard => InternalEvent.PlayedCard,
            .Vote => InternalEvent.JudgeVoted, 
            .Exit => InternalEvent.ClientDisconnected, 
            else => null
        }; 
    }

    pub fn parseString(input: anytype) ?UserInput {
        if (@TypeOf(input) == []const u8){
            const stdin = @as([]const u8, input); 
            const user_input_result: ?UserInput = input_blk: {
                var user_input: ?UserInput = null; 
                user_input = parse_input(stdin) catch null;
                const parsed_int = std.fmt.parseInt(u8, stdin, 10) catch null;
                if (parsed_int) |int_val| {
                    user_input = @enumFromInt(int_val);
                }
                break :input_blk user_input; 
            }; 
            if (user_input_result) |user_input| {
               return user_input;   
            }else {
                return null;    
            }
        }else {
            return null;
        }
    }

    pub fn parse_input(stdin: []const u8) !UserInput {
        const input_info = @typeInfo(UserInput).@"enum"; 
        inline for (input_info.fields) |input_action|{
            if (std.ascii.eqlIgnoreCase(stdin, input_action.name)){
                return std.meta.stringToEnum(UserInput, input_action.name) orelse return error.FailedParsingStringToEnum; 
            }
        }
        return Event.ParsingError.FailedParsingStdinToUserInputField;
    }

    pub fn parseFromInt(input: anytype) ?UserInput{
        if (@TypeOf(input) != u8) return null; 
        return std.meta.intToEnum(UserInput, input) catch null; 
    }

    pub fn intoInt(self: UserInput) u8 {
        return @intFromEnum(self); 
    }

}; 

pub const NetworkEvent = struct {
    const log = std.log.scoped(.NetworkEvent);
    const DataLength = u8; 
    const EventID = @as(u8, Kind); 
    const Bytes = []const u8; 
    const OwnedBytes = []u8; 
    const MessageFormat = struct {DataLength, EventID, Bytes};

    const OptionalPayload = ?[]const u8; 
    id: Kind, 

    /// A payload consist of [data.len, NetworkEvent.Kind, NetworkEvent.payload].
    /// Lets assume we have NetworkEvent{.id = NetworkEvent.Kind.StartGame, .payload = "start"}. 
    /// This would map into a byte sequence of [0x5, 0xC, ... , 0x73, 0x74, 0x61, 0x72, 0x74]
    /// Where the payload represent as: 
    /// 's' => 115 or 0x73
    /// 't' => 116 or 0x74
    /// 'a' => 97 or 0x61
    /// 'r' => 114 or 0x72
    /// 't' => 116 or 0x74
    /// 0x00 to 0xFF (0 to 255) fits in 1 byte (8 bits).
    payload: OptionalPayload,

    //TODO: Fix the kinds!
    pub const Kind = enum(u8) {
        // RequestMessage,
        // ResponseMessage
        ClientConnected = 10,
        ClientDisconnected = 11, 
        StartGame = 12,
        StartAsJudge = 13,
        StartAsPlayer = 14,
        NextRound = 15,

        pub fn intoEventKindFromInt(id: anytype) ?Kind {
            if (@TypeOf(id) != u8) return null; 
            return std.meta.intToEnum(NetworkEvent.Kind, id) catch null;
        }

        pub fn toString(self: Kind) []const u8{
            return @tagName(self);
        }

        pub fn toInteger(self: Kind) u8 {
            return @intFromEnum(self);
        }
    };

    pub fn parseSingleByte(input: anytype) ?NetworkEvent {
        if (@TypeOf(input) != u8) return null;
        const network_event = Kind.intoEventKindFromInt(input) orelse return null;
        return NetworkEvent{.id = network_event, .payload = null}; 
    }

    /// Same as deserializing a message struct from a sequence of bytes into 
    /// a struct. 
    pub fn parseBytes(input: anytype) ?NetworkEvent {
        if(@TypeOf(input) == Bytes or @TypeOf(input) == OwnedBytes){
            const payload_len = input[0];
            const id = input[1];
            const end: usize = @intCast(2 + payload_len); 
            const kind = Kind.intoEventKindFromInt(id) orelse return null;
            const msg_payload = input[2..end];
            // const msg_payload = input[2..][0..payload_len];

            log.debug("From input as Bytes: payload length: {d}, id: {d}, id type: {}, payload: {s}\n", .{payload_len, id, kind, msg_payload});
            return NetworkEvent{.id = kind, .payload = msg_payload};
        }
        return null; 
    }

    pub fn parse(input: anytype) Event.ParsingError!NetworkEvent{
        const input_info = @typeInfo(@TypeOf(input));
        if (input_info == .@"struct"){
            const info_fields = input_info.@"struct".fields; 

            const network_event: NetworkEvent = network_struct: {
                // var payload_buf: [128]u8 = undefined;

                inline for (info_fields) |s_field| {
                    std.debug.print("\tInner Struct Field Name: {s}, Type: {}\n", .{s_field.name, s_field.type}); 
                    if (@hasField(NetworkEvent, s_field.name)){
                        if(@TypeOf(input) == NetworkEvent){
                            break :network_struct NetworkEvent{
                                .id = @field(input, "id"),
                                .payload = @field(input, "payload"),
                            };
                        }

                        // Handle cases when the struct is not of NetworkEvent type: 
                        const kind: Kind = if (s_field.type == NetworkEvent.Kind) @field(input, s_field.name);
                        const payload: []const u8 = if (s_field.type == OptionalPayload or s_field.type == Bytes) @field(input, s_field.name) else "";
                        _ = kind; 
                        _ = payload; 
                        // std.mem.copyForwards(u8, static_buf[0..payload.len], payload);
                        // const slice: []const u8 = static_buf[0..payload.len];
                        // const slice: []const f32 = &arr1;
                    }else {
                        return Event.ParsingError.IntoNetworkEventFromStructFailed;
                    }
                }
                return Event.ParsingError.InputFailedParsingIntoNetworkEvent;
            };
            return network_event; 

        }else if(@TypeOf(input) == Bytes){
            const payload_len = input[0];
            // const payload_len = NetworkEvent.toEvent;
            const id = input[1];
            const kind = NetworkEvent.Kind.intoEventKindFromInt(id) orelse null;
            const id_str = if (kind != null) kind.toString();
            const msg_payload = input[2..payload_len];
            log.debug("From input as Bytes: payload length: {d}, id: {d}, id type: {s}, payload: {s}", .{payload_len, id, id_str, msg_payload});

        }else {
            return Event.ParsingError.ParsingIntoNetworkEventFailed;
        }

    }

    /// Caller owns the returned memory message bytes. So after creating a 
    /// new sequence of bytes, the caller needs to free after usage!
    pub fn toOwnedByteMessage(self: NetworkEvent, allocator: std.mem.Allocator) !OwnedBytes{
        
        var buf: [128]u8 = undefined; 
        const payload: []const u8 = self.payload orelse ""; 
        const payload_len = payload.len; 
        const num_bytes: u8 = @intCast(payload_len); // number of bytes of the msg part, cast from usize len to u8 (payload size).

        const offset = @sizeOf(@TypeOf(self.id.toInteger())) +  @sizeOf(@TypeOf(num_bytes));
        const offset_index: usize = @intCast(offset); // 2
        const total_size: u8 = @as(u8, offset) + num_bytes;
        
        log.info("Size of usize: {d}, len payload: {d}\n", .{@sizeOf(usize), payload_len}); 
        log.info("offset size: {d}, offset_index: {d}, total byte size: {d}\n", .{offset, offset_index, total_size}); 

        buf[0] = num_bytes;
        buf[1] = self.id.toInteger();

        log.debug("buf[0] = {d} => Payload Length\n", .{buf[0]});
        log.debug("buf[1] = {d} => NetworkEvent.Kind => {}\n", .{buf[1], self.id});

        for (payload, 0..) |char, i|{
            const index: usize = offset_index + i;
            log.debug("buf[{d}] = {c}\n", .{index, char}); 
            buf[index] = char;
        }
        const msg_slice: []const u8 = buf[0..offset_index+payload_len]; // Local slice owned by the buf variable.
        const msg_copy = try allocator.dupe(u8, msg_slice); // Creates a new owned copy of the msg_slice.
        log.info("Decoded Message: [ {d}, {d}, '{s}' ]\n", .{msg_slice[0], msg_slice[1], msg_slice[2..offset_index+payload_len]});

        return msg_copy; 
    }

    pub fn toEvent(self: NetworkEvent) ?InternalEvent {
        const id: u8 = @intFromEnum(self.id);
        return switch (id) {
            10 => InternalEvent.ClientConnected,
            11 => InternalEvent.ClientDisconnected, 
            12 => InternalEvent.StartGame,
            13 => InternalEvent.StartAsJudge,
            14 => InternalEvent.StartAsPlayer,
            15 => InternalEvent.NextRound,
            else => null, 
        };
    }
};

pub const Event = union(enum) {
    event: InternalEvent, 
    /// Actions that the user / player makes during the game. 
    /// Its the same as available game actions, that can be triggered. 
    user_input: UserInput, 
    /// A network event type, is e.g., a RPC message payload. 
    network: NetworkEvent, 

    const log = std.log.scoped(.Event);

    const ParsingError = error {
        InputStringNotValid,
        ParsingIntoEventTypeFailed,
        ParsingIntoNetworkEventFailed,
        IntoNetworkEventFromIntFailed,
        IntoNetworkEventFromStructFailed,
        ParseInputAndParseIntFailed,
        ParsingUserInputStringFailed,
        FailedParsingStdinToUserInputField,
        ParsingSingleByteDigitFailed,
        InputFailedParsingIntoNetworkEvent,
    } || std.fmt.ParseIntError || std.process.GetEnvMapError || std.meta.IntToEnumError;

    pub fn tryIntoInternalEvent(self: Event) ?InternalEvent {
        return switch (self) {
            .event => |event_value| return event_value, 
            .user_input => |user_event| return user_event.toEvent(),
            .network => |net_event| return net_event.toEvent(), 
        };
    }

    /// This parse logic for Union's was heavily inspired by code from:
    /// → `https://github.com/ghostty-org/ghostty/blob/main/src/input/Binding.zig`. 
    /// -------------------------------------------------
    /// It would basically take in a Union Type, and return the inner field type of 
    /// that union. In our case, we would return the appropriate InputType. 
    /// Which can be either of `InternalEvent` and external `UserInput` or `NetworkEvent. 
    /// By iterating std.builtin.Type.UnionField we can check for @typeInfo
    /// over each field. This way we can check against the provided input 
    /// argument type of `anytype` and parse into matching field types. 
    /// Lastly calling @unionInit → @unionInit(comptime Union: type, active_field_name: []const u8, init_expr)
    pub fn parse(any_input: anytype) ParsingError!Event {
        const self_info = @typeInfo(Event).@"union"; 
        const self_fields = self_info.fields; 

        inline for(self_fields) |field| {

            // Check if the input type is a string and from stdin → UserInput.
            // If match, then we parse the string input into appropriate Event.
            if (@TypeOf(any_input) == []const u8) {
                if (UserInput.parseString(any_input)) |user_input| return Event{.user_input = user_input}; 
                if (NetworkEvent.parseBytes(any_input)) |network_input| return Event{.network = network_input}; 
                return ParsingError.InputStringNotValid;
            }

            // Try all different Event types and their u8 int parsing, if all fails we return an error!
            if (@TypeOf(any_input) == u8){
                if(UserInput.parseFromInt(any_input)) |user_input| return Event{.user_input = user_input};
                if (NetworkEvent.parseSingleByte(any_input)) |network_input| return Event{.network = network_input}; 
                return ParsingError.ParsingSingleByteDigitFailed;
            }
            
            if (@TypeOf(any_input) == field.type){
                const field_info = @typeInfo(field.type); 
                // std.debug.print("Passed Input type match the Union field of type: {}\n", .{field.type}); 
                // std.debug.print("Match Found, Parsing Inner Child Fields:\n", .{}); 

                // On type match, we switch over that field's type. On enum field types 
                // we check for equality of tag names. 
                switch (field_info) {
                    .@"enum" => |enum_type| {
                        const enum_fields = enum_type.fields; 
                        inline for(enum_fields) |e_field| {
                            if (std.mem.eql(u8, @tagName(any_input), e_field.name)){
                                const event_type = @unionInit(Event, field.name, @field(field.type, e_field.name)); 
                                std.debug.print("Parsed Union return type: {}\n", .{event_type}); 
                                return event_type; 
                            }
                        }
                    },
                    .@"struct" => |struct_type| {
                        const struct_fields = struct_type.fields; 
                        _ = struct_fields; 
                        const network_event = try NetworkEvent.parse(any_input);
                        log.debug("Union to return: {}\n", .{network_event}); 
                        if (network_event.payload) |payload| {
                            log.debug("Union to return payload: {s}\n", .{payload}); 

                        }

                        return Event{.network = network_event}; 
                    },
                    .pointer => |ptr| {
                        if (ptr.size == .slice and ptr.is_const == true and ptr.child == u8){
                            std.debug.print("Type → .pointer and input type = {}\n", .{@TypeOf(any_input)}); 
                        }
                    },
                    else => {},
                }

            }

        }
        return ParsingError.ParsingIntoEventTypeFailed; 
    }


    //TODO: ... Define RPC types first! 
    pub fn parse_rpc(comptime rpc_field: std.builtin.Type.Struct) ParsingError!Event {
        inline for(rpc_field.fields) |field| {
            _ = field.type; 
        }

        return ParsingError.RPCInputNotValid;
    }

};

test "event_type_parsing" {

    // const input_userinput: UserInput = .PickCard; 
    const string_inputs: []const []const u8 = &.{
        "Not known string data",
        "PickCard", "pickcard",
        "Vote", "vote"
    }; 

    // const enum_input: InternalEvent = InternalEvent.ClientConnected; 
    const digit_pickcard: u8 = 1;
    const digit_vote: u8 = 2;
    const digit_connected: u8 = 10;
    const digit_startgame: u8 = 12;
    
    var message_buf: [128]u8 = undefined;
    const slice = &message_buf;
    _ = slice; 

    // std.heap.FixedBufferAllocator;
    const struct_networkevent: NetworkEvent = .{.id = .StartGame, .payload = "start"}; 

    // This would map into a byte sequence of [0x5, 0xC, ... , 0x73, 0x74, 0x61, 0x72, 0x74]
    // Or as: [5, NetworkEvent.Kind.StartGame, "start"].
    const byte_sequence: []const u8 = &.{0x5, 0xC, 0x73, 0x74, 0x61, 0x72, 0x74};
    const byte_sequence_connected: []const u8 = &.{0x9, 0xA, 'c', 'o', 'n', 'n', 'e', 'c', 't', 'e', 'd'};

    const input_values = .{string_inputs, 
        digit_pickcard, digit_vote, digit_connected, digit_startgame, 
        struct_networkevent, 
        byte_sequence, byte_sequence_connected}; 

    const expected_internal_events = .{
        Event.ParsingError.InputStringNotValid, 
        Event{.user_input = UserInput.PickCard},
        Event{.user_input = UserInput.PickCard},
        Event{.user_input = UserInput.Vote},
        Event{.user_input = UserInput.Vote},
        Event{.network = NetworkEvent{.id = .StartGame, .payload = "start"}},
        Event{.network = NetworkEvent{.id = .StartGame, .payload = "start"}},
        Event{.network = NetworkEvent{.id = .StartGame, .payload = "connected"}},
    };
    _ = expected_internal_events; 

    inline for (input_values) |input| {
        if (@TypeOf(input) == []const []const u8) {
            for (input) |str_userinput| {
                std.log.scoped(.event_type_parsing).info("\nTrying to Parse the string: '{s}'\n", .{str_userinput}); 
                _ = Event.parse(str_userinput) catch |err| std.log.scoped(.event_type_parsing).err("\nFailed with: {}\n", .{err}); 
            }
        }else {
            std.log.scoped(.event_type_parsing).info("\nTrying to Parse the type: '{}', with Value: {any}\n", .{@TypeOf(input), input}); 
            const out = try Event.parse(input); 
            std.log.scoped(.event_type_parsing).warn("Event Returned: {}\n", .{out}); 

        }
    }
}

test "byte_parsing" {
    const allocator = std.testing.allocator;
    const struct_networkevent: NetworkEvent = .{.id = .StartGame, .payload = "start"}; 

    // This would map into a byte sequence of [0x5, 0xC, ... , 0x73, 0x74, 0x61, 0x72, 0x74]
    // Or as: [5, NetworkEvent.Kind.StartGame, "start"].
    const byte_sequence: []const u8 = &.{0x5, 0xC, 0x73, 0x74, 0x61, 0x72, 0x74};
    const byte_sequence_connected: []const u8 = &.{0x9, 0xA, 'c', 'o', 'n', 'n', 'e', 'c', 't', 'e', 'd'};

    const bytes = try struct_networkevent.toOwnedByteMessage(allocator); //FIX: - Doesnt return any custom errors!
    defer allocator.free(bytes); 
    

    const payload_len: usize = struct_networkevent.payload.?.len; 
    const expected_len: u8 = @intCast("start".len);
    const offset: usize = 2; 
    const end: usize = offset + payload_len; 
    _ = end; 

    try std.testing.expectEqual(bytes[0], expected_len);
    try std.testing.expectEqual(bytes[1], NetworkEvent.Kind.StartGame.toInteger());
    
    // log.info("Decoded Message: [ {d}, {d}, '{s}' ]\n", .{msg_slice[0], msg_slice[1], msg_slice[2..offset_index+payload_len]});

    const decoded_sequence: []const u8 = &.{bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6]};
    const payload_part: []const u8 = &.{bytes[2], bytes[3], bytes[4], bytes[5], bytes[6]};
    try std.testing.expect(std.mem.eql(u8, decoded_sequence, byte_sequence));
    try std.testing.expect(std.mem.eql(u8, payload_part, "start"));

    const network_connected = NetworkEvent.parseBytes(byte_sequence_connected);
    try std.testing.expect(std.mem.eql(u8, network_connected.?.payload.?, "connected"));

    const networkevent = NetworkEvent.parseBytes(byte_sequence);
    if (networkevent) |actual| {
        std.log.scoped(.byte_parsing).warn("From Input Bytes {x}\n", .{byte_sequence});
        std.log.scoped(.byte_parsing).warn("Actual: NetworkEvent: {}\n", .{actual});
        std.log.scoped(.byte_parsing).warn("Actual: NetworkEvent.payload: {s}\n", .{actual.payload.?});
        // try std.testing.expectEqual(struct_networkevent, actual);
    }

    try std.testing.expect(true); 

}

