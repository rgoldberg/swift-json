public import JSONAST

extension JSON {
    @frozen @usableFromInline enum NodeAccess {
        case protected(PathComponent)
        case reserved(Int)
        case writable
        case occupied(Node)
    }
}
