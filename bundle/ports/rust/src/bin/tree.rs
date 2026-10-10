//! tree: regression tree. Split on col<=bin (or col==symbol) that
//! most reduces squared error; stop below M rows. Prints y^ y.
use ports::{args, fmt, lines, num, opt, same};
use std::collections::{HashMap, HashSet};

struct Tree {
    x: Vec<Vec<String>>,
    y: Vec<f64>,
    mean: HashMap<usize, f64>,
    split: HashMap<usize, (usize, String)>,
}

/// Bins compare with <=; symbols with ==.
fn goes(a: &str, v: &str) -> bool {
    let ab = format!("{a}{v}");
    if !ab.is_empty() && ab.bytes().all(|c| c.is_ascii_digit()) {
        num(a) <= num(v)
    } else {
        same(a, v)
    }
}

impl Tree {
    fn get(&self, r: usize, c: usize) -> &str {
        self.x[r].get(c).map_or("", |s| s.as_str())
    }

    fn part(&self, ids: &[usize], c: usize, v: &str, want: bool) -> Vec<usize> {
        let ok = |&&r: &&usize| goes(self.get(r, c), v) == want;
        ids.iter().filter(ok).copied().collect()
    }

    fn sse(&self, ids: &[usize]) -> f64 {
        if ids.is_empty() {
            return 0.0;
        }
        let (mut s, mut s2) = (0.0, 0.0);
        for &r in ids {
            s += self.y[r];
            s2 += self.y[r] * self.y[r];
        }
        s2 - s * s / ids.len() as f64
    }

    fn grow(&mut self, ids: &[usize], k: usize, ncols: usize, m: f64) {
        let s: f64 = ids.iter().map(|&r| self.y[r]).sum();
        self.mean.insert(k, s / ids.len() as f64);
        if (ids.len() as f64) < m {
            return;
        }
        let mut best = (self.sse(ids), None);
        for c in 0..ncols {
            let mut seen = HashSet::new();
            for &r in ids {
                let v = self.get(r, c);
                if !seen.insert(v) {
                    continue;
                }
                let e = self.sse(&self.part(ids, c, v, true))
                    + self.sse(&self.part(ids, c, v, false));
                if e < best.0 {
                    best = (e, Some((c, v.to_string())));
                }
            }
        }
        let Some((c, v)) = best.1 else { return };
        let (yes, no) =
            (self.part(ids, c, &v, true), self.part(ids, c, &v, false));
        self.split.insert(k, (c, v));
        self.grow(&yes, 2 * k, ncols, m);
        self.grow(&no, 2 * k + 1, ncols, m);
    }

    fn leaf(&self, z: &[&str]) -> f64 {
        let mut k = 1;
        while let Some((c, v)) = self.split.get(&k) {
            k = 2 * k + usize::from(!goes(z.get(*c).unwrap_or(&""), v));
        }
        self.mean[&k]
    }
}

fn main() {
    let mut tree = Tree {
        x: vec![],
        y: vec![],
        mean: HashMap::new(),
        split: HashMap::new(),
    };
    let mut nr = 0.0;
    for (o, file) in args(&[("M", "8")]) {
        let t = opt(&o, "T");
        for line in lines(&file) {
            nr += 1.0;
            let z: Vec<&str> = match line.as_str() {
                "" => vec![],
                l => l.split(',').collect(),
            };
            let (y, cols) = z.split_last().unwrap_or((&"", &[]));
            if nr <= t {
                tree.x.push(cols.iter().map(|v| v.to_string()).collect());
                tree.y.push(num(y));
                continue;
            }
            if nr == t + 1.0 {
                let ids: Vec<usize> = (0..tree.y.len()).collect();
                tree.grow(&ids, 1, cols.len(), opt(&o, "M"));
            }
            println!("{} {}", fmt(tree.leaf(&z)), y);
        }
    }
}
