public import JSONAST

extension JSON {
    @frozen public struct NodeAccessor: ~Copyable {
        @usableFromInline let crumb: PathComponent?
        @usableFromInline var state: NodeAccess<Node>

        @inlinable init(crumb: PathComponent?, state: NodeAccess<Node>) {
            self.crumb = crumb
            self.state = state
        }
    }
}
extension JSON.NodeAccessor {
    @inlinable static func protected(_ crumb: JSON.PathComponent?) -> Self {
        .init(crumb: crumb, state: .protected)
    }

    @inlinable static func reserved(_ crumb: JSON.PathComponent?, _ index: Int) -> Self {
        .init(crumb: crumb, state: .reserved(index))
    }

    @inlinable static func writable(index: Int) -> Self {
        .init(crumb: .index(index), state: .writable)
    }

    @inlinable static func writable(field: JSON.Key) -> Self {
        .init(crumb: .field(field), state: .writable)
    }

    @inlinable static func occupied(index: Int, value: consuming JSON.Node) -> Self {
        .init(crumb: .index(index), state: .occupied(value))
    }

    @inlinable static func occupied(field: JSON.Key, value: consuming JSON.Node) -> Self {
        .init(crumb: .field(field), state: .occupied(value))
    }
}
extension JSON.NodeAccessor {
    @inlinable public subscript(field: JSON.Key) -> Self {
        _read {
            switch self.state {
            case .protected:
                yield self
            case .reserved:
                yield self
            case .writable:
                yield .writable(field: field)
            case .occupied(let node):
                yield node[field, in: self.crumb]
            }
        }
        _modify {
            switch self.state {
            case .protected:
                yield &self

            case .reserved:
                yield &self

            case .writable:
                defer {
                    // we are allowed to overwrite undefined with a single-field object
                    if  case .occupied(let node) = self.state {
                        self.state = .occupied(.object(JSON.Object.init([(field, node)])))
                    }
                }
                yield &self

            case .occupied(var node):
                self.state = .writable
                defer { self.state = .occupied(node) }
                yield &node[field, in: self.crumb]
            }
        }
    }
    @inlinable public subscript(index: Int) -> Self {
        _read {
            switch self.state {
            case .protected:
                yield self
            case .reserved:
                yield self
            case .writable:
                yield index < 0 ? .reserved(self.crumb, index) : .writable(index: index)
            case .occupied(let node):
                yield node[index, in: self.crumb]
            }
        }
        _modify {
            switch self.state {
            case .protected:
                yield &self

            case .reserved:
                yield &self

            case .writable:
                if  index < 0 {
                    var reserved: Self = .reserved(self.crumb, index)
                    yield &reserved
                } else {
                    defer {
                        // we are allowed to overwrite undefined with a vivified array
                        if  case .occupied(let node) = self.state {
                            self.state = .occupied(
                                .array(JSON.Array.init(value: node, at: index))
                            )
                        }
                    }
                    yield &self
                }

            case .occupied(var node):
                self.state = .writable
                defer { self.state = .occupied(node) }
                yield &node[index, in: self.crumb]
            }
        }
    }
    @inlinable public subscript() -> JSON.ArrayAccessor {
        _read {
            switch self.state {
            case .protected:
                yield .protected(self.crumb)
            case .reserved(let offender):
                yield .reserved(self.crumb, offender)
            case .writable:
                yield .writable
            case .occupied(let node):
                yield node[..., in: self.crumb]
            }
        }
        _modify {
            switch self.state {
            case .protected:
                var accessor: JSON.ArrayAccessor = .protected(self.crumb)
                yield &accessor

            case .reserved(let offender):
                var accessor: JSON.ArrayAccessor = .reserved(self.crumb, offender)
                yield &accessor

            case .writable:
                var accessor: JSON.ArrayAccessor = .writable
                defer {
                    // we are allowed to overwrite undefined with a vivified array
                    if  case .occupied(let array) = accessor.state {
                        self.state = .occupied(.array(array))
                    }
                }
                yield &accessor

            case .occupied(var node):
                self.state = .writable
                defer { self.state = .occupied(node) }
                yield &node[..., in: self.crumb]
            }
        }
    }
}
extension JSON.NodeAccessor {
    @inlinable public static func &= (
        self: inout Self,
        delete: Never?
    ) throws(JSON.NodeAccessError) {
        switch self.state {
        case .protected:
            throw .protected(self.crumb)
        case .reserved:
            break
        case .writable:
            break
        case .occupied:
            self.state = .writable
        }
    }
    @inlinable public static func &= (
        self: inout Self,
        value: consuming JSON.Node
    ) throws(JSON.NodeAccessError) {
        switch self.state {
        case .protected:
            throw .protected(self.crumb)
        case .reserved(let offender):
            throw .reserved(self.crumb, offender)
        case .writable:
            self.state = .occupied(value)
        case .occupied:
            self.state = .occupied(value)
        }
    }

    @discardableResult
    @inlinable public static func &? <E, T>(
        self: inout Self,
        yield: (inout JSON.Node) throws(E) -> T
    ) throws(E) -> T? {
        switch self.state {
        case .protected:
            return nil
        case .reserved:
            return nil
        case .writable:
            return nil
        case .occupied(var value):
            self.state = .writable
            defer {
                self.state = .occupied(value)
            }
            return try yield(&value)
        }
    }

    @inlinable public static func & (
        self: inout Self,
        yield: (inout JSON.Node?) throws -> ()
    ) throws {
        switch self.state {
        case .protected:
            var value: JSON.Node? = nil
            try yield(&value)
            if  value != nil {
                throw JSON.NodeAccessError.protected(self.crumb)
            }
        case .reserved(let offender):
            var value: JSON.Node? = nil
            try yield(&value)
            if  value != nil {
                throw JSON.NodeAccessError.reserved(self.crumb, offender)
            }
        case .writable:
            var value: JSON.Node? = nil
            try yield(&value)
            if  let value: JSON.Node {
                self.state = .occupied(value)
            }
        case .occupied(let value):
            var value: JSON.Node? = consume value

            self.state = .writable
            defer {
                self.state = value.map { .occupied($0) } ?? .writable
            }
            try yield(&value)
        }
    }

    @inlinable public static func |? <E, T>(
        self: borrowing Self,
        yield: (JSON.Node) throws(E) -> T
    ) throws(E) -> T? {
        if  case .occupied(let value) = self.state {
            return try yield(value)
        } else {
            return nil
        }
    }

    @inlinable public static func | <T>(
        self: borrowing Self,
        yield: (JSON.Node) throws -> T
    ) throws -> T {
        switch self.state {
        case .protected:
            throw JSON.NodeAccessError.protected(self.crumb)
        case .reserved(let offender):
            throw JSON.NodeAccessError.reserved(self.crumb, offender)
        case .writable:
            return try yield(.null)
        case .occupied(let value):
            return try yield(value)
        }
    }
}
