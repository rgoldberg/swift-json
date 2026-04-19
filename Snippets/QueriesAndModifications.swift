import JSON
import JQ

let string: String = """
{"id": 1, "scores": []}
"""

var root: JSON.Node = try .init(parsing: string)
try root["name"] &= "Barbara"
try root["scores"][0] &= .number(5)
print("\(root)")

do {
    try root["scores"]["banana"] &= true
} catch let error {
    print(error)
}

if  let score: JSON.Node = try root["scores"][0].node {
    print("read back score: \(score)")
}


try root["profile"]["address"]["city"] &= "Malibu"

print("\(root)")

try root["profile"]["address"]["city"] &= nil

print("\(root)")

try root["profile"] &= nil

print("\(root)")

/// this only creates the wrapper objects if the node is assigned a non-nil value
try root["profile"]["address"]["city"] & {
    if  Bool.random() {
        $0 = .string("Tehran")
    }
}

/// this only calls the closure if the node already exists
root["profile"]["address"]["city"] &? {
    if  case .string(let string) = $0 {
        $0 = .string(string.value.uppercased())
    }
}
print("\(root)")

/// this initializes the node with a default value (of `null`)
/// if it does not already exist
try root["x"]["y"]["z"] &! {
    if  Bool.random() {
        $0 = true
    }
}
print("\(root)")

try root["x"] &= nil
try root["name"] &= nil
try root["profile"] &= nil

try root["scores"][] & {
    $0?.elements.append(.number(8))
}

print("\(root)")

/// this initializes the field to an empty array if it does not already exist
try root["friends"][] &! {
    $0.elements.append("Paris")
}

print("\(root)")

let scores: [Int]? = try root["scores"][] | { try Int.init(json: $0) }
print(scores ?? [])

/// this adds 1 to each score in the 'scores' array
try root["scores"][] &! {
    for i: Int in $0.indices {
        let score: Int = try $0[i].decode()
        $0.elements[i] = .number(score + 1)
    }
}

print("\(root)")
