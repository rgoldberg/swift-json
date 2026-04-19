public import JSONAST

extension JSON {
    @frozen @usableFromInline enum NodeAccess<Value> {
        /// The accessor is bound to a node of an incompatible type, and writes will fail.
        case protected
        /// The accessor is bound to a node of a valid type for array vivification (an array or
        /// a `null` value), but the offset provided is invalid (points to a position before the
        /// first existing array element.)
        case reserved(Int)
        /// The accessor is bound to a missing or `null` node.
        case writable
        /// The accessor is bound to an existing node.
        case occupied(Value)
    }
}
