public import JSONAST

extension JSON {
    @frozen @usableFromInline enum ArrayAccess {
        case protected
        case writable
        case occupied([Node])
    }
}
