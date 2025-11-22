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

pub const StateError = error{
    CreatingStateFailed,
    ExecutingStateFailed,
    TransitionToStateFailed,
    UpdatingStateFailed,
};

// Writer{vtable: *const VTable, buffer: []u8, end: usize = 0,};

/// State represent the interface for creating new concrete states.
/// That contains a context `ptr` as a pointer of unknown type with
/// non zero size (anyopaque). Concrete State types, needs a State field. 
/// Creating a new State type is done via the following pseudo example:
/// ```
/// return .{
///     .ptr = self,
///     .vtable = &.{
///         state_fn1,
///         state_fn2,
///         ...
///         state_fn_x
///     },
/// };
/// ```
/// Where the `vtable` is just the container that holds the mandatory 
/// function pointer (callbacks). Further, to cast we can use: 
/// • @ptrCast(@alignCast(ctx)) => Cast *anyopaque into inferred pointer type. 
/// • @alignCast(@ptrCast(ctx)) => 
/// Also: "any sequence of nested pointer cast builtins requires only one 
/// result type, rather than one at every intermediate computation". 
pub const State = struct {
    ptr: *anyopaque,
    kind: Kind, 
    vtable: *const StateVTable,

    // execute_fn: *const fn(ctx: *anyopaque, game: *Game) StateError!void,
    // transition_fn: *const fn(ctx: *anyopaque, next_ctx: *anyopaque) StateError!State,
    // update_fn: *const fn(ctx: *anyopaque) StateError!void,

    pub const StateVTable = struct {
        execute_fn: *const fn(ctx: *State, game: *Game) StateError!void,
        transition_fn: *const fn(ctx: *State, next_ctx: *State) StateError!State,
        update_fn: *const fn(ctx: *State) StateError!void,
    };


    pub const Kind = enum {
        Initial,
        MainMenu,
        Playing,
        Waiting,
        Judging,
        Update, 

        pub fn toString(self: Kind) []const u8{
            const name: []const u8 = @tagName(self);
            return name;  
        }
    };

    pub const Initial = struct {
        state: State,
    };
    pub const MainMenu = struct {
        state: State,
    };
    pub const Playing = struct {
        state: State,
    };
    pub const Waiting = struct {
        state: State,
    };
    pub const Judging = struct {
        state: State,
    };
    pub const Update = struct {
        state: State,
    };


    //For mapping to a State, with some stricter checks.
    // pub fn from(ctx: *anyopaque, comptime T: type, state_kind: Kind) State {
    //     if (!@hasDecl(T, "execute")) @compileError("Type: "++@typeName(T)++" missing a 'execute' fn!"); 
    //     if (!@hasDecl(T, "transition")) @compileError("Type "++@typeName(T)++" missing a 'transition' declaration fn!"); 
    //     if (!@hasDecl(T, "update")) @compileError("Type "++@typeName(T)++" missing a 'update' fn!"); 
    //     const self: *T = @ptrCast(@alignCast(ctx)); 
    //     return State{
    //         .ptr = self, 
    //         .kind = state_kind,
    //         .vtable = &.{
    //             .execute_fn = T.execute,
    //             .transition_fn = T.transition,
    //             .update_fn = T.update,
    //         },
    //     };
    // }

    // std.Io.Writer.Discarding
    // pub const Discarding = struct {
    // count: u64,
    // writer: Writer,
    //
    // pub fn init(buffer: []u8) Discarding {
    //     return .{
    //         .count = 0,
    //         .writer = .{
    //             .vtable = &.{
    //                 .drain = Discarding.drain,
    //                 .sendFile = Discarding.sendFile,
    //             },
    //             .buffer = buffer,
    //         },
    //     };
    // }

    // std.Io.Writer.sendFile(w: *Writer, file_reader: *Reader, limit: Limit)
    // return w.vtable.sendFile(w, file_reader, limit);


    pub fn execute(self: *State, game: *Game) !void{
        // self.execute_fn(self.ptr, game);
        self.vtable.execute_fn(self, game);
    }

    pub fn transition(self: State, next: *State) !State{
        // self.transition_fn(self.ptr, next.ptr);
        self.vtable.transition_fn(self, next);
    }

    pub fn update(self: *State) !void{
        // self.update_fn(self.ptr);
        self.vtable.update_fn(self);
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

            const StateVTable: type = vtable:{
                const info = @typeInfo(Ctx);
                for (info.@"struct".fields) |field| {
                    if (@typeInfo(field.type) != std.builtin.Type.Fn) @compileError("Field of struct need to be of 'Fn' type!");
                    const fn_info = @typeInfo(field.type).@"fn";
                    _ = fn_info; 
                    const fn_type = @typeName(field.type);
                    const fn_name = field.name;
                    log.debug("fn_type: {s}, fn_name: {s}", .{fn_type, fn_name});
                }
                break :vtable @Type(.{info});
            }; 

            const ContextChild: type = child_type:{
                const ctx_info = @typeInfo(Ctx);
                if (ctx_info == .@"union"){
                    for (ctx_info.@"union".decls)|fn_decl|{ _ = fn_decl;}
                    for (ctx_info.@"union".fields)|field|{ _ = field;}
                }
                break :child_type ctx_info.@"union".tag_type.?; 
            };

            /// "Any sequence of nested pointer cast builtins requires only one result type, 
            /// rather than one at every intermediate computation". Below the `.ptr` field 
            /// in the return statement have the inferred type `*anyopaque` while the 
            /// `&self.ctx` have the inferred type of *Ctx. This means that the @ptrCast 
            /// would type-erase and cast from the type *Ctx (type of &self.ctx) 
            /// into the new pointer type of *anyopaque as the inferred type of the `ptr` field. 
            /// Note that the following will re-establish the type via: *anyopaque → *Ctx.
            /// Through: `const self: *Ctx = @ptrCast(@alignCast(state_ctx));`. 
            pub inline fn new(self: *const Self, kind: Kind) State {
                //NOTE: - Difference between @ptrCast(@alignCast(ctx)) vs @alignCast(@ptrCast(ctx))? 

                log.debug("Size Of 'self.ctx' argument (*anyopaque): {d}\n", .{@sizeOf(@TypeOf(self.ctx))});
                log.debug("Size Of '&self.ctx' argument (*anyopaque): {d}\n", .{@sizeOf(@TypeOf(&self.ctx))});
                const context_ptr = ptr_type:{
                    const info_ctx = @typeInfo(Ctx);
                    if(info_ctx == .pointer){
                        log.debug("Ctx Pointer info: {}\n", .{info_ctx.pointer});
                        break :ptr_type @as(Ctx, @ptrCast(self.ctx)); 
                    }else {
                        log.debug("Ctx type was non pointer found Type: {}\n", .{info_ctx});
                        break :ptr_type @as(*Ctx, @ptrCast(&self.ctx)); 
                    }
                };

                const ctx_ptr: *Ctx = @ptrCast(&self.ctx); 
                const type_erased_ptr = ctx_ptr.*;
                log.debug("Pointer Type of context_ptr: => {}\n", .{@TypeOf(context_ptr)}); 
                log.debug("Alignment of context_ptr: => {}\n", .{@alignOf(context_ptr)}); 
                log.debug("Size of context_ptr: => {}\n", .{@sizeOf(@TypeOf(context_ptr))}); 

                log.debug("Type of dereferenced *Ctx casted variable: {}\n", .{@TypeOf(type_erased_ptr)});

                return State{
                    // .ptr = ctx_ptr, // type-erase: *Ctx → *anyopaque
                    .ptr = @ptrCast(&self.ctx), // type-erase, inferred type is of the `.ptr` field: *Ctx → *anyopaque
                    .kind = kind,
                    .execute_fn = any_execute,
                    .transition_fn = any_transition,
                    .update_fn = any_update,
                };
            }

            fn any_execute(state_ctx: *anyopaque, game: *Game) anyerror!void{
                log.debug("Size Of 'ctx' argument (*anyopaque): {d}\n", .{@sizeOf(@TypeOf(state_ctx))});

                // const self: *Ctx = @ptrCast(@alignCast(state_ctx)); // Will cast from *anyopaque into *Ctx. 
                const ptr: *Ctx = @alignCast(@ptrCast(state_ctx)); 
                log.debug("Size Of 'ctx' argument (*anyopaque) After Cast to *Ctx: {d}\n", .{@sizeOf(@TypeOf(ptr))});
                log.debug("Info → const ptr: *Ctx = @alignCast(@ptrCast(state_ctx)): {}\n", .{@typeInfo(state_ctx)});
                log.debug("Info → const type_erased_ptr = ptr.* : {}\n", .{@typeInfo(state_ctx)});
                if (true) @panic("Debug panic in 'any_execute'!"); 
                
                // E.g., exe_func(ptr, game) → fn(ctx: *GameState, game: *Game). 
                return exe_func(ptr, game); //NOTE: - Or should I dereference the ptr.* ?
            }

            fn any_update(state_ctx: *anyopaque) anyerror!void{
                // const self: *Ctx = @ptrCast(@alignCast(state_ctx)); 
                const ptr: *Ctx = @alignCast(@ptrCast(state_ctx));
                return update_func(ptr);
            }

            fn any_transition(state_ctx: *anyopaque, next_state: *anyopaque) anyerror!void{
                const self: *Ctx = @ptrCast(@alignCast(state_ctx)); 
                const next: *Ctx = @ptrCast(@alignCast(next_state)); 
                // const self: *Ctx = @alignCast(@ptrCast(state_ctx));
                return transition_func(self, next);
            }
        };

    }

}; 



