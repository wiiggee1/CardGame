const std = @import("std");

pub const custom_log_options = std.Options{
    .logFn = loggerFn,
};

//TODO: - Add `game`, `network` scope...

pub const custom_scope_options = [_]std.log.ScopeLevel{
    .{.scope = .multiple_lines, .level = .debug},
    .{.scope = .inner_scope, .level = .debug},
    .{.scope = .inner, .level = .debug},
    .{.scope = .str_part, .level = .debug},
};

pub fn loggerFn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void{
    var log_buf: [1024]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&log_buf);
    // const stderr = std.io.getStdErr().writer();
    const stderr = &writer.interface;


    const level_string = comptime switch (level) {
        .debug => "\x1b[1;34m[debug]\x1b[0m : ",
        .warn => "\x1b[1;33m[warn]\x1b[0m : ",
        .info => "\x1b[1;37m[info]\x1b[0m : ",
        .err => "\x1b[1;31m[err]\x1b[0m : ",
    };
    const is_inner: bool = switch(scope){
        .multiple_lines, .inner_scope, .inner, .str_part, .itr_start, .itr_end => true,
        else => false, 
    };

    if (is_inner){
        stderr.print(format, args) catch {};
    }else {
        // std.debug.print("scope: {}\n", .{scope});
        const scope_prefix = if (scope == .default) " " else " (" ++ @tagName(scope) ++ "): ";
        stderr.print(level_string ++ format ++ scope_prefix, args) catch {};
    }
    stderr.flush() catch {};
}
