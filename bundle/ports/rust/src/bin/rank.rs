//! rank: (lines: predicted actual) check the C rows with the best
//! (lowest) predictions; print how the best of them really ranks
//! among all n test rows, as s=r/n.
use ports::{args, cmp, fmt, lines, num, opt};
use std::cmp::Ordering::Less;

fn main() {
    let (mut rows, mut c) = (vec![], 0);
    for (o, file) in args(&[("C", "5")]) {
        c = opt(&o, "C") as usize;
        for line in lines(&file) {
            let mut w = line.split_whitespace().map(str::to_string);
            let p = w.next().unwrap_or_default();
            rows.push((p, w.next().unwrap_or_default()));
        }
    }
    let mut order: Vec<usize> = (0..rows.len()).collect();
    order.sort_by(|&i, &j| num(&rows[i].0).total_cmp(&num(&rows[j].0)));
    let best = order
        .iter()
        .take(if c == 0 { usize::MAX } else { c })
        .map(|&i| rows[i].1.as_str())
        .reduce(|b, a| if cmp(a, b) == Less { a } else { b });
    if let Some(b) = best {
        let n = rows.iter().filter(|r| cmp(&r.1, b) == Less).count();
        println!("{}", fmt((n + 1) as f64 / rows.len() as f64));
    }
}
