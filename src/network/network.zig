//! The network module provide hidden (private) APIs in terms of communication protocol during gameplay. 
//! It would define the RCP types, functionality related to the server-client communication, and more. 
//!
//! ------------------------------------
const std = @import("std"); 
const client = @import("client.zig");
const server = @import("server.zig");
const rpc = @import("rpc.zig");
