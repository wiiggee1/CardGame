//! The `states.zig` is part of the game module, and highly associated (coupled) with the 
//! state design pattern. Generally we can describe states and events according to: 
//! ------------------------------------
//! "A state is a condition of an object that satisfy a specific condition.
//! That often performs a certain activity or execution. States waits for some
//! event, that cause a state transition."
//! ------------------------------------
//! Further, this file contains events that can occur during the game. 
//! It consist of logic for state transition, but also how events are associated 
//! to callbacks (queue of function pointers). 
//! ------------------------------------

const std = @import("std"); 
const Game = @import("game.zig").Game; 
const task = @import("task_scheduler.zig");
const TaskCallback = task.TaskCallback;
const Event = @import("events.zig").Event; 


pub const State = enum {
    MainMenu,
    Playing,
    Waiting,
    Judging,
    Update, 
};


pub fn debug_info(any: anytype, allocator: std.mem.Allocator) !void {
    const self_info = try std.debug.SelfInfo.init(allocator);
    const mem_accessor = std.debug.MemoryAccessor.init; 
    std.debug.print("Size of type: {}, Alignment: {}\n", .{@sizeOf(@TypeOf(any)), @alignOf(@TypeOf(any))});  
    _ = self_info; 
    _ = mem_accessor; 
}


const MainMenuState = struct{callback: TaskCallback};
const PlayingState = struct{callback: TaskCallback};
const WaitingOthersState = struct{callback: TaskCallback};
const JudgingState = struct{callback: TaskCallback};
const UpdateState = struct{callback: TaskCallback}; 

pub const GameState = union(State) {
    /// The `Menu` state, is the first entry prompt, and when waiting for expected 
    /// players to connect. 
    MainMenu: MainMenuState,
    /// Whenever, we are in the `playing` state, we can perform game actions. 
    /// This is the state, for picking a red card during the game round. 
    Playing: PlayingState,

    /// During the `Waiting` state, we have either performed our actions for that round. 
    /// Or we are waiting for players to join the game. In other words, in this state, 
    /// we wait for other players to finish their moves (actions).
    Waiting: WaitingOthersState,

    /// The `Judging` state, is the same as playing state, but execute 
    /// voting actions instead. By picking the appropriate card among the 
    /// received ones. 
    Judging: JudgingState,

    /// Update state, is the updated and modified instance components. 
    /// This is e.g., when we finish a game round and update scores etc...
    Update: UpdateState, 


    pub fn get_state(self: GameState) State {
        const tag: State = self;
        // std.meta.TagPayload(self, comptime tag: Tag(U))
        // std.meta.Tag(comptime T: type)
        return tag; 
    }
    
    pub fn transition(self: *GameState, event_kind: Event) !void {
        
        switch (self.*) {
            .MainMenu => |*menu| {
                // Active State: MainMenu
                // Received Event: StartGame 
                //      New Active State: → Playing.
                // Received Event: StartAsJudge
                //      New Active State: → Judging.
                // Received Event: NextRound
                //      New Active State: → Judging or Playing.
                switch (event_kind) {
                    .event => |internal_event| {
                        switch (internal_event) {
                            .StartGame => {
                                menu.* = GameState{
                                    .Playing = PlayingState{
                                        .callback = TaskCallback{.ctx = null, .func = void}
                                    }
                                };
                            },
                            .StartAsJudge => menu.* = GameState{.Judging = .{.func = void}},
                            else => return error.WrongEventTypeCannotTransition, 
                        }
                    },
                    .user_input => |user_event| {
                        const event_internal = user_event.toEvent(); 
                        if (event_internal) |event| {
                            _ = event; 
                        }
                    },
                    .network => |net_event| {
                        const network_internal = net_event.toEvent() orelse return error.NetworkEventFailedTransition;
                        _ = network_internal; 
                    }
                }
            },
            .Playing => {
                // Active State: Playing
                // Received Event: PlayedCard 
                //      New Active State: → Waiting.
            },
            .Waiting => {
                // Active State: Waiting
                // Received Event: JudgeVoted
                //      New Active State: → Update.
            },
            .Judging => {
                // Active State: Judging:
                // Received Event: ReceivedCard 
                //      New Active State: → Judging.
                // Received Event: AllCardReceived
                //      New Active State: → Update.
            },
            .Update => {
                // Active State: Update:
                // Received Event: NextRound 
                //      New Active State: → MainMenu.
                // Received Event: JudgeVoted
                //      New Active State: → MainMenu.
            }
        }

    }

    pub fn execute(self: GameState) !void {
        // switch (self) {
        //     .MainMenu => |menu| {},
        //     .Playing => |play| {},
        //     .Waiting => |waiting| {},
        //     .Judging => |judge| {},
        //     .Update => |update| {},
        // }
        _ = self; 
    }

};




