//! Module for holding the tighlty coupled components: `State`, `GameState`, `Event` and `TaskScheduler`.
//! This module is consumed by the `Game` type in `game.zig`. 

const std = @import("std"); 
const log = std.log.scoped(.game_state);

const event = @import("events.zig");
const state = @import("states.zig");
const task_scheduler = @import("task_scheduler.zig");

pub const Event = event.Event;
pub const InternalEvent = event.InternalEvent;
pub const UserInput = event.UserInput;
pub const NetworkEvent = event.NetworkEvent;
pub const EventMessage = event.EventMessage;

pub const State = state.State;
pub const GameState = state.GameState;

pub const TaskScheduler = task_scheduler.TaskScheduler;
pub const TaskCallback = task_scheduler.TaskCallback;


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
