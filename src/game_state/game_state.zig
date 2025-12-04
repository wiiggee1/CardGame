//! Module for holding the tighlty coupled components: `State`, `GameState`, `Event` and `TaskScheduler`.
//! This module is consumed by the `Game` type in `game.zig`. 

const std = @import("std"); 
const log = std.log.scoped(.game_state);

const events = @import("events.zig");
const state = @import("states.zig");
const task_scheduler = @import("task_scheduler.zig");

const Event = events.Event;
const InternalEvent = events.InternalEvent;
const UserInput = events.UserInput;
const NetworkEvent = events.NetworkEvent;
const EventMessage = events.EventMessage;
const State = state.State;
const StateError = state.StateError;
const StateBuilder = state.StateBuilder;

// const GameConfig = @import("../game.zig").GameConfig; 
// const Game = @import("../game.zig").Game(GameConfig); 

const TaskScheduler = task_scheduler.TaskScheduler;
const TaskCallback = task_scheduler.TaskCallback;

// execute_fn: *const fn(ctx: *State, game_ctx: *anyopaque) StateError!void,

pub const Initial = struct {
    state: State,
    data: struct{} = .{},

    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *Initial = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *Initial = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }

};

pub const MainMenu = struct {
    state: State,
    menu_option: View = .WaitMenu,

    pub const View = enum {
        WaitMenu,
        PlayMenu,
        JudgeMenu,
    };

    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *MainMenu = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *MainMenu = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }

};

pub const Playing = struct {
    state: State,
    
    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *Playing = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *Playing = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }
};

pub const Waiting = struct {
    state: State,
    wait_count: u8 = 0,
    
    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *Waiting = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *Waiting = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }
};

pub const Judging = struct {
    state: State,
    cards_received: u8 = 0,
    
    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *Judging = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *Judging = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }
};

pub const Update = struct {
    state: State,
    
    pub fn execute(state_base: *State, game_obj: *anyopaque) StateError!void {
        _ = game_obj;
        const self: *Update = @alignCast(@fieldParentPtr("state", state_base)); 
        _ = self;
    }

    pub fn update(state_base: *State) StateError!void {
        const self: *Update = @alignCast(@fieldParentPtr("state", state_base));
        _ = self;
    }
};

const abc = GameState.init(.Initial, .{});

