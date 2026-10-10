//! abcd: confusion-matrix stats from "predicted actual" lines.
use ports::{args, lines, same};
use std::collections::HashMap;

fn pc(x: i64, y: i64) -> i64 {
    if y == 0 {
        0
    } else {
        (100.0 * x as f64 / y as f64 + 0.5) as i64
    }
}

fn main() {
    let (mut n, mut got, mut want, mut hit) =
        (0, HashMap::new(), HashMap::new(), HashMap::new());
    for (_, file) in args(&[]) {
        for line in lines(&file) {
            let w: Vec<&str> = line.split_whitespace().collect();
            let (a, b) = (w.first().unwrap_or(&""), w.get(1).unwrap_or(&""));
            n += 1;
            *got.entry(a.to_string()).or_insert(0) += 1;
            *want.entry(b.to_string()).or_insert(0) += 1;
            *hit.entry(a.to_string()).or_insert(0) += i64::from(same(a, b));
        }
    }
    let mut rows = Vec::new();
    for (x, &wanted) in &want {
        let d = hit.get(x).copied().unwrap_or(0);
        let b = wanted - d;
        let c = got.get(x).copied().unwrap_or(0) - d;
        let a = n - b - c - d;
        let pd = pc(d, b + d);
        let row = format!(
            "{wanted:4},{a:4},{b:4},{c:4},{d:4},{:3},{:3},{:3},{pd:3}, {x}",
            pc(a + d, n),
            pc(d, c + d),
            pc(c, a + c)
        );
        rows.push((pd, row));
    }
    // like `sort -t, -k9nr`: pd descending, then whole line ascending
    rows.sort_by(|p, q| q.0.cmp(&p.0).then(p.1.cmp(&q.1)));
    println!("   n,   a,   b,   c,   d,acc,pre, pf, pd, class");
    for (_, row) in rows {
        println!("{row}");
    }
}
