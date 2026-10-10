//! shuffle: print the header, then the other rows in random order.
use ports::{args, lines, opt};
use std::io::Write;

fn main() {
    let mut rows = Vec::new();
    let mut seed = 1.0;
    for (o, file) in args(&[("seed", "1")]) {
        seed = opt(&o, "seed");
        rows.extend(lines(&file));
    }
    if rows.is_empty() {
        return;
    }
    let mut state = seed as u64;
    for i in (2..rows.len()).rev() {
        // Knuth's 64-bit LCG; the high bits are the random ones
        state = state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        let j = 1 + (state >> 33) as usize % i;
        rows.swap(i, j);
    }
    let mut out = std::io::stdout().lock();
    for row in rows {
        if writeln!(out, "{row}").is_err() {
            break;
        }
    }
}
