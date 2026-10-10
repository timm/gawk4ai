//! nb: incremental naive Bayes. Train rows 1..T, classify rows > W.
use ports::{args, fields, lines, opt};
use std::collections::{BTreeMap, HashMap};

/// Per class: counts of (column, value).
type Counts = HashMap<(usize, String), f64>;

struct Nb {
    rows: f64,
    f: BTreeMap<String, Counts>,
}

impl Nb {
    fn train(&mut self, x: &[&str]) {
        self.rows += 1.0;
        let h = self.f.entry(x[x.len() - 1].to_string()).or_default();
        for (c, v) in x.iter().enumerate().filter(|p| *p.1 != "?") {
            *h.entry((c, v.to_string())).or_insert(0.0) += 1.0;
        }
    }

    fn classify(&self, x: &[&str], m: f64, k: f64) -> &str {
        let mut out: Option<(f64, &str)> = None;
        for h in self.f.keys() {
            let t = self.like(h, x, m, k);
            if out.is_none_or(|(best, _)| t > best) {
                out = Some((t, h));
            }
        }
        out.map_or("", |(_, h)| h)
    }

    /// log P(h) + sum log P(x|h)
    fn like(&self, h: &str, x: &[&str], m: f64, k: f64) -> f64 {
        let fh = &self.f[h];
        let count = |c, v: &str| fh.get(&(c, v.to_string())).copied();
        let n = count(x.len() - 1, h).unwrap_or(0.0);
        let p = (n + k) / (self.rows + k * self.f.len() as f64);
        let mut out = p.ln();
        for (c, v) in x[..x.len() - 1].iter().enumerate() {
            if *v != "?" {
                out += ((count(c, v).unwrap_or(0.0) + m * p) / (n + m)).ln();
            }
        }
        out
    }
}

fn main() {
    let defaults = [("m", "2"), ("k", "1"), ("T", "1E32"), ("W", "10")];
    let mut nb = Nb {
        rows: 0.0,
        f: BTreeMap::new(),
    };
    let mut nr = 0.0;
    for (o, file) in args(&defaults) {
        for line in lines(&file) {
            nr += 1.0;
            let x = fields(&line);
            if x.is_empty() {
                continue;
            }
            if nr > opt(&o, "W") {
                let got = nb.classify(&x, opt(&o, "m"), opt(&o, "k"));
                println!("{} {}", got, x[x.len() - 1]);
            }
            if nr <= opt(&o, "T") {
                nb.train(&x);
            }
        }
    }
}
