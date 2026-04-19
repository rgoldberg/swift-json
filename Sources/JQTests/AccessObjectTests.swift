import JQ
import JSON
import Testing

@Suite struct AccessObjectTests {
    @Test static func Assign() throws {
        var node: JSON.Node = ["x": [false, true]]
        try node["x"] &= true

        #expect("\(node)" == "\(["x": true] as JSON.Node)")

        var nested: JSON.Node = ["a": ["x": false, "y": true]]
        try nested["a"]["y"] &= false

        #expect("\(nested)" == "\(["a": ["x": false, "y": false]] as JSON.Node)")
    }
    @Test static func AssignDelete() throws {
        var node: JSON.Node = ["x": false, "y": true]
        try node["y"] &= nil

        #expect("\(node)" == "\(["x": false] as JSON.Node)")

        var nested: JSON.Node = ["a": ["x": false, "y": true]]
        try nested["a"]["y"] &= nil

        #expect("\(nested)" == "\(["a": ["x": false]] as JSON.Node)")
    }
    @Test static func AssignDeleteNonexistent() throws {
        var node: JSON.Node = ["x": false, "y": true]
        try node["z"] &= nil

        #expect("\(node)" == "\(["x": false, "y": true] as JSON.Node)")

        var nested: JSON.Node = ["a": ["x": false, "y": true]]
        try nested["a"]["z"] &= nil

        #expect("\(nested)" == "\(["a": ["x": false, "y": true]] as JSON.Node)")
    }
    @Test static func AssignVivify() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] &= true

        #expect("\(node)" == "\(["a": ["b": ["c": true]]] as JSON.Node)")
    }
    @Test static func AssignVivifyOverwriteNull() throws {
        var node: JSON.Node = .null
        try node["y"] &= false

        #expect("\(node)" == "\(["y": false] as JSON.Node)")

        var nested: JSON.Node = ["a": .null]
        try nested["a"]["y"] &= false

        #expect("\(nested)" == "\(["a": ["y": false]] as JSON.Node)")
    }
    @Test static func AssignProtected() {
        #expect(throws: JSON.NodeAccessError.protected(nil)) {
            var node: JSON.Node = []
            try node["y"] &= true
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("x"))) {
            var node: JSON.Node = ["x": []]
            try node["x"]["y"] &= true
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("y"))) {
            var node: JSON.Node = ["x": ["y": []]]
            try node["x"]["y"]["z"] &= true
        }
    }

    @Test static func Modify() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] & {
            $0 = .number(.init(1))
        }

        #expect("\(node)" == "\(["a": ["x": false, "y": .number(.init(1))]] as JSON.Node)")

        try node["a"] & {
            $0 = .number(.init(1))
        }

        #expect("\(node)" == "\(["a": .number(.init(1))] as JSON.Node)")

        try node["a"] & {
            $0 = [true, false]
        }

        #expect("\(node)" == "\(["a": [true, false]] as JSON.Node)")
    }
    @Test static func ModifyDelete() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] & {
            $0 = nil
        }

        #expect("\(node)" == "\(["a": ["x": false]] as JSON.Node)")

        try node["a"] & {
            $0 = nil
        }

        #expect("\(node)" == "\([:] as JSON.Node)")
    }
    @Test static func ModifyNilToNil() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] & {
            $0 = nil
        }

        #expect("\(node)" == "\([:] as JSON.Node)")
    }
    @Test static func ModifyVivify() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] & {
            $0 = true
        }

        #expect("\(node)" == "\(["a": ["b": ["c": true]]] as JSON.Node)")
    }
    @Test static func ModifyVivifyOverwriteNull() throws {
        var node: JSON.Node = .null
        try node["y"] & {
            $0 = false
        }

        #expect("\(node)" == "\(["y": false] as JSON.Node)")

        var nested: JSON.Node = ["a": .null]
        try nested["a"]["y"] & {
            $0 = false
        }

        #expect("\(nested)" == "\(["a": ["y": false]] as JSON.Node)")
    }
    @Test static func ModifyProtected() {
        #expect(throws: JSON.NodeAccessError.protected(nil)) {
            var node: JSON.Node = []
            try node["y"] & {
                $0 = true
            }
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("x"))) {
            var node: JSON.Node = ["x": []]
            try node["x"]["y"] & {
                $0 = true
            }
        }
    }

    @Test static func UpdateProtected() {
        var node: JSON.Node = []
        #expect((node["y"] &? { $0 = true }) == nil)
        #expect("\(node)" == "\([] as JSON.Node)")

        var nested: JSON.Node = ["x": []]
        #expect((nested["x"]["y"] &? { $0 = true }) == nil)
        #expect("\(nested)" == "\(["x": []] as JSON.Node)")
    }
    @Test static func UpdateFailure() {
        var node: JSON.Node = ["a": true]
        #expect((node["y"] &? { $0 = true }) == nil)
        #expect("\(node)" == "\(["a": true] as JSON.Node)")

        var nested: JSON.Node = ["x": ["a": true]]
        #expect((nested["x"]["y"] &? { $0 = true }) == nil)
        #expect("\(nested)" == "\(["x": ["a": true]] as JSON.Node)")
    }
    @Test static func UpdateSuccess() {
        var node: JSON.Node = ["a": true]
        #expect((node["a"] &? { $0 = false }) != nil)
        #expect("\(node)" == "\(["a": false] as JSON.Node)")

        var nested: JSON.Node = ["x": ["a": true]]
        #expect((nested["x"]["a"] &? { $0 = false }) != nil)
        #expect("\(nested)" == "\(["x": ["a": false]] as JSON.Node)")
    }
}
