const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjectStep = std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const test_step = b.step("test", "Test the program");
    test_step.dependOn(b.getInstallStep());

    const dylib = b.addSharedLibrary("a", null, b.version(1, 0, 0));
    dylib.setBuildMode(mode);
    dylib.addCSourceFile("a.c", &.{});
    dylib.linkLibC();
    dylib.install();

    const exe = b.addExecutable("test", null);
    exe.addCSourceFile("main.c", &[0][]const u8{});
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibraryWeak("a");
    exe.addLibraryPath(b.pathFromRoot("zig-out/lib"));
    exe.addRPath(b.pathFromRoot("zig-out/lib"));

    const check = exe.checkObject(.macho);
    check.checkStart("cmd LOAD_WEAK_DYLIB");
    check.checkNext("name @rpath/liba.dylib");

    check.checkInSymtab();
    check.checkNext("(undefined) weak external _a (from liba)");
    check.checkNext("(undefined) weak external _asStr (from liba)");

    test_step.dependOn(&check.step);

    const run_cmd = exe.run();
    run_cmd.expectStdOutEqual("42 42");
    test_step.dependOn(&run_cmd.step);
}
