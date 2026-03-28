namespace Hsluv {

private const double[] M0 = {  3.240969941904521, -1.537383177570093, -0.498610760293    };
private const double[] M1 = { -0.96924363628087, 1.87596750150772, 0.041555057407175 };
private const double[] M2 = {  0.055630079696993, -0.20397695888897, 1.056971514242878 };

private const double[] MInv0 = { 0.41239079926595, 0.35758433938387, 0.18048078840183  };
private const double[] MInv1 = { 0.21263900587151, 0.71516867876775, 0.072192315360733 };
private const double[] MInv2 = { 0.019330818715591, 0.11919477979462, 0.95053215224966  };

private double RefX = 0.95045592705167;
private double RefY = 1.0;
private double RefZ = 1.089057750759878;

private double RefU = 0.19783000664283;
private double RefV = 0.46831999493879;

private double Kappa = 903.2962962;
private double Epsilon = 0.0088564516;

private struct Bounds {
    double t0;
    double t1;
}

private Bounds get_bounds_sub(double L, double sub1, double sub2, int t, double[] m) {
    double m1 = m[0];
    double m2 = m[1];
    double m3 = m[2];
    double top1 = (284517 * m1 - 94839 * m3) * sub2;
    double top2 = (838422 * m3 + 769860 * m2 + 731718 * m1) * L * sub2 - 769860 * t * L;
    double bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t;
    return { top1 / bottom, top2 / bottom };
}

private Bounds[] get_bounds(double L) {
    double sub1 = Math.pow(L + 16, 3) / 1560896;
    double sub2 = sub1 > Epsilon ? sub1 : L / Kappa;

    return {
        get_bounds_sub(L, sub1, sub2, 0, M0),
        get_bounds_sub(L, sub1, sub2, 1, M0),
        get_bounds_sub(L, sub1, sub2, 0, M1),
        get_bounds_sub(L, sub1, sub2, 1, M1),
        get_bounds_sub(L, sub1, sub2, 0, M2),
        get_bounds_sub(L, sub1, sub2, 1, M2)
    };
}

private double intersect_line_line(double[] lineA, double[] lineB) {
    return (lineA[1] - lineB[1]) / (lineB[0] - lineA[0]);
}

private double distance_from_pole(double[] point) {
    return Math.sqrt(Math.pow(point[0], 2) + Math.pow(point[1], 2));
}

private bool length_of_ray_until_intersect(double theta, Bounds line, out double length) {
    length = line.t1 / (Math.sin(theta) - line.t0 * Math.cos(theta));

    return length >= 0;
}

private double max_safe_chroma_for_l(double L) {
    Bounds[] bounds = get_bounds(L);
    double min = double.MAX;

    for (int i = 0; i < 2; ++i) {
        var m1 = bounds[i].t0;
        var b1 = bounds[i].t1;
        var line = new double[] { m1, b1 };

        double x = intersect_line_line(line, new double[] {-1 / m1, 0 });
        double length = distance_from_pole(new double[] { x, b1 + x * m1 });

        min = double.min(min, length);
    }

    return min;
}

private double max_chroma_for_lh(double L, double H) {
    double hrad = H / 360 * Math.PI * 2;

    Bounds[] bounds = get_bounds(L);
    double min = double.MAX;

    foreach (var bound in bounds) {
        double length;

        if (length_of_ray_until_intersect(hrad, bound, out length)) {
            min = double.min(min, length);
        }
    }

    return min;
}

private double dot_product(double[] a, double[] b) {
    double sum = 0;

    for (int i = 0; i < a.length; ++i) {
        sum += a[i] * b[i];
    }

    return sum;
}

private double round(double value, int places) {
    double n = Math.pow(10, places);

    return Math.round(value * n) / n;
}

private double from_linear(double c) {
    if (c <= 0.0031308) {
        return 12.92 * c;
    } else {
        return 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
    }
}

private double to_linear(double c) {
    if (c > 0.04045) {
        return Math.pow((c + 0.055) / (1 + 0.055), 2.4);
    } else {
        return c / 12.92;
    }
}

private int[] rgb_prepare(double[] tuple) {
    for (int i = 0; i < tuple.length; ++i) {
        tuple[i] = round(tuple[i], 3);
    }

    for (int i = 0; i < tuple.length; ++i) {
        double ch = tuple[i];

        if (ch < -0.0001 || ch > 1.0001) {
            return null; //throw new Error("Illegal rgb value: " + ch);
                }
    }

    var results = new int[tuple.length];

    for (int i = 0; i < tuple.length; ++i) {
        results[i] = (int) Math.round(tuple[i] * 255);
    }

    return results;
}

internal double[] xyz_to_rgb(double[] tuple) {
    return new double[] {
        from_linear(dot_product(M0, tuple)),
        from_linear(dot_product(M1, tuple)),
        from_linear(dot_product(M2, tuple))
    };
}

internal double[] rgb_to_xyz(double[] tuple) {
    var rgbl = new double[]    {
        to_linear(tuple[0]),
        to_linear(tuple[1]),
        to_linear(tuple[2])
    };

    return new double[]    {
        dot_product(MInv0, rgbl),
        dot_product(MInv1, rgbl),
        dot_product(MInv2, rgbl)
    };
}

private double y_to_l(double Y) {
    if (Y <= Epsilon) {
        return (Y / RefY) * Kappa;
    } else {
        return 116 * Math.pow(Y / RefY, 1.0 / 3.0) - 16;
    }
}

private double l_to_y(double L) {
    if (L <= 8) {
        return RefY * L / Kappa;
    } else {
        return RefY * Math.pow((L + 16) / 116, 3);
    }
}

internal double[] xyz_to_luv(double[] tuple) {
    double X = tuple[0];
    double Y = tuple[1];
    double Z = tuple[2];

    double varU = (4 * X) / (X + (15 * Y) + (3 * Z));
    double varV = (9 * Y) / (X + (15 * Y) + (3 * Z));

    double L = y_to_l(Y);

    if (L == 0) {
        return new double[] { 0, 0, 0 };
    }

    var U = 13 * L * (varU - RefU);
    var V = 13 * L * (varV - RefV);

    return new double [] { L, U, V };
}

internal double[] luv_to_xyz(double[] tuple) {
    double L = tuple[0];
    double U = tuple[1];
    double V = tuple[2];

    if (L == 0) {
        return new double[] { 0, 0, 0 };
    }

    double varU = U / (13 * L) + RefU;
    double varV = V / (13 * L) + RefV;

    double Y = l_to_y(L);
    double X = 0 - (9 * Y * varU) / ((varU - 4) * varV - varU * varV);
    double Z = (9 * Y - (15 * varV * Y) - (varV * X)) / (3 * varV);

    return new double[] { X, Y, Z };
}

internal double[] luv_to_lch(double[] tuple) {
    double L = tuple[0];
    double U = tuple[1];
    double V = tuple[2];

    double C = Math.pow(Math.pow(U, 2) + Math.pow(V, 2), 0.5);
    double Hrad = Math.atan2(V, U);

    double H = Hrad * 180.0 / Math.PI;

    if (H < 0) {
        H = 360 + H;
    }

    return new double[] { L, C, H };
}

internal double[] lch_to_luv(double[] tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    double Hrad = H / 360.0 * 2 * Math.PI;
    double U = Math.cos(Hrad) * C;
    double V = Math.sin(Hrad) * C;

    return new double [] { L, U, V };
}

internal double[] hsluv_to_lch(double[] tuple) {
    double H = tuple[0];
    double S = tuple[1];
    double L = tuple[2];

    if (L > 99.9999999) {
        return new double[] { 100, 0, H };
    }

    if (L < 0.00000001) {
        return new double[] { 0, 0, H };
    }

    double max = max_chroma_for_lh(L, H);
    double C = max / 100 * S;

    return new double[] { L, C, H };
}

internal double[] lch_to_hsluv(double[] tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    if (L > 99.9999999) {
        return new double[] { H, 0, 100 };
    }

    if (L < 0.00000001) {
        return new double[] { H, 0, 0 };
    }

    double max = max_chroma_for_lh(L, H);
    double S = C / max * 100;

    return new double[] { H, S, L };
}

internal double[] hpluv_to_lch(double[] tuple) {
    double H = tuple[0];
    double S = tuple[1];
    double L = tuple[2];

    if (L > 99.9999999) {
        return new double[] { 100, 0, H };
    }

    if (L < 0.00000001) {
        return new double[] { 0, 0, H };
    }

    double max = max_safe_chroma_for_l(L);
    double C = max / 100 * S;

    return new double[] { L, C, H };
}

internal double[] lch_to_hpluv(double[] tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    if (L > 99.9999999) {
        return new double[] { H, 0, 100 };
    }

    if (L < 0.00000001) {
        return new double[] { H, 0, 0 };
    }

    double max = max_safe_chroma_for_l(L);
    double S = C / max * 100;

    return new double[] { H, S, L };
}

internal string rgb_to_hex(double[] tuple) {
    int[] prepared = rgb_prepare(tuple);

    return "#%.2x%.2x%.2x".printf(prepared[0], prepared[1], prepared[2]);
}

internal double[] hex_to_tgb(string hex) {
    return new double[]    {
        hex.substring(1, 2).to_long(null, 16) / 255.0,
        hex.substring(3, 2).to_long(null, 16) / 255.0,
        hex.substring(5, 2).to_long(null, 16) / 255.0
    };
}

internal double[] lch_to_rgb(double[] tuple) {
    return xyz_to_rgb(luv_to_xyz(lch_to_luv(tuple)));
}

internal double[] rgb_to_lch(double[] tuple) {
    return luv_to_lch(xyz_to_luv(rgb_to_xyz(tuple)));
}

// Rgb <--> Hsluv(p)

internal double[] hsluv_to_rgb(double[] tuple) {
    return lch_to_rgb(hsluv_to_lch(tuple));
}

internal double[] rgb_to_hsluv(double[] tuple) {
    return lch_to_hsluv(rgb_to_lch(tuple));
}

internal double[] hpluv_to_rgb(double[] tuple) {
    return lch_to_rgb(hpluv_to_lch(tuple));
}

internal double[] rgb_to_hpluv(double[] tuple) {
    return lch_to_hpluv(rgb_to_lch(tuple));
}

// Hex

internal string hsluv_to_hex(double[] tuple) {
    return rgb_to_hex(hsluv_to_rgb(tuple));
}

internal string hpluv_to_hex(double[] tuple) {
    return rgb_to_hex(hpluv_to_rgb(tuple));
}

internal double[] hex_to_hsluv(string s) {
    return rgb_to_hsluv(hex_to_tgb(s));
}

internal double[] hex_to_hpluv(string s) {
    return rgb_to_hpluv(hex_to_tgb(s));
}

}