import JQ
import JSON
import Testing

@Suite struct AccessArrayTests {
    @Test static func Assign() throws {
        var node: JSON.Node = [false, true]
        try node[0] &= true

        #expect("\(node)" == "\([true, true] as JSON.Node)")

        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][1] &= false

        #expect("\(nested)" == "\(["a": [false, [false, false]]] as JSON.Node)")
    }
    @Test static func AssignReverse() throws {
        var node: JSON.Node = [false, true]
        try node[-1] &= false

        #expect("\(node)" == "\([false, false] as JSON.Node)")

        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][-2] &= true

        #expect("\(nested)" == "\(["a": [false, [true, true]]] as JSON.Node)")
    }
    @Test static func AssignDelete() throws {
        var node: JSON.Node = [false, true]
        try node[1] &= nil

        #expect("\(node)" == "\([false] as JSON.Node)")

        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][1] &= nil

        #expect("\(nested)" == "\(["a": [false, [false]]] as JSON.Node)")
    }
    @Test static func AssignDeleteInterior() throws {
        var node: JSON.Node = [false, true]
        try node[0] &= nil

        #expect("\(node)" == "\([true] as JSON.Node)")


        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][0] &= nil

        #expect("\(nested)" == "\(["a": [false, [true]]] as JSON.Node)")
    }
    @Test static func AssignDeleteNonexistent() throws {
        var node: JSON.Node = [false, true]
        try node[2] &= nil

        #expect("\(node)" == "\([false, true] as JSON.Node)")

        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][2] &= nil

        #expect("\(nested)" == "\(["a": [false, [false, true]]] as JSON.Node)")
    }
    @Test static func AssignDeleteNonexistentReverse() throws {
        var node: JSON.Node = [false, true]
        try node[-5] &= nil

        #expect("\(node)" == "\([false, true] as JSON.Node)")

        var nested: JSON.Node = ["a": [false, [false, true]]]
        try nested["a"][1][-5] &= nil

        #expect("\(nested)" == "\(["a": [false, [false, true]]] as JSON.Node)")
    }


    @Test static func AssignVivify() throws {
        var node: JSON.Node = []
        try node[0]["b"][1] &= true

        #expect("\(node)" == "\([["b": [.null, true]]] as JSON.Node)")
    }
    @Test static func AssignVivifyOverwriteNull() throws {
        var node: JSON.Node = .null
        try node[0] &= false

        #expect("\(node)" == "\([false] as JSON.Node)")

        var nested: JSON.Node = ["a": .null]
        try nested["a"][0] &= false

        #expect("\(nested)" == "\(["a": [false]] as JSON.Node)")
    }
    @Test static func AssignProtected() {
        #expect(throws: JSON.NodeAccessError.protected(nil)) {
            var node: JSON.Node = [:]
            try node[0] &= true
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("x"))) {
            var node: JSON.Node = ["x": [:]]
            try node["x"][0] &= true
        }
    }
    @Test static func AssignProtectedReverse() {
        #expect(throws: JSON.NodeAccessError.protected(nil)) {
            var node: JSON.Node = [:]
            try node[-1] &= true
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("x"))) {
            var node: JSON.Node = ["x": [:]]
            try node["x"][-1] &= true
        }
        #expect(throws: JSON.NodeAccessError.protected(.field("y"))) {
            var node: JSON.Node = ["x": ["y": [:]]]
            try node["x"]["y"][-1] &= true
        }
    }
    @Test static func AssignReserved() {
        #expect(throws: JSON.NodeAccessError.reserved(nil, -1)) {
            var node: JSON.Node = []
            try node[-1] &= true
        }
        #expect(throws: JSON.NodeAccessError.reserved(.field("x"), -1)) {
            var node: JSON.Node = ["x": []]
            try node["x"][-1] &= true
        }
        #expect(throws: JSON.NodeAccessError.reserved(.field("y"), -1)) {
            var node: JSON.Node = ["x": ["y": []]]
            try node["x"]["y"][-1] &= true
        }
    }

    @Test static func Modify() throws {
        var node: JSON.Node = [[false, true]]
        try node[0] & {
            $0 = [true, false]
        }

        #expect("\(node)" == "\([[true, false]] as JSON.Node)")

        try node[] & {
            $0 = [true, true]
        }

        #expect("\(node)" == "\([true, true] as JSON.Node)")


        var nested: JSON.Node = [[[false, true], [true, false]]]
        try nested[0][1] & {
            $0 = .number(1)
        }

        #expect("\(nested)" == "\([[[false, true], .number(1)]] as JSON.Node)")

        try nested[0][] & {
            $0 = [true]
        }

        #expect("\(nested)" == "\([[true]] as JSON.Node)")
    }
    @Test static func ModifyDelete() throws {
        var node: JSON.Node = ["a": ["x": false, "y": true]]
        try node["a"]["y"] & {
            $0 = nil
        }

        #expect("\(node)" == "\(["a": ["x": false]] as JSON.Node)")
    }
    @Test static func ModifyNilToNil() throws {
        var node: JSON.Node = []
        try node[3][2][4] & {
            $0 = nil
        }

        #expect("\(node)" == "\([] as JSON.Node)")
    }
    @Test static func ModifyVivify() throws {
        var node: JSON.Node = []
        try node[2][1][1] & {
            $0 = true
        }

        #expect("\(node)" == "\([.null, .null, [.null, [.null, true]]] as JSON.Node)")
    }
    @Test static func ModifyVivifyOverwriteNull() throws {
        var node: JSON.Node = [.null]
        try node[0][0] & {
            $0 = false
        }

        #expect("\(node)" == "\([[false]] as JSON.Node)")
    }
    @Test static func ModifyProtected() {
        #expect(throws: JSON.NodeAccessError.protected(.field("x"))) {
            var node: JSON.Node = ["x": [:]]
            try node["x"][0] & {
                $0 = true
            }
        }
    }

    @Test static func UpdateProtected() {
        var node: JSON.Node = [:]
        #expect((node[1] &? { $0 = true }) == nil)
        #expect("\(node)" == "\([:] as JSON.Node)")

        var nested: JSON.Node = [[:]]
        #expect((nested[0][1] &? { $0 = true }) == nil)
        #expect("\(nested)" == "\([[:]] as JSON.Node)")
    }
    @Test static func UpdateFailure() {
        var node: JSON.Node = [true, false]
        #expect((node[2] &? { $0 = true }) == nil)
        #expect("\(node)" == "\([true, false] as JSON.Node)")

        var nested: JSON.Node = [[true, false]]
        #expect((nested[0][2] &? { $0 = true }) == nil)
        #expect("\(nested)" == "\([[true, false]] as JSON.Node)")
    }
    @Test static func UpdateFailureReverse() {
        var node: JSON.Node = [true, false]
        #expect((node[-3] &? { $0 = true }) == nil)
        #expect("\(node)" == "\([true, false] as JSON.Node)")

        var nested: JSON.Node = [[true, false]]
        #expect((nested[0][-3] &? { $0 = true }) == nil)
        #expect("\(nested)" == "\([[true, false]] as JSON.Node)")
    }
    @Test static func UpdateSuccess() {
        var node: JSON.Node = [true, false]
        #expect((node[1] &? { $0 = true }) != nil)
        #expect("\(node)" == "\([true, true] as JSON.Node)")

        var nested: JSON.Node = [[true, false]]
        #expect((nested[0][1] &? { $0 = true }) != nil)
        #expect("\(nested)" == "\([[true, true]] as JSON.Node)")
    }
    @Test static func UpdateSuccessReverse() {
        var node: JSON.Node = [true, false]
        #expect((node[-1] &? { $0 = true }) != nil)
        #expect("\(node)" == "\([true, true] as JSON.Node)")

        var nested: JSON.Node = [[true, false]]
        #expect((nested[0][-1] &? { $0 = true }) != nil)
        #expect("\(nested)" == "\([[true, true]] as JSON.Node)")
    }

    @Test static func Pipe() throws {
        let node: JSON.Node = [true, false]
        #expect(try ["true", "false"] == node[] | { "\($0)" })

        let nested: JSON.Node = [[true, false]]
        #expect(try ["true", "false"] == nested[0][] | { "\($0)" })
    }
    @Test static func PipeSuccess() throws {
        let node: JSON.Node = [true, false]
        #expect(["true", "false"] == (node[] |? { "\($0)" }))

        let nested: JSON.Node = [[true, false]]
        #expect(["true", "false"] == (nested[0][] |? { "\($0)" }))
    }
    @Test static func PipeFailure() throws {
        let node: JSON.Node = [:]
        #expect(nil == (node[] |? { "\($0)" }))

        let nested: JSON.Node = [[:]]
        #expect(nil == (nested[0][] |? { "\($0)" }))
    }

    @Test static func Append() throws {
        var node: JSON.Node = .null
        try node[] &! { $0.elements.append("x") }
        #expect("\(node)" == "\(["x"] as JSON.Node)")

        var nested: JSON.Node = [:]
        try nested["a"][] &! { $0.elements.append("x") }
        #expect("\(nested)" == "\(["a": ["x"]] as JSON.Node)")
    }
}
