public import JSONAST

extension JSON {
    @frozen public enum NodeAccessError: Error, Equatable {
        case protected(PathComponent?)
        case reserved(PathComponent?, Int)
    }
}
extension JSON.NodeAccessError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .protected(let crumb?):
            return "cannot write to protected json node \(crumb)"
        case .protected:
            return "cannot write to protected json node"
        case .reserved(let crumb?, let index):
            return "cannot write to reserved offset [\(index)] in json node \(crumb)"
        case .reserved(nil, let index):
            return "cannot write to reserved offset [\(index)] in json node"
        }
    }
}
