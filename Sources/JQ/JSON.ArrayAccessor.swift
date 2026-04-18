public import JSONAST

extension JSON {
    @frozen public struct ArrayAccessor: ~Copyable {
        @usableFromInline var state: ArrayAccess

        @inlinable init(state: ArrayAccess) {
            self.state = state
        }
    }
}
extension JSON.ArrayAccessor {
    @inlinable static func protected(_ key: JSON.PathComponent) -> Self {
        .init(state: .protected(key))
    }

    @inlinable static var writable: Self {
        .init(state: .writable)
    }

    @inlinable static func occupied(_ value: consuming [JSON.Node]) -> Self {
        .init(state: .occupied(value))
    }
}
extension JSON.ArrayAccessor {
    @discardableResult
    @inlinable public static func &? <E, T>(
        self: inout Self,
        yield: (inout [JSON.Node]) throws(E) -> T
    ) throws(E) -> T? {
        switch self.state {
        case .protected:
            return nil
        case .writable:
            return nil
        case .occupied(var values):
            self.state = .writable
            defer {
                self.state = .occupied(values)
            }
            return try yield(&values)
        }
    }

    @inlinable public static func &! (
        self: inout Self,
        yield: (inout [JSON.Node]?) throws -> ()
    ) throws {
        switch self.state {
        case .protected(let offender):
            var values: [JSON.Node]? = nil
            try yield(&values)
            if  values != nil {
                throw JSON.NodeAccessError.protected(offender)
            }
        case .writable:
            var values: [JSON.Node]? = []
            try yield(&values)
            if  let values: [JSON.Node] {
                self.state = .occupied(values)
            }
        case .occupied(let value):
            var values: [JSON.Node]? = consume value

            self.state = .writable
            defer {
                self.state = values.map { .occupied($0) } ?? .writable
            }
            try yield(&values)
        }
    }
}
