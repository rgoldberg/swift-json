public import JSONAST

extension JSON {
    @frozen @usableFromInline enum NodeAccess {
        case protected(Key)
        case writable
        case occupied(Node)
    }
}
