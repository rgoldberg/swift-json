public import JSONAST

extension JSON {
    @frozen public enum PathComponent: Equatable, Sendable {
        case field(JSON.Key)
        case index(Int)
    }
}
extension JSON.PathComponent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .field(let field): "'\(field)'"
        case .index(let index): "[\(index)]"
        }
    }
}
