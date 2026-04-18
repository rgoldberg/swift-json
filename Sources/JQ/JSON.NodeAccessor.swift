public import JSONAST

extension JSON {
    @frozen public struct NodeAccessor: ~Copyable {
        @usableFromInline var state: NodeAccess

        @inlinable init(state: NodeAccess) {
            self.state = state
        }
    }
}
extension JSON.NodeAccessor {
    @inlinable static func protected(_ key: JSON.NodeAccess.PathComponent) -> Self {
        .init(state: .protected(key))
    }

    @inlinable static func reserved(_ index: Int) -> Self {
        .init(state: .reserved(index))
    }

    @inlinable static var writable: Self {
        .init(state: .writable)
    }

    @inlinable static func occupied(_ value: consuming JSON.Node) -> Self {
        .init(state: .occupied(value))
    }
}
extension JSON.NodeAccessor {
    @inlinable public subscript(index: Int) -> Self {
        get {
            switch self.state {
            case .protected(let offender):
                return .protected(offender)
            case .reserved(let offender):
                return .reserved(offender)
            case .writable:
                return index < 0 ? .reserved(index) : .writable
            case .occupied(let node):
                return node[index]
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
                    var reserved: Self = .reserved(index)
                    yield &reserved
                } else {
                    defer {
                        // we are allowed to overwrite undefined with a vivified array
                        if  case .occupied(let node) = self.state {
                            self = .occupied(.array(JSON.Array.init(value: node, at: index)))
                        }
                    }
                    yield &self
                }

            case .occupied(var node):
                self.state = .writable
                defer { self = .occupied(node) }
                yield &node[index]
            }
        }
    }
    @inlinable public subscript(key: JSON.Key) -> Self {
        get {
            switch self.state {
            case .protected(let offender):
                return .protected(offender)
            case .reserved(let offender):
                return .reserved(offender)
            case .writable:
                return .writable
            case .occupied(let node):
                return node[key]
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
                        self = .occupied(.object(JSON.Object.init([(key, node)])))
                    }
                }
                yield &self

            case .occupied(var node):
                self.state = .writable
                defer { self = .occupied(node) }
                yield &node[key]
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
            throw .protected
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
            throw .protected
        case .reserved:
            throw .reserved
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

    @inlinable public static func &! (
        self: inout Self,
        yield: (inout JSON.Node?) throws -> ()
    ) throws {
        switch self.state {
        case .protected:
            var value: JSON.Node? = nil
            try yield(&value)
            if  value != nil {
                throw JSON.NodeAccessError.protected
            }
        case .reserved:
            var value: JSON.Node? = nil
            try yield(&value)
            if  value != nil {
                throw JSON.NodeAccessError.reserved
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
}
