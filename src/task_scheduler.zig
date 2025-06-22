//! This file contain definition, for runnable tasks. But mainly a logic for creating 
//! and managing a task scheduler, through a order-based Queue data structure. The 
//! scheduler itself, is related to the `Event` types as well as mapping of events 
//! to callback with context. In other words a `TaskEvent` => Callback + Context. 

const std = @import("std"); 
const states = @import("states.zig");
const events = @import("events.zig");

const InternalEvent = events.InternalEvent; 
const UserInput = events.UserInput;  
const NetworkEvent = events.NetworkEvent;
const Event = events.Event; 
const EventMessage = events.EventMessage; 

const GameState = states.GameState;  

const Game = @import("game.zig").Game;
const GameConfig = @import("game.zig").GameConfig;


// According to Zig documentation the following are stated: 
// --------------------------------------------------------
// "There is a difference between a function body and a function pointer.
// Function bodies are comptime-only types while function Pointers may be
// runtime-known"
// --------------------------------------------------------
// The reason not to use `anytype` for callbacks are because: 
// `anytype` is resolved at compile time, and you're trying to store a
// generic function in data — which must be concrete and type-erased
// to store in collections or pass around dynamically.
// ------------------------------------------
// General information: 
// → `anytype` is evaluated at compile-time, it acts like C++ `auto` or `template<typename T>`.
//     ... Generic code → use `anytype`.
//
// → `*anyopaque` - runtime, `Type-Erased Pointer`, it must be cast back to its original type 
// using `@ptrCast`. Common for callbacks with unknown data and runtime polymorphism. 
//     ... Store and call things dynamically → use `anyopaque` + function pointers.
// ------------------------------------------

const CallbackFnBody = fn (ctx: *anyopaque) anyerror!void; // Function bodies → Comptime-only.
const CallbackFnPtr = *const fn (ctx: ?*anyopaque) anyerror!void; // Function Pointer Type + *anyopaque → Runtime-known.
const CallbackEventFnPtr = *const fn (ctx: ?*anyopaque, ?Event) anyerror!void; // Function Pointer Type + *anyopaque → Runtime-known.
const CallbackArgsType = std.meta.ArgsTuple(CallbackFnPtr);

const TaskQueue = std.DoublyLinkedList(TaskCallback);
// const TaskQueue = std.PriorityQueue(Key, Value, .lt); 

/// This represent a runnable `Task`, containing a 
/// callback (function pointer) as `func` and an 
/// associated context field `ctx`. 
/// Defining the context in runnable tasks, require
/// the caller to cast to the inteded pointer type. 
pub const TaskCallback = struct {
    ctx: ?*anyopaque = null, 
    func: CallbackFnPtr,
    // func: CallbackEventFnPtr,
    // event_func: CallbackEventFnPtr = null,

    pub fn run_task(self: TaskCallback) !void {
        return self.func(self.ctx); 
        // return self.func(self.ctx, event); 
    }
    
    pub fn from(comptime T: type, ctx: ?*anyopaque) TaskCallback {
        if (!@hasDecl(T, "run_task")) @compileError("Callback ctx type "++@typeName(T)++" missing 'run_task' declaration!"); 
        // @fieldParentPtr(comptime field_name: []const u8, field_ptr: *T)


        const self: *T = @ptrCast(@alignCast(ctx)); 
        return TaskCallback{
            // .func = T.run,
            // .func = self.run_task,
            .func = self.run_task,
            .ctx = self,
        };
    }

};


/// Task hashmap for mapping event types into 
/// a callback function with an associated context pointer. 
/// So whenever an event occur we execute a function from
/// the context. 
pub const TaskMap = std.AutoHashMap(Event, TaskCallback); 


