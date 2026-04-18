public import JSONAST

extension JSON.Node {
    @inlinable public subscript(index: Int) -> JSON.NodeAccessor {
        get {
            let array: JSON.Array
            switch self {
            case .array(let self):
                array = self
            case .null:
                return index < 0 ? .reserved(index) : .writable
            default:
                return .protected(.index(index))
            }

            // normalize index
            let normalized: Int = index < 0 ? array.elements.endIndex + index : index
            if  normalized < 0 {
                return .reserved(index)
            } else if
                normalized < array.elements.endIndex {
                return .occupied(array.elements[normalized])
            } else {
                return .writable
            }
        }
        _modify {
            var accessor: JSON.NodeAccessor

            switch self {
            case .array(var array):
                _ = consume self ; defer {
                    self = .array(array)
                }

                let normalized: Int = index < 0 ? array.elements.endIndex + index : index
                if  normalized < 0 {
                    accessor = .reserved(index)
                    yield &accessor
                } else if
                    normalized < array.elements.endIndex {
                    accessor = .occupied(array.elements[normalized])
                    array.elements[normalized] = .null

                    defer {
                        if  case .occupied(let value) = accessor.state {
                            array.elements[normalized] = value
                        } else {
                            array.elements.remove(at: normalized)
                        }
                    }

                    yield &accessor
                } else {
                    accessor = .writable

                    defer {
                        if  case .occupied(let value) = accessor.state {
                            let skip: Int = normalized - array.elements.endIndex
                            if  skip > 0 {
                                array.elements.reserveCapacity(1 + skip + array.elements.count)
                                array.elements += repeatElement(.null, count: skip)
                            }

                            array.elements.append(value)
                        }
                    }

                    yield &accessor
                }

            case .null:
                if  index < 0 {
                    accessor = .reserved(index)
                    yield &accessor
                } else {
                    accessor = .writable

                    defer {
                        if  case .occupied(let value) = accessor.state {
                            self = .array(JSON.Array.init(value: value, at: index))
                        }
                    }

                    yield &accessor
                }
            default:
                accessor = .protected(.index(index))
                yield &accessor
            }
        }
    }

    @inlinable public subscript(key: JSON.Key) -> JSON.NodeAccessor {
        get {
            let object: JSON.Object
            switch self {
            case .object(let self):
                object = self
            case .null:
                return .writable
            default:
                return .protected(.field(key))
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
            switch self {
            case .object(var object):
                _ = consume self ; defer {
                    self = .object(object)
                }

                let exists: Int? = object.fields.indices.first {
                    object.fields[$0].key == key
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

            case .null:
                accessor = .writable

                defer {
                    // we are allowed to overwrite null with a single-field object
                    if  case .occupied(let value) = accessor.state {
                        self = .object(JSON.Object.init([(key, value)]))
                    }
                }

                yield &accessor

            default:
                accessor = .protected(.field(key))
                yield &accessor
            }
        }
    }
}
