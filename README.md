# computils

Zig utilities for all your comptime needs.

## Utilities

### `ComptimeArrayList`

**Example:**
```zig
// Simply replace your ArrayList(T).init(allocator) with ComptimeArrayList(T).init()
// and use `comptime` on all operations

comptime {
    var list = ComptimeArrayList(u8).init();
    list.append('a');
}
```

## License

MIT
