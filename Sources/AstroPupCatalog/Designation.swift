import Foundation

/// Designation normalization shared by the resolver and the alias cross-reference.
public enum Designation {
    /// Uppercase, strip non-alphanumerics, drop leading zeros within each digit
    /// run. So "NGC 224"/"NGC0224", "UGC 5079"/"UGC 05079", "Sh2 119"/"SH 2-119"
    /// all collapse to a single comparable key.
    public static func normalize(_ s: String) -> String {
        let upper = s.uppercased()
        var out = ""
        var digits = ""
        func flushDigits() {
            guard !digits.isEmpty else { return }
            out += String(Int(digits) ?? 0)
            digits = ""
        }
        for ch in upper {
            if ch.isNumber { digits.append(ch) }
            else if ch.isLetter { flushDigits(); out.append(ch) }
            else { flushDigits() } // drop spaces, dashes, dots, plus, etc.
        }
        flushDigits()
        return out
    }
}
