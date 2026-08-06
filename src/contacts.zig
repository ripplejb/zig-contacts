const std = @import("std");
const Io = std.Io;

const Contact = struct {
    name: []u8,
    email: []u8,
    phone: []u8,

    pub fn deinit(self: Contact, allocator: std.mem.Allocator) void {
        allocator.free(self.phone);
        allocator.free(self.email);
        allocator.free(self.name);
    }
};

pub const ContactBook = struct {
    allocator: std.mem.Allocator,
    contacts: std.ArrayList(Contact),

    pub fn init(allocator: std.mem.Allocator) ContactBook {
        return .{
            .allocator = allocator,
            .contacts = std.ArrayList(Contact).empty,
        };
    }

    pub fn deinit(self: *ContactBook) void {
        for (self.contacts.items) |contact| {
            contact.deinit(self.allocator);
        }
        self.contacts.deinit(self.allocator);
    }

    pub fn getContactCount(self: *ContactBook) usize {
        return self.contacts.items.len;
    }

    pub fn createContact(self: *ContactBook, name: []const u8, email: []const u8, phone: []const u8) !void {
        const heap_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(heap_name);
        const heap_email = try self.allocator.dupe(u8, email);
        errdefer self.allocator.free(heap_email);
        const heap_phone = try self.allocator.dupe(u8, phone);
        errdefer self.allocator.free(heap_phone);

        const new_contact = Contact{
            .name = heap_name,
            .email = heap_email,
            .phone = heap_phone,
        };

        try self.contacts.append(self.allocator, new_contact);
    }

    pub fn removeContact(self: *ContactBook, phone: []const u8) void {
        for (self.contacts.items, 0..) |item, index| {
            if (std.mem.eql(u8, item.phone, phone)) {
                _ = self.contacts.swapRemove(index);
                return;
            }
        }
    }
};

test "Test ContactBook" {
    const allcator = std.testing.allocator;
    var contacts = ContactBook.init(allcator);
    defer contacts.deinit();

    const zcnt = contacts.getContactCount();
    try std.testing.expectEqual(@as(usize, 0), zcnt);

    try contacts.createContact("Ripal", "asdf@ght.com", "1223456789");

    const ocnt = contacts.getContactCount();
    try std.testing.expectEqual(@as(usize, 1), ocnt);

    // remove wrong phone number
    contacts.removeContact("1111111111");

    const wcnt = contacts.getContactCount();
    try std.testing.expectEqual(@as(usize, 1), wcnt);

    // remove Correct phone number
    contacts.removeContact("123456789");

    const ccnt = contacts.getContactCount();
    try std.testing.expectEqual(@as(usize, 1), ccnt);
}
