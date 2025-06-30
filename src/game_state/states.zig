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

const State = struct {
    ptr: *anyopaque,
    execute_fn: *const fn(ctx: *anyopaque, game: *Game) anyerror!void,
    transition_fn: *const fn(ctx: *anyopaque, comptime T: type) anyerror!State,
    update_fn: *const fn(ctx: *anyopaque) anyerror!void,

    pub fn execute(self: State, game: *Game) !void{
        self.execute_fn(self.ptr, game);
    }


    pub fn transition(self: State, comptime T: type) !T{
        if (!@hasDecl(T, "execute")) @compileError("Type: "++@typeName(T)++" missing a 'execute' fn!"); 
        if (!@hasDecl(T, "transition")) @compileError("Type "++@typeName(T)++" missing a 'transition' declaration fn!"); 
        self.transition_fn(self.ptr, T);
    }

    pub fn update(self: *State) !void{
        self.update_fn(self.ptr);
    }
   
    // pub fn allocator(self: *ArenaAllocator) Allocator {
    //     return .{
    //         .ptr = self,
    //         .vtable = &.{
    //             .alloc = alloc,
    //             .resize = resize,
    //             .remap = remap,
    //             .free = free,
    //         },
    //     };
    // }
    // const self: *ArenaAllocator = @ptrCast(@alignCast(ctx));

    pub fn Any(comptime StateContext: type, comptime funcs: anytype) type{
        if (!@hasDecl(StateContext, "execute")) @compileError("Context Type: "++@typeName(StateContext)++" missing a 'execute' fn!"); 
        if (!@hasDecl(StateContext, "transition")) @compileError("Context Type "++@typeName(StateContext)++" missing a 'transition' declaration fn!"); 
        if (!@hasDecl(StateContext, "update")) @compileError("Context Type "++@typeName(StateContext)++" missing a 'update' fn!"); 

        return struct {
            ctx: StateContext, 
            vtable: StateVTable,

            const Self = @This();

            const StateVTable: type = vtable:{
                const info = @typeInfo(@TypeOf(funcs));
                if(info.@"struct" != std.builtin.Type.Struct){
                    const num_funcs = info.@"struct".fields.len;
                    _ = num_funcs; 
                     
                    for (info.@"struct".fields) |field| {
                        if (@typeInfo(field.type) != std.builtin.Type.Fn) @compileError("Field of struct need to be of 'Fn' type!");
                        const fn_info = @typeInfo(field.type).@"fn";
                        _ = fn_info; 
                        const fn_type = @typeName(field.type);
                        const fn_name = field.name;
                        log.debug("fn_type: {s}, fn_name: {s}", .{fn_type, fn_name});
                    }
                    break :vtable @Type(.{
                       info,
                    });

                }else {
                    @compileError("Passed argument need to be a struct with functions. Got: "++@typeName(@TypeOf(funcs)));
                }
                
            }; 
        };
    }

    pub fn AnyState(
        comptime Ctx: type,
        comptime exe_func: fn (ctx: Ctx, game: *Game) anyerror!void,
        comptime update_func: fn (ctx: Ctx) anyerror!void,
        comptime transition_func: fn (ctx: Ctx, new_ctx: Ctx) anyerror!void,
    ) type {

        if (!@hasDecl(Ctx, "execute")) @compileError("Context Type: "++@typeName(Ctx)++" missing a 'execute' fn!"); 
        if (!@hasDecl(Ctx, "transition")) @compileError("Context Type "++@typeName(Ctx)++" missing a 'transition' declaration fn!"); 
        if (!@hasDecl(Ctx, "update")) @compileError("Context Type "++@typeName(Ctx)++" missing a 'update' fn!"); 

        return struct {
            ctx: Ctx, 
            const Self = @This(); 

            const ContextChild: type = child_type:{
                const ctx_info = @typeInfo(Ctx);
                if (ctx_info == .@"union"){
                    for (ctx_info.@"union".decls)|fn_decl|{ _ = fn_decl;}
                    for (ctx_info.@"union".fields)|field|{ _ = field;}
                }
                break :child_type ctx_info.@"union".tag_type.?; 
            };

            pub inline fn new(self: *const Self) State {
                if (Ctx == GameState){
                    const gamestate_ctx: *GameState = @ptrCast(@alignCast(&self.ctx));
                    return State{
                        .ptr = gamestate_ctx,
                        .execute_fn = gamestate_ctx.execute,
                        .transition_fn = gamestate_ctx.fsm_handle,
                        .update_fn = gamestate_ctx.fsm_update,
                    };
                }

                const ctx_ptr: *Ctx = @ptrCast(@alignCast(&self.ctx)); 
                // const ctx_ptr: *Ctx = @ptrCast(&self.ctx); 

                return State{
                    .ptr = ctx_ptr,
                    .execute_fn = any_execute,
                    .transition_fn = transition,
                    .update_fn = update,
                };
            }

            fn any_execute(state_ctx: *anyopaque, game: *Game) anyerror!void{
                // const self: *Ctx = @ptrCast(@alignCast(state_ctx)); 
                const ptr: *Ctx = @alignCast(@ptrCast(state_ctx)); // Would this set our Ctx field?
                return exe_func(ptr, game);
            }

            fn any_update(state_ctx: *anyopaque) anyerror!void{
                // const self: *Ctx = @ptrCast(@alignCast(state_ctx)); 
                const self: *Ctx = @alignCast(@ptrCast(state_ctx));
                return update_func(self);
            }

            fn any_transition(state_ctx: *anyopaque, other_state: *Ctx) anyerror!void{
                // const self: *Ctx = @ptrCast(@alignCast(state_ctx)); 
                
                const self: *Ctx = @alignCast(@ptrCast(state_ctx));
                return transition_func(self);
            }
        };

    }

    /// For mapping to a State, with some checks. 
    pub fn state(ctx: *anyopaque, comptime T: type) State {
    // pub fn state(self: *StateDefault, comptime T: type) StateDefault {
        if (!@hasDecl(T, "execute")) @compileError("Type: "++@typeName(T)++" missing a 'execute' fn!"); 
        if (!@hasDecl(T, "transition")) @compileError("Type "++@typeName(T)++" missing a 'transition' declaration fn!"); 
        if (!@hasDecl(T, "update")) @compileError("Type "++@typeName(T)++" missing a 'update' fn!"); 
        const self: *T = @ptrCast(@alignCast(ctx)); 
        return State{
            .ptr = self, 
            .execute_fn = self.execute,
            .transition_fn = self.transition,
            .update_fn = self.update,
        };
    }
}; 

