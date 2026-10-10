//! disc: two passes; bin the numeric columns (header starts A-Z).
use ports::{Stats, args, lines, num, opt};
use std::collections::BTreeMap;

fn main() {
    let (mut nr, mut numeric) = (0, Vec::new());
    let mut stats: BTreeMap<usize, Stats> = BTreeMap::new();
    for (o, file) in args(&[("B", "7")]) {
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let mut x: Vec<String> =
                line.split(',').map(String::from).collect();
            if fnr == 1 {
                let head = &x[..x.len() - 1];
                numeric = head
                    .iter()
                    .map(|s| s.starts_with(|c: char| c.is_ascii_uppercase()))
                    .collect();
                if nr > 1 {
                    println!("{line}");
                }
            } else if nr == fnr {
                for (c, _) in numeric.iter().enumerate().filter(|p| *p.1) {
                    let v = x.get(c).map_or("", |s| s.as_str());
                    if v != "?" {
                        stats.entry(c).or_default().add(num(v));
                    }
                }
            } else {
                for (&c, st) in &stats {
                    if let Some(v) = x.get_mut(c).filter(|v| *v != "?") {
                        *v = st.bin(num(v), opt(&o, "B")).to_string();
                    }
                }
                println!("{}", x.join(","));
            }
        }
    }
}
