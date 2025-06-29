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
const TaskCallback = @import("task_scheduler.zig").TaskCallback;
const TaskScheduler = @import("task_scheduler.zig").TaskScheduler;
const events = @import("events.zig"); 
const Event = events.Event; 
const GameConfig = @import("../game.zig").GameConfig; 
const Game = @import("../game.zig").Game(GameConfig); 
const log = std.log.scoped(.gamestate_states);

const StateContext = TaskCallback; 

pub const State = enum {
    Initial,
    MainMenu,
    Playing,
    Waiting,
    Judging,
    Update, 

    pub fn toString(self: State) []const u8{
        const name: []const u8 = @tagName(self);
        return name;  
    }
};


pub fn debug_info(any: anytype, allocator: std.mem.Allocator) !void {
    const self_info = try std.debug.SelfInfo.init(allocator);
    const mem_accessor = std.debug.MemoryAccessor.init; 
    std.debug.print("Size of type: {}, Alignment: {}\n", .{@sizeOf(@TypeOf(any)), @alignOf(@TypeOf(any))});  
    _ = self_info; 
    _ = mem_accessor; 
}


const InitialStartState = struct{setup_callback: TaskCallback};
const MainMenuState = struct{callback: TaskCallback};
const PlayingState = struct{callback: TaskCallback};
const WaitingOthersState = struct{callback: TaskCallback};
const JudgingState = struct{callback: TaskCallback};
const UpdateState = struct{callback: TaskCallback}; 

/// The `GameState` tagged union, represent the concrete active state. 
/// It executes and gain access to only the active state's functionality. 
/// Main purpose of this design principle is to have a clear separation 
/// of the responsibility during different phases of the game. 
pub const GameState = union(State) {
    /// This is the default starting state, during the setup. 
    Initial: InitialStartState, 
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

    pub const GameStateError = error {
        FailedObtainingInternalEventDuringTransition,
    };

    pub fn get_state(self: GameState) State {
        const tag: State = self;
        return tag; 
    }

    fn dummy_callback(ctx: ?*anyopaque) !void {
        var self: *GameState = @ptrCast(@alignCast(ctx)); 
        std.log.debug("{s} executed callback! \n", .{self.get_state().toString()});
    }

    pub fn fsm_update(state_ctx: *anyopaque, game: *Game) void {
        _ = state_ctx;
        _ = game; 
    }

    /// The `fsm_handle` is a "Finite-State-Machine" state machine pattern logic. That
    /// would encapsulate system behavior, by separating logic into concrete states, 
    /// that would transition based on input events. 
    pub fn fsm_handle(self: *GameState, comptime GameType: type, game_ctx: *anyopaque, event_input: Event) GameStateError!void {
        var game: *GameType = @ptrCast(@alignCast(game_ctx)); 
        _ = &game; 

        //NOTE: - Using *anyopaque + function pointers, allows for state transition and logic without coupling (polymorphism).

        const current_state = self.get_state(); 
        const event_kind = event_input.tryIntoInternalEvent() orelse return GameStateError.FailedObtainingInternalEventDuringTransition; 
        std.debug.print("Current State: {s}, Received Event: {s}\n", .{current_state.toString(), event_kind.toString()});

        //TODO: - The GameState should use generic functions, for passing pointers
        // such as the game_ctx for being able to access parent pointers fields. 
        // Which impact the resulting state-to-state transitions. 
        
        // Switch over the current active state. Then transition the active to new state.
        // Based on different criterions! 
        switch (self.*) {
            .Initial => |*active_field| {
                try active_field.setup_callback.run_task(); // Run state specific stuff upon entering state.
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


    pub fn test_transition(self: *GameState, event_input: Event) !void {
        const current_state = self.get_state(); 
        const event_kind = event_input.tryIntoInternalEvent() orelse return error.FailedObtainingInternalEventDuringTransition;
        std.debug.print("Current State: {s}, Received Event: {s}\n", .{current_state.toString(), event_kind.toString()});
        
        switch (self.*) {
            .Initial => |*active_field| {
                try active_field.setup_callback.run_task(); // Run state specific stuff upon entering state.
                if (event_kind == .StartGame) {
                    // self = GameState{.MainMenu = .{.callback = .{.ctx = null, .func = void}}}; 
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
                    // self = GameState{.Judging = .{.callback = .{.ctx = null, .func = void}}}; 
                }else if (event_kind == .StartAsPlayer){
                    // self = GameState{.Playing = .{.callback = .{.ctx = null, .func = void}}}; 
                }else {
                    
                }

                const new_state = self.get_state().toString(); 
                std.debug.print("\t→ New State: {s}\n", .{new_state});

            },
            .Playing => |*playing| {
                try playing.callback.run_task(); 
            },
            .Waiting => |*wait| {
                try wait.callback.run_task();
            },
            .Judging => |*judge| {
                try judge.callback.run_task();
            },
            .Update => |*update| {
                try update.callback.run_task();
            }

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

test "state-transitions" {

    const user_inputs = [_]events.UserInput{
        .PickCard, 
        .Vote,
        .Show,
        .Exit,
    };

    const expected_states = [_]State{
        .Initial,
        .MainMenu,
        .Playing,
        .Judging,
    };

    const test_events = [_]events.InternalEvent{
        .StartGame, 
        .PlayedCard, 
        .NextRound,
        .JudgeVoted, 
    };

    _ = expected_states; 
    _ = test_events; 

    for (user_inputs) |action_event| {
        const event = try Event.parse(action_event);
        _ = event; 

    }
}