pub const StateType = enum {
    Initial,
    MainMenu,
    Playing,
    Waiting,
    Judging,
    Update, 

    pub fn toString(self: StateType) []const u8{
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


// const DummyState = State.AnyState()
// const InitialStartState = struct{
//     pub fn execute(ctx: *anyopaque, game: *Game) !void {
//         const self: *InitialStartState = @ptrCast(@alignCast(ctx));
//         _ = game; 
//         _ = self; 
//     }
// };

// const test_state = DummyState(
//                         comptime Ctx: type, 
//                         comptime exe_func: fn(ctx:Ctx, game:*Game)anyerror!void, 
//                         comptime update_func: fn(ctx:Ctx)anyerror!void, 
//                         comptime transition_func: fn(ctx:Ctx, new_ctx:Ctx)anyerror!void
//                     )

pub const AnyGameState = State.AnyState(
                        *GameState, 
                        GameState.execute, 
                        GameState.fsm_update, 
                        GameState.fsm_handle 
                    );


/// The `GameState` tagged union, represent the concrete active state. 
/// It executes and gain access to only the active state's functionality. 
/// Main purpose of this design principle is to have a clear separation 
/// of the responsibility during different phases of the game. 
pub const GameState = union(StateType) {
    /// This is the default starting state, during the setup. 
    Initial: AnyGameState, 
    /// The `Menu` state, is the first entry prompt, and when waiting for expected 
    /// players to connect. 
    MainMenu: AnyGameState,
    /// Whenever, we are in the `playing` state, we can perform game actions. 
    /// This is the state, for picking a red card during the game round. 
    Playing: AnyGameState,

    /// During the `Waiting` state, we have either performed our actions for that round. 
    /// Or we are waiting for players to join the game. In other words, in this state, 
    /// we wait for other players to finish their moves (actions).
    Waiting: AnyGameState,

    /// The `Judging` state, is the same as playing state, but execute 
    /// voting actions instead. By picking the appropriate card among the 
    /// received ones. 
    Judging: AnyGameState,

    /// Update state, is the updated and modified instance components. 
    /// This is e.g., when we finish a game round and update scores etc...
    Update: AnyGameState, 

    pub const GameStateError = error {
        FailedObtainingInternalEventDuringTransition,
    };

    pub fn get_state(self: GameState) StateType {
        const tag: StateType = self;
        return tag; 
    }

    pub fn intoGameState(kind: StateType) GameState{
        return switch (kind) {
            .Initial => GameState{.Initial = .{ .ctx = .Initial }}
        };
    }

    pub fn intoState(self: *GameState) State{
        // const sc = AnyGameState.new();
        const state = GameState{.Initial = .{ .ctx = .Initial }};
        state.Initial.new();
        // switch (self.*) {
            // inline else => |*active_state| {
                // return AnyGameState.new(self: *const Self)
            // }
        // }
        return switch(self.*){
            .Initial => |*ctx| ctx.new(),
            // StateType.MainMenu => return AnyGameState{.ctx = .{ .Initial =  },
            StateType.Initial => return AnyGameState.new(.{ .ctx = .Initial }),
            StateType.Initial => return AnyGameState.new(.{ .ctx = .Initial }),
            StateType.Initial => return AnyGameState.new(.{ .ctx = .Initial }),
        };
    }

    fn dummy_callback(ctx: ?*anyopaque) !void {
        var self: *GameState = @ptrCast(@alignCast(ctx)); 
        std.log.debug("{s} executed callback! \n", .{self.get_state().toString()});
    }
    
    // execute_fn: *const fn(ctx: *anyopaque, game: *Game) anyerror!void,
    // transition_fn: *const fn(ctx: *anyopaque, comptime T: type) anyerror!State,


    pub fn fsm_update(self: *GameState) !void {
        switch (self.*) {
            inline else => |*active_state| {
                active_state.update();
            }
        }
    }
    pub fn execute(ctx: *anyopaque, game: *Game) !void {
        const self: *GameState = @ptrCast(@alignCast(ctx));
        _ = game; 
        switch (self.*) {
            inline else => |*active_state| {
                active_state.execute();
            }
        }

    }

    /// The `fsm_handle` is a "Finite-State-Machine" state machine pattern logic. That
    /// would encapsulate system behavior, by separating logic into concrete states, 
    /// that would transition based on input events. 
    pub fn fsm_handle(self: *GameState, event_input: Event) GameStateError!void {
        // var game: *GameType = @ptrCast(@alignCast(game_ctx)); 
        // _ = &game; 

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

};

test "state-transitions" {

    const user_inputs = [_]events.UserInput{
        .PickCard, 
        .Vote,
        .Show,
        .Exit,
    };

    const expected_states = [_]StateType{
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
    
    // std.mem.Allocator
    // std.heap.DebugAllocator
    // var initial_state = GameState{.Initial = .{ .setup_callback =  }

    _ = expected_states; 
    _ = test_events; 

    for (user_inputs) |action_event| {
        const event = try Event.parse(action_event);
        _ = event; 

    }
}




