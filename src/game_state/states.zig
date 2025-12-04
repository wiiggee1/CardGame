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
const events = @import("events.zig"); 
const task_scheduler = @import("task_scheduler.zig");
const game_state = @import("game_state.zig");

const TaskCallback = task_scheduler.TaskCallback;
const TaskScheduler = task_scheduler.TaskScheduler;
const Event = events.Event; 

// const GameConfig = @import("../game.zig").GameConfig; 
// const Game = @import("../game.zig").Game(GameConfig); 

const GameState = game_state.GameState;
const log = std.log.scoped(.gamestate_states);

pub const StateError = error{
    CreatingStateFailed,
    ExecutingStateFailed,
    TransitionToStateFailed,
    UpdatingStateFailed,
};

// pub fn StateContextType(comptime StateKind: State.Kind) type{}

// std.fs.File.stdout → hStdOutput → HANDLE → *anyopaque

//TODO: - Should the state interface init methods pass arguments or not, such as input and output 
// buffers? Or passing a config struct as argument?

pub fn StateBuilder(comptime StateKind: State.Kind) type{
    const StateType = switch (StateKind) { 
        .Initial => game_state.Initial, 
        .MainMenu => game_state.MainMenu, 
        .Playing => game_state.Playing, 
        .Waiting => game_state.Waiting, 
        .Judging => game_state.Judging, 
        .Update => game_state.Update, 
    };

    return struct {
        const Self = StateType;
        // const Self = @This();


        pub fn initFrom(state_ctx: anytype) Self{
            const StatePtr = @TypeOf(state_ctx);
            std.debug.assert(@typeInfo(StatePtr) == .pointer); // Need to be a pointer.
            std.debug.assert(@typeInfo(StatePtr).pointer.size == .one); // Must be a single-item pointer.
            std.debug.assert(@typeInfo(@typeInfo(StatePtr).pointer.child) == .@"struct"); // Must point to struct.

            // const context_x: *StateType = @alignCast(@fieldParentPtr("state", state_ctx));
            
            // return Self{
            //     .ctx = .{
            //         .state = initStateInterface(state_ctx),
            //         .data = {},
            //     },
            //     .kind = StateKind,
            // };

            return Self{
                .state = initStateInterface(state_ctx),
                .data = {},
            };
        }
        
        pub fn init() Self{
            return Self{
                .state = initStateInterfaceDefault(),
            };
        }

        
        pub fn initStateInterfaceDefault() State{
            std.debug.assert(@hasDecl(StateType, "execute"));
            std.debug.assert(@hasDecl(StateType, "update"));
            std.debug.assert(@hasField(StateType, "state"));
            const state_vtable = create_vtable(StateType);

            return State{
                .kind = StateKind,
                .vtable = &state_vtable,
            };
        }

        pub fn initStateInterface(state_ptr: anytype) State{
            // const context: *StateType = @alignCast(@fieldParentPtr("state", state_ptr));

            const StatePtr = @TypeOf(state_ptr);
            std.debug.assert(@typeInfo(StatePtr) == .pointer); // Need to be a pointer.
            std.debug.assert(@typeInfo(StatePtr).pointer.size == .one); // Must be a single-item pointer.
            std.debug.assert(@typeInfo(@typeInfo(StatePtr).pointer.child) == .@"struct"); // Must point to struct.

            // const StatePtrType = @typeInfo(@typeInfo(StatePtr).pointer.child);
            const StatePtrType = @typeInfo(StatePtr).pointer.child;
            std.debug.assert(@hasDecl(StatePtrType, "execute"));
            std.debug.assert(@hasDecl(StatePtrType, "update"));

            const state_vtable = create_vtable(StatePtrType);

            return State{
                // .ptr = @ptrCast(@alignCast(state_ptr)),
                // .ptr = state_ptr,
                .kind = StateKind,
                .vtable = &state_vtable,
            };
        }

        fn create_vtable(StateChildType: type) State.StateVTable{
            std.debug.assert(StateChildType == StateType);

            return State.StateVTable{
                .execute_fn = StateType.execute,
                // .transition_fn = StateType.transition,
                .update_fn = StateType.update,
            };
        }
        
        // /// A `Mixin` provide methods to manipulate a types field.
        // pub fn execute_mixin(self: *Self, game: *Game) StateError!void{
        //     // const initial = self.state_interface.as(game_state.Initial);
        //     const context_x: *StateType = @alignCast(@fieldParentPtr("state", self));
        //     context_x.state.execute(game);
        // }

    };
}

