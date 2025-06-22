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

pub const InternalEvent = enum {
    StartGame,
    StartAsJudge,
    ClientConnected,
    PlayedCard, 
    ReceivedCard,
    JudgeVoted, 
    GameOver, 
    NextRound,
    ClientExited, 

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

    pub fn toString(self: UserInput) []const u8 {
        const input_name: []const u8 = @tagName(self); 
        return input_name; 
    }

    pub fn toEvent(self: UserInput) ?InternalEvent {
        return switch(self) {
            .PickCard => InternalEvent.PlayedCard,
            .Vote => InternalEvent.JudgeVoted, 
            .Exit => InternalEvent.PlayerExited, 
            else => null
        }; 
    }

    pub fn parse(input: anytype) !UserInput {
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
                return error.ParseInputAndParseIntFailed;    
            }
        }else if (@TypeOf(input) == u8){
            const u8_input = @as(u8, input); 
            return @enumFromInt(u8_input); 
        }else {
            return error.ParsingOnlyWorksFromStringOrIntegers;
        }
    }

    pub fn parse_input(stdin: []const u8) !UserInput {
        const input_info = @typeInfo(UserInput).@"enum"; 
        inline for (input_info.fields) |input_action|{
            // if (std.mem.eql(u8, stdin, input_action.name)){
            if (std.ascii.eqlIgnoreCase(stdin, input_action.name)){
                return std.meta.stringToEnum(UserInput, input_action.name) orelse return error.FailedParsingStringToEnum; 
            }

        }
        return error.FailedParsingStdinToUserInputField;
    }


    pub fn intoInt(self: UserInput) u8 {
        return @intFromEnum(self); 
    }

}; 

pub const NetworkEvent = struct {
    id: u8, 
    payload: []const u8,

    pub const Kind = enum {
       //TODO: - Define the Network Event enum fields below:  
    };

    pub fn toEvent(self: NetworkEvent) ?InternalEvent {
        return switch (self.id) {
            10 => InternalEvent.ClientConnected,
            11 => InternalEvent.ClientExited, 
            12 => InternalEvent.StartGame,
            13 => InternalEvent.StartAsJudge,
            14 => InternalEvent.NextRound,
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
    pub fn parse(any_input: anytype) !Event {
        const self_info = @typeInfo(Event).@"union"; 
        const self_fields = self_info.fields; 

        inline for(self_fields) |field| {

            // Check if the input type is a string and from stdin → UserInput.
            // If match, then we parse the string input into appropriate Event.
            if (@TypeOf(any_input) == []const u8) {
                const user_input = try UserInput.parse(any_input); 
                const resulting_event = Event{.user_input = user_input}; 
                std.debug.print("Parsing Into UserInput Successful, returning: {}\n", .{resulting_event}); 
                return resulting_event;
            }
            
            if(@typeInfo(@TypeOf(any_input)) == .@"struct"){
                @panic("Found Struct!");
            }

            
            if (@TypeOf(any_input) == field.type){
                const field_info = @typeInfo(field.type); 
                std.debug.print("Passed Input type match the Union field of type: {}\n", .{field.type}); 
                std.debug.print("Match Found, Parsing Inner Child Fields:\n", .{}); 

                // On type match, we switch over that field's type. On enum field types 
                // we check for equality of tag names. 
                switch (field_info) {
                    .@"enum" => |enum_type| {
                        const tag_type = enum_type.tag_type; 
                        std.debug.print("\tInner Enum Field Tag Type: {}\n", .{tag_type}); 
                        const enum_fields = enum_type.fields; 

                        inline for(enum_fields) |e_field| {
                            // std.debug.print("\tInner Enum Field Name: {s}\n", .{e_field.name}); 
                            if (std.mem.eql(u8, @tagName(any_input), e_field.name)){
                                std.debug.print("\tInput Tag Name: {s} Match with Inner Enum Field Name: {s}\n", .{@tagName(any_input), e_field.name}); 
                                std.debug.print("Found: Active Field Name: {s} With Type: {}\n", .{field.name, field.type}); 

                                const field_output = @field(field.type, e_field.name);
                                std.debug.print("Field Output: {}\n", .{field_output}); 
                                
                                const event_type = @unionInit(Event, field.name, @field(field.type, e_field.name)); 
                                std.debug.print("Union to return: {}\n", .{event_type}); 
                                return event_type; 
                            }

                        }
                    },
                    .@"struct" => |struct_type| {
                        const struct_fields = struct_type.fields; 
                        // var empty_struct: field.type = undefined; 
                        inline for (struct_fields) |s_field| {
                            std.debug.print("\tInner Struct Field Name: {s}, Type: {}\n", .{s_field.name, s_field.type}); 
                            std.debug.print("\tStruct: {}\n", .{s_field}); 
                            // inline for (@typeInfo(@TypeOf(any_input)).@"struct".fields) |input_field| {
                            //     if(@hasField(field.type, input_field.name)){
                            //         std.debug.print("Found Input Field Name: {s}\n", .{input_field.name}); 
                            //     }
                            // }

                            
                            // const struct_instance = @Type(std.builtin.Type.Struct{
                            // });


                            // const field_output = @field(field.type, s_field.name);
                            // std.debug.print("Field Output: {}\n", .{field_output}); 
                            // const event_type = @unionInit(Event, field.name, @field(field.type, s_field.name)); 
                            // std.debug.print("Union to return: {}\n", .{event_type}); 
                        }
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
        return error.ParsingIntoEventTypeFailed; 
    }


    //TODO: ... Define RPC types first! 
    pub fn parse_rpc(comptime rpc_field: std.builtin.Type.Struct) !Event {
        inline for(rpc_field.fields) |field| {
            _ = field.type; 
        }
    }

};

test "event_type_parsing" {
    const string_input: []const u8 = "input as string data"; 
    // pub const UserInput = enum(u8) {
    //     PickCard = 1 , 
    //     Vote = 2,
    //     Show = 3,
    //     Exit = 4, 
    const input_userinput: UserInput = .PickCard; 
    const string_inputs: []const []const u8 = &.{
        "Not known string data",
        "PickCard", "pickcard",
        "Vote", "vote"
    }; 

    const enum_input: InternalEvent = InternalEvent.ClientConnected; 
    const struct_input: NetworkEvent = .{.id = 123, .payload = "Random payload format"}; 
    const input_values = .{string_input, input_userinput, string_inputs, enum_input, struct_input}; 

    inline for (input_values, 0..) |input, i| {
        std.debug.print("\nTEST {d}-----------------------------------------------\n", .{i}); 
        if (@TypeOf(input) == []const []const u8) {
            for (input) |str_userinput| {
                std.debug.print("\nTrying to Parse the string: '{s}'\n", .{str_userinput}); 
                _ = Event.parse(str_userinput) catch |err| std.debug.print("\nFailed Parsing with Error: {}\n", .{err}); 
            }
        }else {
            _ = Event.parse(input) catch |err| std.debug.print("\nFailed Parsing with Error: {}\n", .{err}); 
        }
        std.debug.print("-----------------------------------------------\n", .{}); 
    }
}

