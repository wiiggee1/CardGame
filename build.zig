const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    
    const home_directory = std.process.getEnvVarOwned(b.allocator, "HOME") catch "";
    _ = home_directory; 

    // const lib_mod = b.createModule(.{
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        // .root_source_file = b.path("src/root.zig"),
        // .target = target,
        // .optimize = optimize,
    // });

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });


    // Modules can depend on one another using the `std.Build.Module.addImport` function.
    // This is what allows Zig source code to use `@import("foo")` where 'foo' is not a
    // file path. In this case, we set up `exe_mod` to import `lib_mod`.
    // exe_mod.addImport("CardGameZig", lib_mod);

    // Now, we will create a static library based on the module we created above.
    // This creates a `std.Build.Step.Compile`, which is the build step responsible
    // for actually invoking the compiler.
    // const lib = b.addLibrary(.{
    //     .linkage = .static,
    //     .name = "CardGameZig",
    //     .root_module = lib_mod,
    // });


    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "CardGameZig",
        .root_module = exe_mod,
    });

    // const settings_module = b.dependency("config", .{.target = target, .optimize = optimize}).module("config");

    // const state = b.createModule(.{ .root_source_file = b.path("src/game_state/states.zig") });
    // const event = b.createModule(.{ .root_source_file = b.path("src/game_state/events.zig") });
    // const task_scheduler = b.createModule(.{ .root_source_file = b.path("src/game_state/task_scheduler.zig") });

    const game_state_mod = b.addModule("game_state", .{
        .root_source_file = b.path("src/game_state/game_state.zig"),
        .target = target,
        .optimize = optimize,
    });


    // "A module is a directory of files, along with a root source file that identifies
    // the file referred to when the module is used with @import."

    const settings_mod = b.addModule("settings", .{
        .root_source_file = b.path("src/settings.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{.name = "cli", .module = b.createModule(.{
                .root_source_file = b.path("src/cli.zig"),
                .target = target,
                .optimize = optimize, 
            })},
        }
    });
    
    const game_mod  = b.addModule("game", .{
        .root_source_file = b.path("src/game.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{.name = "settings", .module = settings_mod},
            // .{.name = "game_state", .module = game_state_mod},
        },
    });
        
    const network_mod  = b.addModule("network", .{
        .root_source_file = b.path("src/network/network.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{.name = "client", .module = b.createModule(.{
                .root_source_file = b.path("src/network/client.zig"),
                .target = target,
                .optimize = optimize, 
            })},
            .{.name = "rpc", .module = b.createModule(.{
                .root_source_file = b.path("src/network/rpc.zig"),
                .target = target,
                .optimize = optimize, 
            })},
            .{.name = "server", .module = b.createModule(.{
                .root_source_file = b.path("src/network/server.zig"),
                .target = target,
                .optimize = optimize, 
            })},
        }
    });

    exe.root_module.addImport("game", game_mod); 
    exe.root_module.addImport("game_state", game_state_mod); 
    exe.root_module.addImport("network", network_mod); 

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This is where the interesting part begins.
    // As you can see we are re-defining the same executable but
    // we're binding it to a dedicated build step.
    const exe_check = b.addExecutable(.{
    .name = "CardGameZig",
    .root_module = exe_mod,
    });
    

    const check = b.step("check", "Check if 'CardGameZig' compiles");
    check.dependOn(&exe_check.step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_filter = b.option([]const u8, "test-filter", "Filters for test");

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_testing = b.addTest(.{
        .name = "game-test",
        .filters = if (test_filter) |filter| &.{filter} else &.{}, 
        // .root_source_file = b.path("src/game.zig"), // working
        .root_source_file = b.path("src/main.zig"), // testing?!?!?
        // .root_module = exe_mod,
        // .root_module = b.createModule(.{
        //         .root_source_file = b.path("src/game.zig"),
        //         // .root_source_file = b.path("src/main.zig"),
        //         .target = target,
        //         .optimize = .Debug,
        //         .strip = false,
        //         .omit_frame_pointer = false,
        //         .unwind_tables = .sync,
        // }),
        .test_runner = .{ .path = b.path("src/unit_testing.zig"), .mode = .simple},
    });

    const gamestate_testing = b.addTest(.{
        .name = "gamestate-test",
        .filters = if (test_filter) |filter| &.{filter} else &.{}, 
        .root_source_file = b.path("src/game_state/game_state.zig"), // working
        .test_runner = .{ .path = b.path("src/unit_testing.zig"), .mode = .simple},
    });

    _ = gamestate_testing; 

    // Add the imports that the game_mod is using to the test. 

    // Working
    unit_testing.root_module.addImport("settings", settings_mod);
    unit_testing.root_module.addImport("game_state", game_state_mod);
    unit_testing.root_module.addImport("game", game_mod);

    const run_game_testing = b.addRunArtifact(unit_testing);
    run_game_testing.has_side_effects = true; 
    
    // gamestate_testing.root_module.addImport("game", game_mod);
    // const runstep_gamestep = b.addRunArtifact(gamestate_testing);
    // runstep_gamestep.has_side_effects = true; 

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests (test runner) for the Game");
    test_step.dependOn(&run_game_testing.step);
    // test_step.dependOn(&runstep_gamestep.step);
}
