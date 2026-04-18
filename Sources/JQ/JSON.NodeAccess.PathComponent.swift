public import JSONAST

extension JSON.NodeAccess {
    @frozen @usableFromInline enum PathComponent {
        case field(JSON.Key)
        case index(Int)
    }
}
