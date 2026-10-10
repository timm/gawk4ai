//! some: keep the first N rows, then the rows after T.
use ports::{args, lines, opt};

fn main() {
    let mut nr = 0.0;
    for (o, file) in args(&[]) {
        for line in lines(&file) {
            nr += 1.0;
            if nr <= opt(&o, "N") || nr > opt(&o, "T") {
                println!("{line}");
            }
        }
    }
}
