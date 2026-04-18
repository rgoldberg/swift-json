public import JSONAST

extension JSON.Node {
    @inlinable public subscript(field: JSON.Key) -> JSON.NodeAccessor {
        get {
            self[field, in: nil]
        }
        _modify {
            yield &self[field, in: nil]
        }
    }
    @inlinable public subscript(index: Int) -> JSON.NodeAccessor {
        get {
            self[index, in: nil]
        }
        _modify {
            yield &self[index, in: nil]
        }
    }
}
extension JSON.Node {
    @inlinable subscript(field: JSON.Key, in crumb: JSON.PathComponent?) -> JSON.NodeAccessor {
        get {
            let object: JSON.Object
            switch self {
            case .object(let self):
                object = self
            case .null:
                return .writable(field: field)
            default:
                return .protected(crumb)
            }

            let exists: Int? = object.fields.indices.first {
                object.fields[$0].key == field
            }
            if  let exists: Int {
                return .occupied(field: field, value: object.fields[exists].value)
            } else {
                return .writable(field: field)
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
                    object.fields[$0].key == field
                }

                if  let exists: Int {
                    accessor = .occupied(field: field, value: object.fields[exists].value)
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
                    accessor = .writable(field: field)

                    defer {
                        if  case .occupied(let value) = accessor.state {
                            object.fields.append((field, value))
                        }
                    }

                    yield &accessor
                }

            case .null:
                accessor = .writable(field: field)

                defer {
                    // we are allowed to overwrite null with a single-field object
                    if  case .occupied(let value) = accessor.state {
                        self = .object(JSON.Object.init([(field, value)]))
                    }
                }

                yield &accessor

            default:
                accessor = .protected(crumb)
                yield &accessor
            }
        }
    }
    @inlinable subscript(index: Int, in crumb: JSON.PathComponent?) -> JSON.NodeAccessor {
        get {
            let array: JSON.Array
            switch self {
            case .array(let self):
                array = self
            case .null:
                return index < 0 ? .reserved(crumb, index) : .writable(index: index)
            default:
                return .protected(crumb)
            }

            // normalize index
            let normalized: Int = index < 0 ? array.elements.endIndex + index : index
            if  normalized < 0 {
                return .reserved(crumb, index)
            } else if
                normalized < array.elements.endIndex {
                return .occupied(index: index, value: array.elements[normalized])
            } else {
                return .writable(index: index)
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
                    accessor = .reserved(crumb, index)
                    yield &accessor
                } else if
                    normalized < array.elements.endIndex {
                    accessor = .occupied(index: index, value: array.elements[normalized])
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
                    accessor = .writable(index: index)

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
                    accessor = .reserved(crumb, index)
                    yield &accessor
                } else {
                    accessor = .writable(index: index)

                    defer {
                        if  case .occupied(let value) = accessor.state {
                            self = .array(JSON.Array.init(value: value, at: index))
                        }
                    }

                    yield &accessor
                }
            default:
                accessor = .protected(crumb)
                yield &accessor
            }
        }
    }
}
