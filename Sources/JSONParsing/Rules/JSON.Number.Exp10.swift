extension JSON.Number {
    /// A namespace for decimal-related functionality.
    ///
    /// This API is used by library functions that are emitted into the client.
    /// Most library users should not have to call it directly.
    enum Exp10 {}
}
extension JSON.Number.Exp10 {
    /// Positive powers of 10, up to `10_000_000_000_000_000_000`.
    private static var powers: InlineArray<20, UInt64> {
        [
            1,
            10,
            100,

            1_000,
            10_000,
            100_000,

            1_000_000,
            10_000_000,
            100_000_000,

            1_000_000_000,
            10_000_000_000,
            100_000_000_000,

            1_000_000_000_000,
            10_000_000_000_000,
            100_000_000_000_000,

            1_000_000_000_000_000,
            10_000_000_000_000_000,
            100_000_000_000_000_000,

            1_000_000_000_000_000_000,
            10_000_000_000_000_000_000,
            //  UInt64.max:
            //  18_446_744_073_709_551_615
        ]
    }

    static subscript(power: Int) -> UInt64 { self.powers[power] }
    static var startIndex: Int { self.powers.startIndex }
    static var endIndex: Int { self.powers.endIndex }
}
