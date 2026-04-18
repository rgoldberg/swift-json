public import JSONAST

extension JSON.Node {
    @inlinable public subscript(key: JSON.Key) -> JSON.NodeAccessor {
        get {
            let object: JSON.Object
            switch self {
            case .object(let self):
                object = self
            case .null:
                return .writable
            default:
                return .protected(key)
            }

            let exists: Int? = object.fields.indices.first {
                object.fields[$0].key == key
            }
            if  let exists: Int {
                return .occupied(object.fields[exists].value)
            } else {
                return .writable
            }
        }
        _modify {
            var accessor: JSON.NodeAccessor

            var object: JSON.Object
            let exists: Int?
            switch consume self {
            case .object(let self):
                object = consume self
                exists = object.fields.indices.first {
                    object.fields[$0].key == key
                }

            case .null:
                object = JSON.Object.init()
                exists = nil

            case let other:
                self = other
                accessor = .protected(key)
                yield &accessor
                return
            }

            defer {
                self = .object(object)
            }

            if  let exists: Int {
                accessor = .occupied(object.fields[exists].value)
                object.fields[exists].value = .null

                defer {
                    if  case .occupied(let value) = accessor.state {
                        object.fields[exists].value = value
                    } else {
                        object.fields.remove(at: exists)
                    }
                }

                yield &accessor
            } else {
                accessor = .writable

                defer {
                    if  case .occupied(let value) = accessor.state {
                        object.fields.append((key, value))
                    }
                }

                yield &accessor
            }
        }
    }
}
