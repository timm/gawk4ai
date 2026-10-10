//! ybin: replace the class column by its bin (stats from 1st T rows).
use ports::{Stats, args, lines, num, opt};

fn main() {
    let (mut nr, mut stats) = (0, Stats::default());
    for (o, file) in args(&[("B", "7")]) {
        for (fnr, line) in (1..).zip(lines(&file)) {
            nr += 1;
            let mut x: Vec<String> =
                line.split(',').map(String::from).collect();
            let y = x.last_mut().unwrap();
            if nr == fnr {
                if fnr as f64 <= opt(&o, "T") && y != "?" {
                    stats.add(num(y));
                }
            } else {
                if y != "?" {
                    *y = stats.bin(num(y), opt(&o, "B")).to_string();
                }
                println!("{}", x.join(","));
            }
        }
    }
}