/// The `GameState` tagged union, represent the concrete active state. 
/// It executes and gain access to only the active state's functionality. 
/// Main purpose of this design principle is to have a clear separation 
/// of the responsibility during different phases of the game. 
pub const GameState = union(State.Kind) {
    /// This is the default starting state, during the setup. 
    Initial: StateBuilder(.Initial), 
    /// The `Menu` state, is the first entry prompt, and when waiting for expected 
    /// players to connect. 
    MainMenu: StateBuilder(.MainMenu),
    /// Whenever, we are in the `playing` state, we can perform game actions. 
    /// This is the state, for picking a red card during the game round. 
    Playing: StateBuilder(.Playing),

    /// During the `Waiting` state, we have either performed our actions for that round. 
    /// Or we are waiting for players to join the game. In other words, in this state, 
    /// we wait for other players to finish their moves (actions).
    Waiting: StateBuilder(.Waiting),

    /// The `Judging` state, is the same as playing state, but execute 
    /// voting actions instead. By picking the appropriate card among the 
    /// received ones. 
    Judging: StateBuilder(.Judging),

    /// Update state, is the updated and modified instance components. 
    /// This is e.g., when we finish a game round and update scores etc...
    Update: StateBuilder(.Update), 

    pub const GameStateError = error {
        FailedObtainingInternalEventDuringTransition,
    };

    pub fn get_kind(self: GameState) State.Kind {
        const tag: State.Kind = self;
        return tag; 
    }

    pub fn init(comptime kind: State.Kind, cfg: anytype) GameState{
        _ = cfg;
        return switch (kind) {
            .Initial => GameState{.Initial = StateBuilder(.Initial).init()},
            .MainMenu => GameState{.MainMenu = StateBuilder(.MainMenu).init()},
            .Playing => GameState{.Playing = StateBuilder(.Playing).init()},
            .Judging => GameState{.Judging = StateBuilder(.Judging).init()},
            .Waiting => GameState{.Waiting = StateBuilder(.Waiting).init()},
            .Update => GameState{.Update = StateBuilder(.Update).init()},
        };
    }

    fn dummy_callback(ctx: ?*anyopaque) !void {
        var self: *GameState = @ptrCast(@alignCast(ctx)); 
        std.log.debug("{s} executed callback! \n", .{self.get_state().toString()});
    }

    // pub fn fsm_transition(self: *GameState, next_state: State) !State{
    //     return try self.intoState().transition(next_state);
    //     // self.state = next_state;
    //
    // }

    // pub fn fsm_update(self: *GameState) !void {
    //     switch (self.*) {
    //         .Initial => |*initial| {
    //             initial.new().update();
    //         },
    //         inline else => |*active_state| {
    //             active_state.new().update();
    //         }
    //     }
    // }

    // pub fn execute(ctx: *anyopaque, game: *anyopaque) !void {
    //     const self: *GameState = @ptrCast(@alignCast(ctx));
    //     while(game.scheduler.poll_event()) |event| {
    //         log.debug("\n--- Dispatching Event: {s} ---\n", .{event.toString()}); 
    //         try self.handleEvent(event); 
    //         // self.state.update();
    //
    //     }
    //     // self.fsm_handle(event_input: Event)
    //     switch (self.*) {
    //         inline else => |*active_state| {
    //             active_state.execute();
    //         }
    //     }
    // }

    /// The `fsm_handle` is a "Finite-State-Machine" state machine pattern logic. That
    /// would encapsulate system behavior, by separating logic into concrete states, 
    /// that would transition based on input events. 
    pub fn handleEvent(self: *GameState, event_input: Event) GameStateError!void {

        // const current_state = self.get_state(); 
        const event_kind = event_input.tryIntoInternalEvent() orelse return GameStateError.FailedObtainingInternalEventDuringTransition; 

        // std.debug.print("Current State: {s}, Received Event: {s}\n", .{current_state.toString(), event_kind.toString()});
        
        // Switch over the current active state. Then transition the active to new state.
        // Based on different criterions! 
        switch (self.*) {
            .Initial => |*active_field| {
                try active_field.setup_callback.run_task(); // Run state specific stuff upon entering state.
                // active_field.initFrom(state_ctx: anytype)
                if (event_kind == .StartGame) {
                    self = GameState{.MainMenu = .{.callback = TaskCallback{.ctx = self, .func = dummy_callback}}}; 
                    const new_state = self.get_state().toString(); 
                    std.debug.print("\t→ New State: {s}\n", .{new_state});
                }

                if (event_kind == .ClientConnected) {
                    // update / render status of how many client / players are connected to the game. 
                }
            },
            .MainMenu => |*menu| {
                try menu.callback.run_task(); 

                if (event_kind == .StartAsJudge) {
                    self = GameState{.Judging = .{.callback = .{.ctx = self, .func = dummy_callback}}}; 
                }else if (event_kind == .StartAsPlayer){
                    self = GameState{.Playing = .{.callback = .{.ctx = self, .func = dummy_callback}}}; 
                }else {
                    
                }

                const new_state = self.get_state().toString(); 
                std.debug.print("\t→ New State: {s}\n", .{new_state});
            },
            else => {},
        }

    }

    pub fn transition(self: *GameState, event_kind: Event) !void {
        
        switch (self.*) {
            .Initial => |initial| {
                _ = initial;
            },
            .MainMenu => |*menu| {
                _ = menu.*; 
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
                            .StartGame => {},
                            .StartAsJudge => {},
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

};

test "gamestate-module" {
    _ = @import("events.zig");
    _ = @import("states.zig");
    _ = @import("task_scheduler.zig");
    // std.testing.refAllDecls(@This()); 
    std.testing.refAllDeclsRecursive(@This()); 
    
    // Fail test: 
    // try std.testing.expect(false);
    try std.testing.expect(true);

    // leak test: 
    const allocator = std.testing.allocator;
    const buf = try allocator.alloc(u8, 10);
    const val = buf[0];
    _ = val; 
}
