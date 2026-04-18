import JQ
import JSON
import Testing

@Suite struct JQTests {
    private var node: JSON.Node

    init() {
        self.node = [
            "a": [
                "x": .number(.init(1)),
                "y": .number(.init(2)),
            ],
            "b": [
                false,
                true,
            ],
            "c": .null
        ]
    }

    @Test static func Assign() throws {
        var node: JSON.Node = ["x": [false, true]]
        try node["x"] &= true

        #expect("\(node)" == "\(["x": true] as JSON.Node)")
    }
    @Test static func AssignNested() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] &= false

        #expect("\(node)" == "\(["a": ["x": false, "y": false]] as JSON.Node)")
    }
    @Test static func AssignDelete() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] &= nil

        #expect("\(node)" == "\(["a": ["x": false]] as JSON.Node)")
    }
    @Test static func AssignVivify() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] &= true

        #expect("\(node)" == "\(["a": ["b": ["c": true]]] as JSON.Node)")
    }
    @Test static func AssignVivifyOverwriteNull() throws {
        var node: JSON.Node = ["a": .null]
        try node["a"]["y"] &= false

        #expect("\(node)" == "\(["a": ["y": false]] as JSON.Node)")
    }
    @Test static func AssignProtected() {
        #expect(throws: JSON.NodeAccessError.protected) {
            var node: JSON.Node = ["x": []]
            try node["x"]["y"] &= true
        }
    }

    @Test static func Modify() throws {
        var node: JSON.Node = ["x": [false, true]]
        try node["x"] &! {
            $0 = [true, false]
        }

        #expect("\(node)" == "\(["x": [true, false]] as JSON.Node)")
    }
    @Test static func ModifyNested() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] &! {
            $0 = .number(.init(1))
        }

        #expect("\(node)" == "\(["a": ["x": false, "y": .number(.init(1))]] as JSON.Node)")
    }
    @Test static func ModifyDelete() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] &! {
            $0 = nil
        }

        #expect("\(node)" == "\(["a": ["x": false]] as JSON.Node)")
    }
    @Test static func ModifyNilToNil() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] &! {
            $0 = nil
        }

        #expect("\(node)" == "\([:] as JSON.Node)")
    }
    @Test static func ModifyVivify() throws {
        var node: JSON.Node = [:]
        try node["a"]["b"]["c"] &! {
            $0 = true
        }

        #expect("\(node)" == "\(["a": ["b": ["c": true]]] as JSON.Node)")
    }
    @Test static func ModifyVivifyOverwriteNull() throws {
        var node: JSON.Node = ["a": .null]
        try node["a"]["y"] &! {
            $0 = false
        }

        #expect("\(node)" == "\(["a": ["y": false]] as JSON.Node)")
    }
    @Test static func ModifyProtected() {
        #expect(throws: JSON.NodeAccessError.protected) {
            var node: JSON.Node = ["x": []]
            try node["x"]["y"] &! {
                $0 = true
            }
        }
    }

    @Test static func UpdateProtected() {
        var node: JSON.Node = ["x": []]
        #expect((node["x"]["y"] &? { $0 = true }) == nil)
        #expect("\(node)" == "\(["x": []] as JSON.Node)")
    }
    @Test static func UpdateFailure() {
        var node: JSON.Node = ["x": ["a": true]]
        #expect((node["x"]["y"] &? { $0 = true }) == nil)
        #expect("\(node)" == "\(["x": ["a": true]] as JSON.Node)")
    }
    @Test static func UpdateSuccess() {
        var node: JSON.Node = ["x": ["a": true]]
        #expect((node["x"]["a"] &? { $0 = false }) != nil)
        #expect("\(node)" == "\(["x": ["a": false]] as JSON.Node)")
    }
}
