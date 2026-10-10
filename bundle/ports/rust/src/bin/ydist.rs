//! ydist: (MOOT optimize csv, 2 passes) keep x columns; swap the
//! goals (names ending in + or -) for one column: distance to
//! heaven (0 = best). Skips names ending in X.
use ports::{args, fields, fmt, lines, num};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Default)]
struct Ydist {
    w: BTreeMap<usize, f64>,
    x: BTreeSet<usize>,
    lo: BTreeMap<usize, f64>,
    hi: BTreeMap<usize, f64>,
}

impl Ydist {
    fn header(&mut self, names: &[&str]) -> String {
        let mut out = String::new();
        for (c, s) in names.iter().enumerate() {
            if s.ends_with(['+', '-']) {
                self.w.insert(c, f64::from(s.ends_with('+')));
            } else if !s.ends_with('X') {
                self.x.insert(c);
                out += &format!("{s},");
            }
        }
        out + "D2h-"
    }

    fn minmax(&mut self, z: &[&str]) {
        for &c in self.w.keys() {
            let v = z.get(c).unwrap_or(&"");
            if *v != "?" {
                let v = num(v);
                let lo = self.lo.entry(c).or_insert(v);
                *lo = lo.min(v);
                let hi = self.hi.entry(c).or_insert(v);
                *hi = hi.max(v);
            }
        }
    }

    fn row(&self, z: &[&str]) -> String {
        let get = |c: usize| *z.get(c).unwrap_or(&"");
        let mut out = String::new();
        for &c in &self.x {
            out += &format!("{},", get(c));
        }
        let mut d = 0.0;
        for (&c, w) in &self.w {
            let lo = self.lo.get(&c).copied().unwrap_or(0.0);
            let hi = self.hi.get(&c).copied().unwrap_or(0.0);
            d += (w - (num(get(c)) - lo) / (hi - lo + 1E-32)).powi(2);
        }
        out + &fmt((d / self.w.len() as f64).sqrt())
    }
}

fn main() {
    let mut yd = Ydist::default();
    let mut nr = 0;
    for (n, (_, file)) in args(&[]).into_iter().enumerate() {
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let z = fields(&line);
            if fnr == 1 {
                let head = yd.header(&z);
                if nr > 1 {
                    println!("{head}");
                }
            } else if n == 0 {
                yd.minmax(&z);
            } else {
                println!("{}", yd.row(&z));
            }
        }
    }
}