pub fn debug_info(any: anytype, allocator: std.mem.Allocator) !void {
    const self_info = try std.debug.SelfInfo.init(allocator);
    const mem_accessor = std.debug.MemoryAccessor.init; 
    std.debug.print("Size of type: {}, Alignment: {}\n", .{@sizeOf(@TypeOf(any)), @alignOf(@TypeOf(any))});  
    _ = self_info; 
    _ = mem_accessor; 
}

pub const AnyGameState = State.AnyState(
                        *GameState, 
                        GameState.execute, // Execute state specific action. 
                        GameState.fsm_update, // Updates the FSM, by handling incoming events.
                        GameState.fsm_transition 
                    );

// const abc = GameState.execute(ctx: *anyopaque, game: *Game(GameConfig))


// Game → GameState (has a State.AnyState field) → AnyState → State. 

/// The `GameState` tagged union, represent the concrete active state. 
/// It executes and gain access to only the active state's functionality. 
/// Main purpose of this design principle is to have a clear separation 
/// of the responsibility during different phases of the game. 
pub const GameState = union(State.Kind) {
    /// This is the default starting state, during the setup. 
    Initial: AnyGameState, 
    /// The `Menu` state, is the first entry prompt, and when waiting for expected 
    /// players to connect. 
    MainMenu,
    /// Whenever, we are in the `playing` state, we can perform game actions. 
    /// This is the state, for picking a red card during the game round. 
    Playing,

    /// During the `Waiting` state, we have either performed our actions for that round. 
    /// Or we are waiting for players to join the game. In other words, in this state, 
    /// we wait for other players to finish their moves (actions).
    Waiting,

    /// The `Judging` state, is the same as playing state, but execute 
    /// voting actions instead. By picking the appropriate card among the 
    /// received ones. 
    Judging,

    /// Update state, is the updated and modified instance components. 
    /// This is e.g., when we finish a game round and update scores etc...
    Update, 

    pub const GameStateError = error {
        FailedObtainingInternalEventDuringTransition,
    };

    pub fn get_kind(self: GameState) State.Kind {
        const tag: State.Kind = self;
        return tag; 
    }

    pub fn init(kind: State.Kind) GameState{
        // AnyGameState{.ctx = GameState{.Initial = .}}
        return switch (kind) {
            .Initial => GameState{.Initial},
            .MainMenu => GameState{.MainMenu},
            .Playing => GameState{.Playing},
            .Judging => GameState{.Judging},
            .Waiting => GameState{.Waiting},
            .Update => GameState{.Update},
        };
    }

    /// This would create a `State` from the current active 
    /// union type, or the GameState variant. Maps and casts 
    /// into the State interface aligned type. 
    pub fn state(self: *GameState) State{

        // switch (self.*) {
        //     inline else => |*ctx| ctx.new(),
        // }

        // const active_state = self.get_kind();
        // const state_obj = AnyGameState.new(self, active_state);
        

        return switch(self.*){
            .Initial => |*ctx| ctx.new(),
            .MainMenu => |*menu_ctx| menu_ctx.new(),
            .Playing => |*play_ctx| play_ctx.new(),
            .Judging => |*judge_ctx| judge_ctx.new(),
            .Waiting => |*wait_ctx| wait_ctx.new(),
            .Update => |*update_ctx| update_ctx.new(),
        };
    }

    fn dummy_callback(ctx: ?*anyopaque) !void {
        var self: *GameState = @ptrCast(@alignCast(ctx)); 
        std.log.debug("{s} executed callback! \n", .{self.get_state().toString()});
    }
    

    pub fn fsm_transition(self: *GameState, next_state: State) !State{
        return try self.intoState().transition(next_state);
        // self.state = next_state;

    }

    pub fn fsm_update(self: *GameState) !void {
        switch (self.*) {
            .Initial => |*initial| {
                initial.new().update();
            },
            inline else => |*active_state| {
                active_state.new().update();
            }
        }
    }

    pub fn execute(ctx: *anyopaque, game: *Game) !void {
        const self: *GameState = @ptrCast(@alignCast(ctx));
        while(game.scheduler.poll_event()) |event| {
            log.debug("\n--- Dispatching Event: {s} ---\n", .{event.toString()}); 
            try self.handleEvent(event); 
            // self.state.update();
            
        }
        // self.fsm_handle(event_input: Event)
        switch (self.*) {
            inline else => |*active_state| {
                active_state.execute();
            }
        }

    }

    /// The `fsm_handle` is a "Finite-State-Machine" state machine pattern logic. That
    /// would encapsulate system behavior, by separating logic into concrete states, 
    /// that would transition based on input events. 
    pub fn handleEvent(self: *GameState, event_input: Event) GameStateError!void {

        const current_state = self.get_state(); 
        const event_kind = event_input.tryIntoInternalEvent() orelse return GameStateError.FailedObtainingInternalEventDuringTransition; 
        std.debug.print("Current State: {s}, Received Event: {s}\n", .{current_state.toString(), event_kind.toString()});
        
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

    const expected_states = [_]State.Kind{
        .Initial,
        .MainMenu,
        .Playing,
        .Waiting,
        .Judging,
        .Update,
    };

    const test_events = [_]events.InternalEvent{
        .StartGame, 
        .PlayedCard, 
        .NextRound,
        .JudgeVoted, 
    };
    
    // var initial_state = GameState{.Initial = .{ .setup_callback =  }

    _ = expected_states; 
    _ = test_events; 

    for (user_inputs) |action_event| {
        const event = try Event.parse(action_event);
        _ = event; 

    }
}




