pub const ServerInstance = struct {
    id: u8,

    pub fn notify_clients(self: *ServerInstance, msg: []const u8) !void {
        // for (clients) |client| {
        //     try client.send_message(msg);
        // }

        _ = self; 
        _ = msg; 
    }
};
