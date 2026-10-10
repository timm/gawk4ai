//! TWCNB: Rennie et al. ICML'03, Table 4 (steps 1-8)
//! input rows: word counts..., label
use ports::{args, lines, num, opt};
use std::collections::{BTreeMap, HashMap};

/// Training row: label and the (column, weight) of its non-zero words.
type Doc = (String, Vec<(usize, f64)>);

fn learn(
    docs: &mut [Doc],
    df: &HashMap<usize, f64>,
    t: f64,
    nf: usize,
) -> BTreeMap<String, Vec<f64>> {
    let (mut s, mut all, mut nh) =
        (HashMap::new(), HashMap::new(), BTreeMap::new());
    let mut tot = 0.0;
    for (y, d) in docs.iter_mut() {
        let mut len = 0.0;
        for (c, v) in d.iter_mut() {
            *v *= (t / df[c]).ln(); // step 2
            len += *v * *v;
        }
        for &(c, v) in d.iter() {
            let z = v / (len + 1e-32_f64).sqrt(); // step 3
            *s.entry((y.clone(), c)).or_insert(0.0) += z;
            *all.entry(c).or_insert(0.0) += z;
            *nh.entry(y.clone()).or_insert(0.0) += z;
            tot += z;
        }
    }
    let mut w = BTreeMap::new();
    for (h, nh) in nh {
        // steps 4-6
        let ws: Vec<f64> = (0..nf - 1)
            .map(|c| {
                let shc = s.get(&(h.clone(), c)).unwrap_or(&0.0);
                let a = all.get(&c).unwrap_or(&0.0);
                ((a - shc + 1.0) / (tot - nh + nf as f64 - 1.0)).ln()
            })
            .collect();
        let z = ws.iter().fold(0.0, |z, x| z - x);
        w.insert(h, ws.iter().map(|x| x / z).collect());
    }
    w
}

fn classify<'a>(w: &'a BTreeMap<String, Vec<f64>>, x: &[&str]) -> &'a str {
    // steps 7,8
    let mut out: Option<(f64, &str)> = None;
    for (h, wh) in w {
        let mut t = 0.0;
        for (c, v) in x[..x.len() - 1].iter().enumerate() {
            t += (1.0 + num(v)).ln() * wh.get(c).unwrap_or(&0.0);
        }
        if out.is_none_or(|(best, _)| t < best) {
            out = Some((t, h));
        }
    }
    out.map_or("", |(_, h)| h)
}

fn main() {
    let (mut nr, mut docs, mut df) = (0.0, Vec::new(), HashMap::new());
    let mut w = BTreeMap::new();
    for (o, file) in args(&[]) {
        let t = opt(&o, "T");
        for line in lines(&file) {
            nr += 1.0;
            let x: Vec<&str> = line.split(',').collect();
            if nr <= t {
                // step 1
                let mut d = Vec::new();
                for (c, v) in x[..x.len() - 1].iter().enumerate() {
                    if num(v) > 0.0 {
                        d.push((c, (1.0 + num(v)).ln()));
                        *df.entry(c).or_insert(0.0) += 1.0;
                    }
                }
                if !d.is_empty() {
                    docs.push((x[x.len() - 1].to_string(), d));
                }
                continue;
            }
            if nr == t + 1.0 {
                w = learn(&mut docs, &df, t, x.len());
            }
            println!("{} {}", classify(&w, &x), x[x.len() - 1]);
        }
    }
}
