//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

const mfgErrors = Io.Writer.Error || std.mem.Allocator.Error;

pub fn myFirstGpa(gpaAllocator: std.mem.Allocator, writer: *Io.Writer) mfgErrors!void {
    const lstNames = gpaAllocator.alloc([32]u8, 20) catch |err| {
        try writer.print("ERROR allocating lstNames", .{});
        return err;
    };
    defer gpaAllocator.free(lstNames);

    for (lstNames, 0..) |*name, i| {
        _ = std.fmt.bufPrint(&name.*, "Test {}", .{i}) catch {
            try writer.print("ERROR setting a name {}", .{i});
        };
    }

    try writer.print("Names\n", .{});
    try writer.print("=====\n", .{});

    for (lstNames, 0..) |name, i| {
        var len: u16 = undefined;
        if (i < 10) {
            len = 6;
        } else {
            len = 7;
        }
        const cleanName = name[0..len];
        try writer.print("{s}\n", .{cleanName});
    }

    try writer.flush(); // Don't forget to flush!

}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
