extension JSValue {
    @frozen @usableFromInline enum Storage {
        case boolean(Bool)
        case string(JSString)
        case number(Double)
        case object(JSObject)
        case null
        case undefined
        case symbol(JSSymbol)
        case bigInt(JSBigInt)
    }
}
