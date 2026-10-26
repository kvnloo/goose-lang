// runtime-debug: decimal rounding must not suffer u64-to-f64 double rounding.
import std;
import json;

fn expect(text: u8[:], expected: f64) {
    let got, ok = parse_flt(text);
    assert(ok && got == expected);
}

var seed: u64 = 0x9E3779B97F4A7C15;
fn next_random() -> u64 {
    seed ^= seed << 13;
    seed ^= seed >> 7;
    seed ^= seed << 17;
    return seed;
}

// JSON's independent exact parser provides an oracle for valid JSON numbers.
fn check(text: u8[:]) {
    let got, ok = parse_flt(text);
    let reference = json::scan_number_general(text, 0);
    assert(ok && reference.end == text.len && got == reference.value);
}

fn main() {
    // Cases supplied by billybromfield in aardappel/goose issue #88.
    expect("98.91739066979865", 98.91739066979865);
    expect("110.35759859866259", 110.35759859866259);
    expect("114.80299819254557", 114.80299819254557);
    expect("103.56484075001073", 103.56484075001073);
    expect("1.1035759859866259e2", 110.35759859866259);
    expect("-98.91739066979865", -98.91739066979865);
    expect("+98.91739066979865", 98.91739066979865);
    expect("0000098.91739066979865", 98.91739066979865);
    expect("98.91739066979865000", 98.91739066979865);
    expect("9007199254740993.0", 9007199254740992.0);
    expect("9007199254740995.0", 9007199254740996.0);

    // Exercise binary64 halfway cases and decimal scaling at both ends of
    // the exact-comparison range, not only examples near 100.
    for k in 6000 {
        let mant: u64 = 10000000000000000 + next_random() % 9000000000000000000;
        let e = (next_random() % 45) as i64 - 22;
        check(str(mant, "e", e));
    }
    for k in 4000 {
        // 90..250 with 15 digits after the point, as in the bug report.
        let mant: u64 = 90000000000000000 + next_random() % 160000000000000000;
        let digits = str(mant);
        let cut = digits.len - 15;
        check(str(digits[..cut], ".", digits[cut..]));
    }
    print("10000 decimal values round as JSON");
}
