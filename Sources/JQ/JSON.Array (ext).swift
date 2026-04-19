public import JSONAST

extension JSON.Array {
    @inlinable init(value: JSON.Node, at index: Int) {
        var values: [JSON.Node]
        if  index > 0 {
            values = []
            values.reserveCapacity(1 + index)
            values += repeatElement(.null, count: index)
            values.append(value)
        } else {
            values = [value]
        }
        self.init(values)
    }
}
