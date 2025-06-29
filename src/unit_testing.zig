//! To run the unit testing, we have to add the following into the build.zig: 
//! 
//! ```
//!     const tests = b.addTest(.{
//!         .target = target,
//!         .optimize = optimize,
//!         .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple }, // add this line
//!         .root_source_file = b.path("src/main.zig"),
//!     });
//! ```
//!

const std = @import("std");
const builtin = @import("builtin");
// const game = @import("game.zig");
// const settings = @import("settings.zig");
// const states = @import("game_state/states.zig");
// const events = @import("game_state/events.zig");
// const task_scheduler = @import("game_state/task_scheduler.zig");
const logger = @import("log.zig");

pub const std_options: std.Options = .{
    .logFn = logger.loggerFn,
};

const TestingError = error {
    TestCaseFailed,
} || std.fmt.ParseIntError || std.process.GetEnvMapError || std.io.AnyWriter.Error;


pub const TestCase = struct{test_name: []const u8, metric: TestMetric, duration: ?i64, err_msg: ?TestingError};

pub const TestMetric = enum {
    passed,
    failed,
    leaked,
    total, 

    fn fromString(str: []const u8) ?TestMetric{
        return std.meta.stringToEnum(TestMetric, str) orelse null;
    }
};

pub const TestSummary = struct {
    passed: usize = 0, 
    failed: usize = 0, 
    leaked: usize = 0, 
    total: usize = 0, 
    test_cases: std.ArrayList(TestCase), 
    module_name: ?[]const u8 = null, 


    fn showTestSummary(self: TestSummary, file_writer: std.fs.File.Writer, comptime format: []const u8) !void{
        const fields = @typeInfo(@TypeOf(self)).@"struct".fields;
        if(std.mem.eql(u8, format, "")){
            if (self.module_name) |mod_name| {
                if (std.mem.eql(u8, mod_name, "game")){
                    try getModuleNameHeader("Game Module", file_writer);
                }else if (std.mem.eql(u8, mod_name, "game_state")){
                    try getModuleNameHeader("GameState Module", file_writer);
                }else if (std.mem.eql(u8, mod_name, "events")){
                    try getModuleNameHeader("GameState Module [Events]", file_writer);
                }else if (std.mem.eql(u8, mod_name, "states")){
                    try getModuleNameHeader("GameState Module [States]", file_writer);
                }else if (std.mem.eql(u8, mod_name, "task_scheduler")){
                    try getModuleNameHeader("GameState Module [TaskScheduler]", file_writer);
                }
            }else {
                const header_str = "╚═Unit Test Summary═╝";
                try file_writer.print("\n\t\t {s:^25}\n", .{header_str});
            }
        }else {
            try file_writer.print(format, .{});
        }

        inline for(fields) |field| {
            const metric = TestMetric.fromString(field.name);
            if (metric) |metric_tag|{
                // const metric_string = comptime switch (metric) {
                switch (metric_tag) {
                    .passed => try file_writer.print("\x1b[1;33m Passed ✅ {d}/{d} tests\x1b[0m | ", .{self.passed, self.total}),
                    .failed => try file_writer.print("\x1b[1;31m Failed ❌ {d}/{d} tests\x1b[0m | ", .{self.failed, self.total}),
                    .leaked => try file_writer.print("\x1b[1;35m Leaked ⚠️ {d}/{d} tests\x1b[0m | ", .{self.leaked, self.total}),
                    .total => {}, 
                }
            }
            // const print_format = "{s:<10}: " ++ switch (field.type) {
            // try file_writer.print(metric_string, .{self});
        }
        try file_writer.print("\x1b[0m \n\n", .{}); 
     
    }

    fn showAllTestCases(self: TestSummary, file_writer: std.fs.File.Writer) !void {
        for (self.test_cases.items, 0..) |test_case, i| {
            const name = test_case.test_name; 
            switch (test_case.metric) {
                .passed => {
                    if (test_case.duration) |duration| {
                        try file_writer.print("Test: {s:<20} :\tPassed, duration: {d}ms ✅\n", .{name, duration}); 
                    }else {
                        try file_writer.print("Test: {s:<20} :\tPassed ✅\n", .{name}); 
                    }
                },
                .failed => {
                    if (test_case.err_msg) |err| {
                        try file_writer.print("Test: {s:<20} :\tFailed: {} ❌\n", .{name, err});
                    }
                },
                .leaked => {
                    const prior = self.test_cases.items[i - 1]; 
                    if (std.mem.eql(u8, prior.test_name, name)){
                        try file_writer.print("\t↪ Leaked memory ⚠️\n", .{}); 
                    }
                },
                .total => {},
            }
        }
    }

    //TODO: 
    fn showMemoryFootprint(self: TestSummary, file_writer: std.fs.File.Writer) void {
        _ = self; 
        _ = file_writer; 
    }

    fn getModuleNameHeader(comptime mod_name: []const u8, file_writer: std.fs.File.Writer) !void {
        // const len = "Passed ✅ 5/5 tests |  Failed ❌ 0/5 tests |  Leaked ⚠️ 0/5 tests |";
        // const format = "\n\t\t\x1b[1;36m{s:^23}\x1b[0m\n";
        // const format_header = "\t\t\x1b[1;36m╚═{s}═╝\x1b[0m\n\n";
        // const header_str = "═Unit Test Summary═";

        const color_start = "\x1b[1;36m ";
        const color_end = "\x1b[0m";
        const module_section = color_start++mod_name++color_end++"\n"; 
        const delim = "═════════════════════";
        const delimiter = color_start++delim++color_end++"\n";
        const info_format = color_start++"╚═Unit Test Summary═╝"++color_end;

        // try file_writer.print("\n\t\t\x1b[1;36m{s:^23}\x1b[0m\n", .{mod_name});
        // try file_writer.print("\t\t\x1b[1;36m{s:═^23}\n", .{""});
        // try file_writer.print(format_header, .{header_str});

        const delim_len: usize = std.mem.count(u8, delim, "═");
        const diff_len: i64 = @as(i64, @intCast(delim_len)) - @as(i64, @intCast(mod_name.len));
        const diff_abs = @abs(diff_len);

        // If it exceed the delimiter length.
        if (diff_len < 0){
            const offset: u64 = @divFloor(diff_abs, 2); 
            switch (offset) {
                0...5 => try file_writer.print("\n{s:>59}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format}),
                6...10 => try file_writer.print("\n{s:>62}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format}),
                11...20 => try file_writer.print("\n{s:>64}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format}), 
                else => try file_writer.print("\n{s:>68}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format}),
            }
        }else {
            std.debug.print("diff_len is less than 0! \n", .{});
            if (diff_len > 0 and diff_len <= 5){
                try file_writer.print("\n{s:=>53}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format});
            }else if (diff_len > 0 and diff_len > 10){
                try file_writer.print("\n{s:=>48}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format});
            }else if (diff_len > 5 and diff_len <= 10){
                try file_writer.print("\n{s:=>50}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format});
            }
        }
        // try file_writer.print("\n{s:=>50}{s:=>56}{s:=>55}\n", .{module_section, delimiter, info_format});
    }

};

pub fn main() !void {
    var mem: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    // var debug_allocator = std.heap.DebugAllocator(.{.stack_trace_frames = 10,}){};
    // const allocator = debug_allocator.allocator(); 
    const allocator = fba.allocator(); 
    
    const test_filter = std.process.getEnvVarOwned(allocator, "TEST_FILTER") catch |err| blk: {
        if (err == error.EnvironmentVariableNotFound) break :blk  "";
        return err;
    };

    // std.posix.termios
    // @cImport(@cInclude("ncurses_dll.h")) 

    var coverage = TestSummary{.test_cases = std.ArrayList(TestCase).init(allocator)};
    defer coverage.test_cases.deinit(); 

    const stderr = std.io.getStdErr().writer();
    try stderr.print("\n", .{});
    try stderr.print("\r\x1b[0K", .{}); // beginning of line and clear to end of line

    for (builtin.test_functions) |test_target| {
        // std.debug.print("test_target: {}\n", .{test_target});
        std.testing.allocator_instance = .{};
        var iter = std.mem.splitScalar(u8, test_target.name, '.'); 
        
        const module_name: []const u8 = mod_blk: {
            const mod_name = iter.first(); 
            if (std.mem.eql(u8, mod_name, "game")){
                break :mod_blk "game";
            }else if (std.mem.eql(u8, mod_name, "game_state")){
                break :mod_blk "game_state";
            }else if (std.mem.eql(u8, mod_name, "events")){
                break :mod_blk "events";
            }else if (std.mem.eql(u8, mod_name, "states")){
                break :mod_blk "states";
            }else if (std.mem.eql(u8, mod_name, "task_scheduler")){
                break :mod_blk "task_scheduler";
            }
            break :mod_blk mod_name;
        };
        
        if (coverage.module_name == null){
            coverage.module_name = module_name; 
        }
        
        if (iter.peek()) |peek_str| {
           if (std.mem.eql(u8, peek_str, "test")){
                _ = iter.next(); 
            }
        }
        const test_name = iter.next();

        const name_test = test_name orelse test_target.name; 
        std.debug.print("Found Module name: {s} and test_function: {s}\n", .{module_name, name_test}); 


        if (std.mem.indexOf(u8, test_target.name, test_filter) == null) continue; 
         
        const start = std.time.milliTimestamp();
        test_target.func() catch |err| {
            // try stderr.print("Test: {s} :\tFailed with error: {} ❌\n", .{test_target.name, err});
            try coverage.test_cases.append(.{.test_name = name_test, .metric = .failed, .duration = null, .err_msg = err}); 
            coverage.failed += 1; 
            if (@errorReturnTrace()) |stack_trace| {
                // std.builtin.StackTrace{}
                // std.debug.StackIterator.init(first_address: ?usize, fp: ?usize)
                std.debug.dumpStackTrace(stack_trace.*);
            }
            continue;
        };

        const end = std.time.milliTimestamp();
        const duration: i64 = end - start; 
        // try stderr.print("Test: {s} :\tPassed, duration: {d}ms ✅\n", .{test_target.name, duration}); 
        try coverage.test_cases.append(.{.test_name = name_test, .metric = .passed, .duration = duration, .err_msg = null}); 

        if (std.testing.allocator_instance.deinit() == .leak){
            const func_addr = @intFromPtr(test_target.func);
            std.debug.print("Test Function Addr: {d}\n", .{func_addr});
            // std.debug.dumpCurrentStackTrace(func_addr);
            // std.debug.dumpStackPointerAddr(prefix: []const u8)

            // try stderr.print("\n\tTest: {s} :\tLeaked memory ⚠️\n", .{test_target.name}); 
            try coverage.test_cases.append(.{.test_name = name_test, .metric = .leaked, .duration = duration, .err_msg = null}); 
            coverage.leaked += 1; 
        }
        coverage.passed += 1; 
    }
    coverage.total = coverage.passed + coverage.failed; 
    try coverage.showTestSummary(stderr, ""); 
    // try coverage.showTestSummary(stderr, module_name_header); 
    try coverage.showAllTestCases(stderr);
    
}


