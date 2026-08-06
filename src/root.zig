//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const contacts = @import("contacts.zig");

test {
    std.testing.refAllDecls(@This());
}

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
    const lstNames = gpaAllocator.alloc([]u8, 20) catch |err| {
        try writer.print("ERROR allocating lstNames", .{});
        return err;
    };
    defer {
        for (lstNames) |name| {
            gpaAllocator.free(name);
        }
        gpaAllocator.free(lstNames);
    }

    for (lstNames, 0..) |*name, i| {
        name.* = try std.fmt.allocPrint(gpaAllocator, "Test {}", .{i});
    }

    try writer.print("Names\n", .{});
    try writer.print("=====\n", .{});

    for (lstNames) |name| {
        try writer.print("{s}\n", .{name});
    }

    try writer.flush(); // Don't forget to flush!

}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

test "my first gpaAllocator" {

    // Use the test allocator for the input
    const gpa = std.testing.allocator;

    // Create a list to catch the output
    var list = try std.ArrayList(u8).initCapacity(gpa, 1024);
    defer list.deinit(gpa);

    var stdout_file_writer = Io.Writer.fromArrayList(&list);

    try myFirstGpa(gpa, &stdout_file_writer);

    list = stdout_file_writer.toArrayList();

    try std.testing.expectStringStartsWith(list.items, "Names");
}
