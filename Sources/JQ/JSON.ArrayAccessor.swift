public import JSONAST

extension JSON {
    @frozen public struct ArrayAccessor: ~Copyable {
        @usableFromInline let crumb: PathComponent?
        @usableFromInline var state: NodeAccess<Array>

        @inlinable init(crumb: PathComponent?, state: NodeAccess<Array>) {
            self.crumb = crumb
            self.state = state
        }
    }
}
extension JSON.ArrayAccessor {
    @inlinable static func protected(_ crumb: JSON.PathComponent?) -> Self {
        .init(crumb: crumb, state: .protected)
    }

    @inlinable static func reserved(_ crumb: JSON.PathComponent?, _ index: Int) -> Self {
        .init(crumb: crumb, state: .reserved(index))
    }

    @inlinable static var writable: Self {
        .init(crumb: nil, state: .writable)
    }

    @inlinable static func occupied(_ value: consuming JSON.Array) -> Self {
        .init(crumb: nil, state: .occupied(value))
    }
}
extension JSON.ArrayAccessor {
    /// Modify an existing array at the accessed path, returning nil if no such array exists, or
    /// if the accessed path is invalid.
    @discardableResult
    @inlinable public static func &? <E, T>(
        self: inout Self,
        yield: (inout JSON.Array) throws(E) -> T
    ) throws(E) -> T? {
        if case .occupied(var array) = self.state {
            self.state = .writable
            defer {
                self.state = .occupied(array)
            }
            return try yield(&array)
        } else {
            return nil
        }
    }

    /// Modify the array at the accessed path, creating an empty array in the tree if it does
    /// not exist.
    ///
    /// Use this when you are confident that the array must be written, and expect to receive
    /// an error if incompatible data already exists in the accessed location.
    @inlinable public static func &! (
        self: inout Self,
        yield: (inout JSON.Array) throws -> ()
    ) throws {
        switch self.state {
        case .protected:
            throw JSON.NodeAccessError.protected(self.crumb)

        case .reserved(let offender):
            throw JSON.NodeAccessError.reserved(self.crumb, offender)

        case .writable:
            var array: JSON.Array = []
            try yield(&array)
            self.state = .occupied(array)

        case .occupied(let value):
            var array: JSON.Array = consume value
            self.state = .writable
            defer {
                self.state = .occupied(array)
            }
            try yield(&array)
        }
    }

    /// Modify the array at the accessed path, allowing the closure to create, update, or delete
    /// it. Assigning a value to a node that was originally nil creates it, likewise,
    /// assigning nil to a node that was originally non-nil deletes it.
    ///
    /// If the accessed path is not writable, and the node is assigned a value in the
    /// closure — even an empty array — a ``NodeAccessError`` is thrown.
    @inlinable public static func & (
        self: inout Self,
        yield: (inout JSON.Array?) throws -> ()
    ) throws {
        switch self.state {
        case .protected:
            var array: JSON.Array? = nil
            try yield(&array)
            if  array != nil {
                throw JSON.NodeAccessError.protected(self.crumb)
            }

        case .reserved(let offender):
            var array: JSON.Array? = nil
            try yield(&array)
            if  array != nil {
                throw JSON.NodeAccessError.reserved(self.crumb, offender)
            }

        case .writable:
            var array: JSON.Array? = nil
            try yield(&array)
            if  let array: JSON.Array {
                self.state = .occupied(array)
            }

        case .occupied(let value):
            var array: JSON.Array? = consume value

            self.state = .writable
            defer {
                self.state = array.map { .occupied($0) } ?? .writable
            }
            try yield(&array)
        }
    }

    @inlinable public static func |? <E, T>(
        self: borrowing Self,
        yield: (JSON.Node) throws(E) -> T
    ) throws(E) -> [T]? {
        if  case .occupied(let array) = self.state {
            return try array.elements.map(yield)
        } else {
            return nil
        }
    }

    @inlinable public static func | <T>(
        self: borrowing Self,
        yield: (JSON.Node) throws -> T
    ) throws -> [T]? {
        switch self.state {
        case .protected:
            throw JSON.NodeAccessError.protected(self.crumb)
        case .reserved(let offender):
            throw JSON.NodeAccessError.reserved(self.crumb, offender)
        case .writable:
            return nil
        case .occupied(let array):
            return try array.elements.map(yield)
        }
    }
}
