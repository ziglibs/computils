const std = @import("std");
const testing = std.testing;

/// All subfunctions have to be run as `comptime` or in `comptime` blocks.
pub fn ComptimeArrayList(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        capacity: usize,

        pub fn init() Self {
            comptime var initial = [_]T{};
            return Self{
                .items = &initial,
                .capacity = 0
            };
        }

        pub fn append(self: *Self, comptime item: T) void {
            self.capacity += 1;
            var new_items: [self.capacity]T = undefined;

            std.mem.copy(T, &new_items, self.items);
            new_items[self.capacity - 1] = item;

            self.items = &new_items;
        }

        pub fn appendSlice(self: *Self, comptime items: []T) void {
            self.capacity += items.len;
            var new_items: [self.capacity]T = undefined;

            std.mem.copy(T, &new_items, self.items);
            var i: usize = 0;
            while (i < items.len) : (i += 1)
                new_items[self.capacity - items.len + i] = items[i];

            self.items = &new_items;
        }

        pub fn deinit(self: *Self) void {
            self.capacity = 0;
            var new_items: [0]T = undefined;
            self.items = &new_items;
        }

        pub fn toOwnedSlice(self: *Self) []T {
            defer self.deinit();
            return self.items;
        }

        pub fn remove(self: *Self, comptime index: usize) void {
            self.capacity -= 1;
            var new_items: [self.capacity]T = undefined;

            var i: usize = 0;
            while (i < self.items.len) : (i += 1) {
                if (i == index) {
                    continue;
                } else if (i > index) {
                    new_items[i - 1] = self.items[i];
                } else {
                    new_items[i] = self.items[i];
                }
            }

            self.items = &new_items;
        }
    };
}

test "ComptimeArrayList.append, ComptimeArrayList.appendSlice" {
    comptime {
        var list = ComptimeArrayList(u8).init();
        
        list.append('a');
        list.append('b');
        var arr = [_]u8{'c', 'd'};
        list.appendSlice(&arr);

        var expected = [_]u8{'a', 'b', 'c', 'd'};
        var expected_empty = [_]u8{};

        std.testing.expectEqualSlices(u8, &expected, list.items);
        std.testing.expectEqualSlices(u8, &expected, list.toOwnedSlice());
        std.testing.expectEqual(list.capacity, 0);
        std.testing.expectEqualSlices(u8, &expected_empty, list.items);
    }
}

test "ComptimeArrayList.remove" {
    comptime {
        var list = ComptimeArrayList(u8).init();

        list.append('a');
        list.append('b');
        list.append('c');
        list.append('d');
        list.append('e');

        list.remove(1);
        list.remove(3);
        list.remove(1);

        var expected = [_]u8{'a', 'd'};

        std.testing.expectEqualSlices(u8, &expected, list.toOwnedSlice());
    }
}
