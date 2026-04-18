public import JSONAST

extension JSON {
    @frozen @usableFromInline enum NodeAccess {
        case protected
        case reserved(Int)
        case writable
        case occupied(Node)
    }
}
