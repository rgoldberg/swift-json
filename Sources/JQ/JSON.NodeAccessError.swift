public import JSONAST

extension JSON {
    @frozen public enum NodeAccessError: Error, Equatable {
        case protected
        case reserved
    }
}
extension JSON.NodeAccessError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .protected:
            return "cannot write to protected json node"
        case .reserved:
            return "cannot write to reserved json node"
        }
    }
}
