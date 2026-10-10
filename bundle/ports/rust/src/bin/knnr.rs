//! knnr: kNN on raw rows. Numbers scaled 0..1 by train min/max,
//! symbols 0/1, "?" 1. Predict mean y of K nearest. Prints y^ y.
use ports::{args, cmp, fields, fmt, lines, num, opt, same};
use std::cmp::Ordering::{Greater, Less};
use std::collections::HashMap;

struct Knnr {
    num: Vec<bool>,
    rows: Vec<(Vec<String>, f64)>,
    lo: HashMap<usize, String>,
    hi: HashMap<usize, String>,
}

impl Knnr {
    fn train(&mut self, x: &[&str]) {
        let (y, cols) = x.split_last().unwrap_or((&"", &[]));
        for (c, v) in cols.iter().enumerate() {
            if self.num.get(c) == Some(&true) && *v != "?" {
                let lo = self.lo.entry(c).or_insert(v.to_string());
                if cmp(v, lo) == Less {
                    *lo = v.to_string();
                }
                let hi = self.hi.entry(c).or_insert(v.to_string());
                if cmp(v, hi) == Greater {
                    *hi = v.to_string();
                }
            }
        }
        let cols = cols.iter().map(|v| v.to_string()).collect();
        self.rows.push((cols, num(y)));
    }

    fn gap(&self, c: usize, a: &str, b: &str) -> f64 {
        if a == "?" || b == "?" {
            return 1.0;
        }
        if self.num.get(c) != Some(&true) {
            return f64::from(!same(a, b));
        }
        let get =
            |m: &HashMap<usize, String>| m.get(&c).map_or(0.0, |v| num(v));
        (num(a) - num(b)) / (get(&self.hi) - get(&self.lo) + 1E-32)
    }

    fn predict(&self, z: &[&str], k: usize) -> f64 {
        let mut d: Vec<(f64, usize)> = self
            .rows
            .iter()
            .enumerate()
            .filter(|(_, (x, _))| !x.is_empty())
            .map(|(r, (x, _))| {
                let mut s = 0.0;
                for (c, a) in x.iter().enumerate() {
                    s += self.gap(c, a, z.get(c).unwrap_or(&"")).powi(2);
                }
                (s, r)
            })
            .collect();
        d.sort_by(|a, b| a.0.total_cmp(&b.0).then(a.1.cmp(&b.1)));
        let near = &d[..k.min(d.len())];
        near.iter().map(|&(_, r)| self.rows[r].1).sum::<f64>()
            / near.len() as f64
    }
}

fn main() {
    let mut knn = Knnr {
        num: vec![],
        rows: vec![],
        lo: HashMap::new(),
        hi: HashMap::new(),
    };
    let mut nr = 0.0;
    for (o, file) in args(&[("K", "5")]) {
        for line in lines(&file) {
            nr += 1.0;
            let x = fields(&line);
            if nr == 1.0 {
                let names = &x[..x.len().saturating_sub(1)];
                knn.num = names
                    .iter()
                    .map(|s| s.starts_with(|c: char| c.is_ascii_uppercase()))
                    .collect();
            } else if nr <= opt(&o, "T") + 1.0 {
                knn.train(&x);
            } else {
                let y = knn.predict(&x, opt(&o, "K") as usize);
                println!("{} {}", fmt(y), x.last().unwrap_or(&""));
            }
        }
    }
}