//NOTE:: 
// 1. Using @fieldParentPtr: The interface is the State field embedded directly in each concrete state.
// 2. We pass around and store a *State (pointer to that field). 
// 3. Inside vtable functions we use @fieldParentPtr to go from *State → *ConcreteState.

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
    // ptr: *anyopaque,
    kind: Kind, 
    vtable: *const StateVTable,


    pub const StateVTable = struct {
        // execute_fn: *const fn(ctx: *anyopaque, game: *Game) StateError!void,
        // transition_fn: *const fn(ctx: *anyopaque, next_ctx: *anyopaque) StateError!State,
        // update_fn: *const fn(ctx: *anyopaque) StateError!void,
        execute_fn: *const fn(ctx: *State, game_ctx: *anyopaque) StateError!void,
        // transition_fn: *const fn(ctx: *State, next_state: *State) StateError!void,
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

    // pub fn init(comptime StateKind: Kind) State { 
        // pub fn init(state_obj: anytype) State { 
        // const d: *Discarding = @alignCast(@fieldParentPtr("writer", w));
        // const w: *Writer = @alignCast(@fieldParentPtr("interface", io_w)); 
        // const StateImpl = State.into(StateType, state_obj); 

        // return State{ 
        //     // .ptr = state_obj, // concrete state pointer type
        //     .kind = StateKind, 
        //     .vtable = &.{ 
        //         .execute_fn = StateImpl.execute, 
        //         .transition_fn = StateImpl.transition, 
        //         .update_fn = StateImpl.update, 
        //     } 
        // }; 
    // }

    /// Helper for casting into a specific State Type.
    pub fn asContext(self: *State, comptime T: type) *T {
        const context: *T = @alignCast(@fieldParentPtr("state", self));
        return context;
        // return @as(*T, @alignCast(@fieldParentPtr("state", self)));
    }

    pub fn execute(self: *State, game_ctx: *anyopaque) StateError!void{
        // pub fn execute(self: *State, game: *Game) StateError!void{
        // self.vtable.execute_fn(self.ptr, game);
        self.vtable.execute_fn(self, game_ctx);
    }

    pub fn transitionInto(self: *State, comptime new_state: Kind) StateError!void{
        // var next_state = State.init(new_state);
        // const next_state: *State = @alignCast(@fieldParentPtr("state", state_base));
        const StateType = switch (new_state) { 
            .Initial => game_state.Initial, 
            .MainMenu => game_state.MainMenu, 
            .Playing => game_state.Playing, 
            .Waiting => game_state.Waiting, 
            .Judging => game_state.Judging, 
            .Update => game_state.Update, 
        };

        const context: *StateType = @alignCast(@fieldParentPtr("state", self));
        
        // self = &next_state;
        self = &context.state;
    }

    pub fn update(self: *State) StateError!void{
        // self.vtable.update_fn(self.ptr);
        self.vtable.update_fn(self);
    }

}; 


pub fn debug_info(any: anytype, allocator: std.mem.Allocator) !void {
    const self_info = try std.debug.SelfInfo.init(allocator);
    const mem_accessor = std.debug.MemoryAccessor.init; 
    std.debug.print("Size of type: {}, Alignment: {}\n", .{@sizeOf(@TypeOf(any)), @alignOf(@TypeOf(any))});  
    _ = self_info; 
    _ = mem_accessor; 
}

test "state-transitions" {

    const starting: game_state.Initial = StateBuilder(.Initial).init();
    std.debug.print("Current State: {any}, kind: {any}\n", .{starting.state, starting.state.kind});

    var active_state = starting.state;
    std.debug.print("Trying to transition from {any} → {any} State\n", .{active_state.kind, State.Kind.Judging});

    try active_state.transitionInto(.Judging);
    std.debug.print("New State: {any}\n", .{starting.state});

    const playing = active_state.asContext(game_state.Playing);
    active_state = playing.state;
    std.debug.print("New Current State: {any}\n", .{active_state});

    try active_state.transitionInto(.Waiting);
    std.debug.print("New Active State: {any}\n", .{active_state});
    
    try active_state.transitionInto(.MainMenu);
    std.debug.print("Updated State To: {any}\n", .{active_state});

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
    
    _ = user_inputs;
    _ = expected_states; 
    _ = test_events; 

    //
    // for (user_inputs) |action_event| {
    //     const event = try Event.parse(action_event);
    //     _ = event; 
    //
    // }
}