/// The generic `TaskScheduler` should act like a task scheduler that manages events, 
/// by enqueuing and dequeuing events. Whenever, an event occur, it should be able to 
/// run an associated event callback function that should be executed. 
pub fn TaskScheduler(comptime E: type) type {
    if (E != Event){
        @compileError("The type must be an `Event` enum. "++"Got: "++@typeName(@TypeOf(E))); 
    }

    return struct {
        const Self = @This(); 
        pub const Key: type = Event; // type alias 
        pub const Task: type = TaskCallback; // type alias 
        pub const EventQueue = std.ArrayList(Key); 
        pub const TaskEventQueue = std.DoublyLinkedList(TaskEvent); 
        pub const FifoQueue = std.fifo.LinearFifo(TaskEvent, .Dynamic);

        //WARN: - Decide if I should use LinkedList for my Queues or is an ArrayList enough? 
    
        pub const TaskEvent = struct {
            event: Event,
            task: Task, 

            pub fn new(event_type: Event, task_: Task) TaskEvent {
                return TaskEvent{.event = event_type, .task = task_}; 
            }

            pub fn get_event(self: TaskEvent) Event {
                
                return self.event; 
            }

            pub fn get_task(self: TaskEvent) Task {
                return self.task; 
            }
        };
      
        //TODO: - Should I use all three: TaskMap, EventQueue, and TaskQueue? 
        // Or should I embed it and use a TaskEvent → Task + Event struct? 

        tasks: TaskMap, 
        event_queue: EventQueue, 
        task_queue: TaskEventQueue, 
        // task_queue: TaskQueue, 
        allocator: std.mem.Allocator, 

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .tasks = TaskMap.init(allocator),
                .event_queue = EventQueue.init(allocator),
                .task_queue = TaskEventQueue{},
                .allocator = allocator,
            }; 
        }

        pub fn deinit(self: *Self) void{
            self.tasks.deinit();
            self.event_queue.deinit(); 
        }

        /// Executes the main event loop. Should process and handle static
        /// enqueued events in the queue. This act as an `Event Dispatcher`.
        pub fn event_dispatch(self: *Self, game_state: *GameState) !void {
            // const events = [_]Event{ .StartGame, .PlayedCard, .NextRound };
            while(true) {
                const latest_event = self.event_queue.pop(); // pop or dequeues from FIFO event queue. 
                if (latest_event) |event| {
                    std.debug.print("\n--- Dispatching Event: {s} ---\n", .{event.toString()}); 
                    try self.run_callback(event); 
                    try game_state.transition(event); 

                }else {
                    std.debug.print("All event tasks have been processed!\n", .{}); 
                    break;
                }
            }
        }

        pub fn run_callback(self: *Self, event: Event) !void {
            if (self.tasks.get(event)) |cb| {
                // try cb.run(); 
                // try cb.run_task(event); 
                try cb.run_task(); 
            }
        }


        /// Adds new event to the queue. 
        pub fn enqueue(self: *Self, event: Key) void {
            // event_queue.enqueue(Event{ .event_type = .EnemySpotted, .task = my_task });
            try self.event_queue.append(event);
        }

        pub fn print_callbacks(self: *Self) void {
            var iter = self.tasks.iterator();

            while (iter.next()) |cb| {
                const event = cb.key_ptr.*; 
                const cb_value = cb.value_ptr.*; 
                std.debug.print("Registered event: {s}\n", .{event.toString()});
                std.debug.print("\tContext value: {any}\n", .{cb_value});
            }
        }

        /// Should add/setup/define new tasks associated with an `Event` type. 
        /// This is the same as adding new function pointers to the `HashMap`.
        /// Alt. we could define it as: 
        /// `fn add_callback(comptime T: type, ctx: anytype, callback: fn(@TypeOf(ctx), T) void) void {}`
        /// pub fn add_new(self: *Self, event: E, ctx: anytype, func: CallbackFnPtr) void {
        /// ------------------------------------------
        pub fn register(self: *Self, event: E, cb: TaskCallback) !void {
            // const allocator_ctx_example: *ArenaAllocator = @ptrCast(@alignCast(ctx));
            
            // const new_task = TaskCallback{
            //     .func = func, 
            //     .ctx = switch (ctx_info) {
            //         .pointer => @ptrCast(@alignCast(ctx)),
            //         else => @ptrCast(@alignCast(&ctx)),
            //     }
            // }; 
            try self.tasks.put(event, cb); 
            std.debug.print("Added new Callback for Event: {s}\n", .{event.toString()}); 

            // const new_task = TaskEvent.new(event, cb);
        }

        /// Similar to `from` logic, where we create a new `TaskCallback`
        pub fn create_task(self: *Self, comptime T: type, ctx: ?*anyopaque) TaskCallback {
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

            //     fn alloc(ctx: *anyopaque, n: usize, alignment: mem.Alignment, ra: usize) ?[*]u8 {
            //          const self: *ArenaAllocator = @ptrCast(@alignCast(ctx));

            const ctx_example: *T = @ptrCast(@alignCast(ctx));
            const new_task = TaskCallback{.ctx = ctx_example, .func = ctx_example.run_task};
            _ = self; 
            return new_task; 

            // var game_context = try Game().init(self.allocator, .{}); 
            // const game_state = GameState{.Playing = PlayingState{.func = void}};


            // const next_event: Event = undefined;
            // switch (next_event) {
            //     .PlayedCard => return TaskCallback{
            //         .ctx = &game_context,
            //         .func = game_context.play_card, 
            //         // .state = game_state,
            //     },
            //     .JudgeVoted => return TaskCallback{
            //         .ctx = &game_context,
            //         .func = game_context.vote_callback, 
            //         // .state = game_state,
            //     }
            // }
        }
    };
}


