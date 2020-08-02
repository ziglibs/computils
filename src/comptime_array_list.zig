const std = @import("std");
const testing = std.testing;

/// All subfunctions have to be run as `comptime` or in `comptime` blocks.
pub fn ComptimeArrayList(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,

        pub fn init() Self {
            comptime var initial = [_]T{};
            return Self{
                .items = &initial
            };
        }

        pub fn append(self: *Self, comptime item: T) void {
            var new_items: [self.items.len + 1]T = undefined;

            std.mem.copy(T, &new_items, self.items);
            new_items[self.items.len] = item;

            self.items = &new_items;
        }

        pub fn appendSlice(self: *Self, comptime items: []T) void {
            var new_items: [self.items.len + items.len]T = undefined;

            std.mem.copy(T, &new_items, self.items);
            var i: usize = 0;
            while (i < items.len) : (i += 1)
                new_items[self.items.len + i] = items[i];

            self.items = &new_items;
        }

        pub fn deinit(self: *Self) void {
            var new_items: [0]T = undefined;
            self.items = &new_items;
        }

        pub fn toOwnedSlice(self: *Self) []T {
            defer self.deinit();
            return self.items;
        }

        pub fn orderedRemove(self: *Self, comptime index: usize) void {
            var new_items: [self.items.len - 1]T = undefined;

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

        /// Adjusts the list's length to `new_len`.
        /// On "upsizing", elements that were previously "downsized" and left
        /// out of the resize will become undefined
        pub fn resize(self: *Self, comptime new_len: usize) void {
            if (new_len > self.items.len) {
                var new_items: [new_len]T = undefined;
                std.mem.copy(u8, &new_items, self.items);
                self.items = &new_items;
            } else {
                self.items.len = new_len;
            }
        }
        
        /// Shrinks the list's length to `new_len`.
        /// This will make elements "left out" of the resize "disappear".
        pub fn shrink(self: *Self, comptime new_len: usize) void {
            std.debug.assert(new_len <= self.items.len);

            var new_items: [new_len]T = undefined;

            var i: usize = 0;
            while (i < new_len) : (i += 1) {
                new_items[i] = self.items[i];
            }
            
            self.items = &new_items;
        }

        /// Caller must free memory.
        pub fn toRuntime(self: *Self, allocator: *std.mem.Allocator) !std.ArrayList(T) {
            var arr = std.ArrayList(T).init(allocator);
            try arr.appendSlice(self.items);
            return arr;
        }
    };
}

test "ComptimeArrayList.append / ComptimeArrayList.appendSlice" {
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
        std.testing.expectEqual(list.items.len, 0);
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

        list.orderedRemove(1);
        list.orderedRemove(3);
        list.orderedRemove(1);

        var expected = [_]u8{'a', 'd'};

        std.testing.expectEqualSlices(u8, &expected, list.toOwnedSlice());
    }
}

test "ComptimeArrayList.resize" {
    comptime {
        var list = ComptimeArrayList(u8).init();

        list.append('a');
        list.append('b');
        list.append('c');
        list.append('d');

        list.resize(2);

        std.testing.expectEqual(2, list.items.len);
    }
}

test "ComptimeArrayList.shrink" {
    comptime {
        var list = ComptimeArrayList(u8).init();

        list.append('a');
        list.append('b');
        list.append('c');
        list.append('d');

        list.shrink(2);

        std.testing.expectEqual(2, list.items.len);
    }
}

test "ComptimeArrayList.toRuntime" {
    comptime var list = ComptimeArrayList(u8).init();

    comptime {
        list.append('a');
        list.append('b');
        list.append('c');
        list.append('d');
    }

    var array_list = try list.toRuntime(std.testing.allocator);
    defer array_list.deinit();

    var expected = [_]u8{'a', 'b', 'c', 'd'};
    std.testing.expectEqualSlices(u8, &expected, array_list.items);
}
