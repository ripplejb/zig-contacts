const std = @import("std");
const Io = std.Io;

const contacts = @import("contacts_mod");

const MenuItem = enum { @"1", @"2", @"3", @"4", @"5", @"6" };

pub fn main(init: std.process.Init) !void {

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stdin_buffer: [100]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;
    const allocator = std.heap.smp_allocator;
    var contectBook: contacts.ContactBook = .init(allocator);
    defer contectBook.deinit();

    var input_buf: [100]u8 = undefined;

    while (true) {
        try writeMenu(stdout_writer);
        const input = try inputReader("Type something here and press enter: ", &input_buf, stdout_writer, stdin_reader);
        try stdout_writer.print("\n{s} is your input.\n", .{input});
        try stdout_writer.flush();

        const selection = std.meta.stringToEnum(MenuItem, input) orelse {
            try stdout_writer.print("Invalid Input\n", .{});
            try stdout_writer.flush();
            continue;
        };

        switch (selection) {
            .@"1" => try AddContact(&contectBook, stdout_writer, stdin_reader),
            .@"2" => try contectBook.listAll(stdout_writer),
            .@"3" => try searchContact(&contectBook, stdout_writer, stdin_reader),
            .@"4" => try removeContact(&contectBook, stdout_writer, stdin_reader),
            .@"5" => break,
            else => {},
        }
    }
}

pub fn writeMenu(writer: *Io.Writer) !void {
    try writer.print("\n", .{});
    try writer.print("Select your option:\n", .{});
    try writer.print("======================\n", .{});
    try writer.print("[1] New Contact\n", .{});
    try writer.print("[2] List Contacts\n", .{});
    try writer.print("[3] Search Contacts\n", .{});
    try writer.print("[4] Delete Contact\n", .{});
    try writer.print("[5] Exit\n", .{});
    try writer.flush();
}

pub fn inputReader(prompt: []const u8, buf: []u8, writer: *Io.Writer, reader: *Io.Reader) ![]const u8 {
    try writer.print("{s} ", .{prompt});
    try writer.flush();

    const input = (try reader.takeDelimiter('\n')) orelse return error.EndOfStream;
    const clean = std.mem.trimEnd(u8, input, "\r");
    @memcpy(buf[0..clean.len], clean);
    return buf[0..clean.len];
}

pub fn AddContact(contactBook: *contacts.ContactBook, writer: *Io.Writer, reader: *Io.Reader) !void {
    try writer.print("\n", .{});
    var name_buf: [100]u8 = undefined;
    var email_buf: [100]u8 = undefined;
    var phone_buf: [100]u8 = undefined;

    const name = try inputReader("Name ==>", &name_buf, writer, reader);
    const email = try inputReader("email ==>", &email_buf, writer, reader);
    const phone = try inputReader("Phone ==>", &phone_buf, writer, reader);

    try contactBook.createContact(name, email, phone);
}

pub fn removeContact(contactBook: *contacts.ContactBook, writer: *Io.Writer, reader: *Io.Reader) !void {
    try writer.print("\n", .{});
    var phone_buf: [100]u8 = undefined;

    const phone = try inputReader("Phone to remove ==>", &phone_buf, writer, reader);

    contactBook.removeContact(phone) catch {
        try writer.print("Contact with phone# {s} not found,", .{phone});
        return;
    };
    try writer.print("Contact with phone# {s} is removed successfully.", .{phone});
}

pub fn searchContact(contactBook: *contacts.ContactBook, writer: *Io.Writer, reader: *Io.Reader) !void {
    try writer.print("\n", .{});
    var name_buf: [100]u8 = undefined;

    const name = try inputReader("Name to search ==> ", &name_buf, writer, reader);

    const contact = contactBook.searchByName(name) catch {
        try writer.print("Name {s} not found.", .{name});
        return;
    };
    try writer.print("Name: {s}, Email: {s}, Phone: {s}\n", .{ contact.name, contact.email, contact.phone });
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
