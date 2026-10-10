//! Helpers shared by the awk ports: command line, input, awk-ish values.
use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead, BufReader};

pub type Opts = HashMap<String, String>;

/// awk command line: `name=value` sets an option for the files after it;
/// `-` (or no file at all) is stdin. Returns (options, file) pairs.
pub fn args(defaults: &[(&str, &str)]) -> Vec<(Opts, String)> {
    let mut opts: Opts = defaults
        .iter()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect();
    let mut out = Vec::new();
    for arg in std::env::args().skip(1) {
        match arg.split_once('=') {
            Some((k, v)) if is_name(k) => {
                opts.insert(k.to_string(), v.to_string());
            }
            _ => out.push((opts.clone(), arg)),
        }
    }
    if out.is_empty() {
        out.push((opts, "-".to_string()));
    }
    out
}

fn is_name(s: &str) -> bool {
    let mut cs = s.chars();
    cs.next()
        .is_some_and(|c| c.is_ascii_alphabetic() || c == '_')
        && cs.all(|c| c.is_ascii_alphanumeric() || c == '_')
}

/// Numeric value of an option (0 if unset).
pub fn opt(o: &Opts, key: &str) -> f64 {
    o.get(key).map_or(0.0, |v| num(v))
}

/// All lines of a file (`-` is stdin).
pub fn lines(path: &str) -> Vec<String> {
    let input: Box<dyn BufRead> = if path == "-" {
        Box::new(io::stdin().lock())
    } else {
        let f = File::open(path).unwrap_or_else(|e| panic!("{path}: {e}"));
        Box::new(BufReader::new(f))
    };
    input.lines().map(|l| l.expect("read error")).collect()
}

/// Split on the regex ` *, *` (awk's FS for nb and knn).
pub fn fields(line: &str) -> Vec<&str> {
    if line.is_empty() {
        return vec![];
    }
    let mut out: Vec<&str> = line.split(',').collect();
    let last = out.len() - 1;
    for (i, p) in out.iter_mut().enumerate() {
        if i < last {
            *p = p.trim_end_matches(' ');
        }
        if i > 0 {
            *p = p.trim_start_matches(' ');
        }
    }
    out
}

/// Longest numeric prefix of s, like awk's string-to-number conversion.
fn scan(s: &str) -> (f64, usize) {
    let b = s.as_bytes();
    let digits = |mut i: usize| {
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        i
    };
    let mut i = digits(usize::from(matches!(b.first(), Some(b'+' | b'-'))));
    if b.get(i) == Some(&b'.') {
        i = digits(i + 1);
    }
    if matches!(b.get(i), Some(b'e' | b'E')) {
        let j = i + 1 + usize::from(matches!(b.get(i + 1), Some(b'+' | b'-')));
        if digits(j) > j {
            i = digits(j);
        }
    }
    (s[..i].parse().unwrap_or(0.0), i)
}

/// awk's numeric value of a string ("12abc" is 12, "abc" is 0).
pub fn num(s: &str) -> f64 {
    scan(s.trim_start()).0
}

/// Does s look like a number (so awk compares it numerically)?
pub fn is_num(s: &str) -> bool {
    let t = s.trim();
    scan(t).1 == t.len() && t.bytes().any(|c| c.is_ascii_digit())
}

/// awk's `a == b` on two field values.
pub fn same(a: &str, b: &str) -> bool {
    if is_num(a) && is_num(b) {
        num(a) == num(b)
    } else {
        a == b
    }
}

/// awk's ordering of two field values (numeric if both look numeric).
pub fn cmp(a: &str, b: &str) -> std::cmp::Ordering {
    if is_num(a) && is_num(b) {
        num(a).total_cmp(&num(b))
    } else {
        a.cmp(b)
    }
}

/// A number as awk prints it: integers as such, else C's "%.6g".
pub fn fmt(x: f64) -> String {
    if x == x.trunc() && x.abs() < 1e16 {
        return format!("{}", x as i64);
    }
    let e = format!("{x:.5e}");
    let (mant, exp) = e.split_once('e').unwrap();
    let exp: i32 = exp.parse().unwrap();
    let trim = |s: &str| match s.contains('.') {
        true => s.trim_end_matches('0').trim_end_matches('.').to_string(),
        false => s.to_string(),
    };
    if !(-4..6).contains(&exp) {
        let sign = if exp < 0 { '-' } else { '+' };
        format!("{}e{sign}{:02}", trim(mant), exp.abs())
    } else {
        trim(&format!("{:.*}", (5 - exp) as usize, x))
    }
}

/// Running mean and sd, used to map numbers to sigmoid bins 0..b.
#[derive(Default)]
pub struct Stats {
    n: f64,
    s: f64,
    s2: f64,
}

impl Stats {
    pub fn add(&mut self, x: f64) {
        self.n += 1.0;
        self.s += x;
        self.s2 += x * x;
    }

    pub fn bin(&self, x: f64, b: f64) -> i64 {
        let mu = self.s / self.n;
        let sd = (self.s2 / self.n - mu * mu).sqrt() + 1e-32;
        (b / (1.0 + (-1.7 * (x - mu) / sd).exp())) as i64
    }
}
