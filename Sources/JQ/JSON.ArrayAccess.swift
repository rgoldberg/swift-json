public import JSONAST

extension JSON {
    @frozen @usableFromInline enum ArrayAccess {
        case protected(PathComponent)
        case writable
        case occupied([Node])
    }
}
