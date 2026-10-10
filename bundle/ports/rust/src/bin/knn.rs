//! knn: y = mean y of K nearest train rows in the predicted y-bin.
//! (ALL=1: ignore the bin; S=n: keep only n train rows;
//!  I=1: only search rows sharing the test row's bin in the
//!       train column with most variance)
use ports::{Opts, Stats, args, fields, fmt, lines, num, opt, same};
use std::collections::HashMap;

struct Row {
    x: Vec<String>,
    y: f64,
    bin: i64,
}

struct Knn {
    rows: Vec<Row>,
    col: Option<usize>,
    idx: HashMap<String, Vec<usize>>,
}

fn is_int(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|c| c.is_ascii_digit())
}

/// Distance between two values: bins are ordered, else 0/1.
fn dist(a: &str, b: &str, bins: f64) -> f64 {
    if a == "?" || b == "?" {
        1.0
    } else if is_int(&format!("{a}{b}")) {
        (num(a) - num(b)).abs() / (bins - 1.0)
    } else {
        f64::from(!same(a, b))
    }
}

impl Knn {
    /// Index the rows on the column (of integers) with most variance.
    fn index(&mut self) {
        let mut stats: Vec<(f64, f64, f64)> = Vec::new();
        for row in &self.rows {
            for (c, v) in row.x.iter().enumerate().filter(|p| is_int(p.1)) {
                if stats.len() <= c {
                    stats.resize(c + 1, (0.0, 0.0, 0.0));
                }
                let (k, m, m2) = &mut stats[c];
                *k += 1.0;
                *m += num(v);
                *m2 += num(v) * num(v);
            }
        }
        let mut most = 0.0;
        for (c, (k, m, m2)) in stats.into_iter().enumerate() {
            let v = m2 / k - (m / k) * (m / k);
            if k > 0.0 && v > most {
                (most, self.col) = (v, Some(c));
            }
        }
        for (r, row) in self.rows.iter().enumerate() {
            let key = self.key(&row.x);
            self.idx.entry(key.to_string()).or_default().push(r);
        }
    }

    fn key<'a>(&self, x: &'a [impl AsRef<str>]) -> &'a str {
        self.col.and_then(|c| x.get(c)).map_or("", |v| v.as_ref())
    }

    fn predict(&self, o: &Opts, p: &str, z: &[&str]) -> f64 {
        let (bins, k) = (opt(o, "B"), opt(o, "K") as usize);
        let near = |r: usize| {
            let x = &self.rows[r].x;
            let d = x
                .iter()
                .enumerate()
                .map(|(c, a)| dist(a, z.get(c).unwrap_or(&""), bins));
            (d.fold(0.0, |s, v| s + v), r)
        };
        let mut d: Vec<(f64, usize)> = match self.idx.get(self.key(z)) {
            Some(rs) if opt(o, "I") != 0.0 && rs.len() >= k => {
                rs.iter().map(|&r| near(r)).collect()
            }
            _ => (0..self.rows.len())
                .filter(|&r| {
                    opt(o, "ALL") != 0.0
                        || same(&self.rows[r].bin.to_string(), p)
                })
                .map(near)
                .collect(),
        };
        d.sort_by(|a, b| a.0.total_cmp(&b.0).then(a.1.cmp(&b.1)));
        let ys: Vec<f64> =
            d.iter().take(k).map(|&(_, r)| self.rows[r].y).collect();
        ys.iter().fold(0.0, |s, y| s + y) / ys.len() as f64
    }
}

fn main() {
    let defaults = [("B", "7"), ("K", "5"), ("ALL", "0")];
    let mut knn = Knn {
        rows: vec![],
        col: None,
        idx: HashMap::new(),
    };
    let (mut nr, mut stats, mut tests) = (0, Stats::default(), vec![]);
    for (o, file) in args(&defaults) {
        let (t, s) = (opt(&o, "T"), opt(&o, "S"));
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let fnr_f = fnr as f64;
            if nr == fnr && fnr_f <= t {
                if s == 0.0 || fnr_f <= s {
                    let x = fields(&line);
                    let (y, cols) = x.split_last().unwrap();
                    stats.add(num(y));
                    let x = cols.iter().map(|v| v.to_string()).collect();
                    knn.rows.push(Row {
                        x,
                        y: num(y),
                        bin: 0,
                    });
                }
                continue;
            }
            if nr == fnr {
                tests.push(line);
                continue;
            }
            if fnr == 1 {
                for row in &mut knn.rows {
                    row.bin = stats.bin(row.y, opt(&o, "B"));
                }
                if opt(&o, "I") != 0.0 {
                    knn.index();
                }
            }
            let test = tests.get(fnr - 1).map_or("", |s| s.as_str());
            let z = fields(test);
            let p = line.split_whitespace().next().unwrap_or("");
            let y = knn.predict(&o, p, &z);
            println!("{} {}", fmt(y), z.last().unwrap_or(&""));
        }
    }
}