fn test_callback_fn(callback_fn: CallbackFnPtr, callback_fn_body: CallbackFnBody, ctx1: anytype, ctx2: anytype) !void {
    const callback_fn_ptr_info = @typeInfo(@TypeOf(callback_fn(ctx1))); 
    const callback_fn_body_info = @typeInfo(@TypeOf(callback_fn_body(ctx2))); 
    std.debug.print("CallbackFnPtr: {any}\n", .{callback_fn_ptr_info});
    std.debug.print("CallbackFnBody type: {any}\n", .{callback_fn_body_info});

    std.debug.print("Executing CallbackFnPtr: \n", .{});
    callback_fn(ctx1); 
    std.debug.print("Executing CallbackFnBody: \n", .{});
    callback_fn_body(ctx2); 
}

fn eventmsg_callback(ctx: ?*anyopaque) !void {
    const ctx_type: *EventMessage = @ptrCast(@alignCast(ctx));
    const ctx_event = @tagName(ctx_type.event); 
    std.debug.print("Hello from CTX instance: {s}!\n", .{@typeName(@TypeOf(ctx_type.*))}); 
    std.debug.print("\t{s}: {s}\n", .{ctx_event, ctx_type.message});
    @panic("eventmsg_callback stop!"); 
}

fn on_event(ctx: ?*anyopaque) !void {
    // const callback = Callback.from(comptime T: type, ctx: ?*anyopaque)
    _ = ctx; 
}

test "event_callbacks" {
    // const context_1: struct {event: Event, message: []const u8} = .{.event = .StartGame, .message = "You may start the game now!"};
    // const context_2: struct {event: Event, message: []const u8} = .{.event = .ReceivedCard, .message = "You received a new card!"};
    // try test_callback_fn(callback_hello_fn, callback_hello_fn, context_1, context_2); 
}

test "adding_callbacks" {
    var callback_ctx1 = EventMessage{.event = .PlayedCard, .message = "Red Card: 1337"}; 
    var callback_ctx2 = EventMessage{.event = .ReceivedCard, .message = "Green Card: Peepo"}; 
    const allocator = std.testing.allocator; 

    var callback_manger = TaskScheduler(Event).init(allocator); 
    defer callback_manger.deinit(); 

    const callback_1 = TaskCallback{.ctx = &callback_ctx1, .func = eventmsg_callback};
    const callback_2 = TaskCallback{.ctx = &callback_ctx2, .func = eventmsg_callback};
    // const callback_3 = TaskCallback.from(EventMessage, &callback_ctx1); 
    // _ = callback_3; 

    try callback_manger.register(.PlayedCard, callback_1); 
    try callback_manger.register(.ReceivedCard, callback_2); 
    
    callback_manger.print_callbacks(); 

    // try callback_manger.event_dispatch(); 

}

