//! tfidf: (text TAB label) -> counts of the K words with most tf*idf.
use ports::{args, lines, opt};
use std::collections::HashMap;

const STOP: [&str; 16] = [
    "that", "this", "with", "from", "have", "which", "their", "these", "been",
    "such", "more", "were", "also", "they", "than", "into",
];

fn words(text: &str) -> HashMap<String, f64> {
    let mut out = HashMap::new();
    let lower = text.to_ascii_lowercase();
    for w in lower.split(|c: char| !c.is_ascii_lowercase()) {
        if w.len() > 3 && !STOP.contains(&w) {
            *out.entry(w.to_string()).or_insert(0.0) += 1.0;
        }
    }
    out
}

fn main() {
    let (mut nr, mut docs) = (0, 0.0);
    let mut df: HashMap<String, f64> = HashMap::new();
    let mut tf: HashMap<String, f64> = HashMap::new();
    let mut keep: Vec<String> = Vec::new();
    for (o, file) in args(&[("K", "64")]) {
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let mut cols = line.split('\t');
            let text = cols.next().unwrap_or("");
            if fnr == 1 {
                if nr > 1 {
                    let mut score: Vec<(f64, &String)> = df
                        .iter()
                        .map(|(w, d)| (tf[w] * (docs / d).ln(), w))
                        .collect();
                    score
                        .sort_by(|a, b| b.0.total_cmp(&a.0).then(b.1.cmp(a.1)));
                    let k = opt(&o, "K") as usize;
                    keep = score.iter().take(k).map(|p| p.1.clone()).collect();
                }
            } else if nr == fnr {
                docs += 1.0;
                for (w, n) in words(text) {
                    *df.entry(w.clone()).or_insert(0.0) += 1.0;
                    *tf.entry(w).or_insert(0.0) += n;
                }
            } else {
                let a = words(text);
                let k = opt(&o, "K") as usize;
                let mut out: Vec<String> = (0..k)
                    .map(|j| keep.get(j).and_then(|w| a.get(w)).unwrap_or(&0.0))
                    .map(|n| n.to_string())
                    .collect();
                out.push(cols.next().unwrap_or("").to_string());
                println!("{}", out.join(","));
            }
        }
    }
}
