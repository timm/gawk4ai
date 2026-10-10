//! select: keep the K columns with least H(class|col); default K = half.
use ports::{args, lines, opt};
use std::collections::{BTreeMap, BTreeSet};

fn main() {
    let (mut nr, mut keep) = (0, BTreeSet::new());
    let mut n: BTreeMap<(usize, String), f64> = BTreeMap::new();
    let mut ny: BTreeMap<(usize, String, String), f64> = BTreeMap::new();
    for (o, file) in args(&[("K", "0")]) {
        let t = opt(&o, "T");
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let x: Vec<&str> = line.split(',').collect();
            let (y, cols) = x.split_last().unwrap();
            if nr == fnr {
                if fnr as f64 <= t {
                    for (c, v) in
                        cols.iter().enumerate().filter(|p| *p.1 != "?")
                    {
                        *n.entry((c, v.to_string())).or_insert(0.0) += 1.0;
                        let key = (c, v.to_string(), y.to_string());
                        *ny.entry(key).or_insert(0.0) += 1.0;
                    }
                }
                continue;
            }
            if fnr == 1 {
                let mut e: BTreeMap<usize, f64> = BTreeMap::new();
                for ((c, v, _), cy) in &ny {
                    let cv = n[&(*c, v.clone())];
                    let p = cy / cv;
                    *e.entry(*c).or_insert(0.0) -= cv / t * p * p.ln();
                }
                let k = match opt(&o, "K") as usize {
                    0 => cols.len() / 2,
                    k => k,
                };
                let mut ranked: Vec<(usize, f64)> = e.into_iter().collect();
                ranked.sort_by(|a, b| a.1.total_cmp(&b.1));
                keep = ranked.iter().take(k).map(|p| p.0).collect();
            }
            let mut out: Vec<&str> =
                keep.iter().filter_map(|&c| cols.get(c)).copied().collect();
            out.push(y);
            println!("{}", out.join(","));
        }
    }
}
