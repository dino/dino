namespace Xmpp.Xep.ConsistentColor {
private const double KR = 0.299;
private const double KG = 0.587;
private const double KB = 0.114;
private const double Y = 0.732;

public float string_to_angle(string s) {
    Checksum checksum = new Checksum(ChecksumType.SHA1);
    checksum.update(s.data, -1);
    size_t len = 20;
    uint8[] digest = new uint8[len];
    checksum.get_digest(digest, ref len);
    uint16 output = ((uint16)(*(uint16*)digest)).to_little_endian();
    return (((float) output) / 65536.0f) * 360.0f;
}

private uint8[] rgbd_to_rgb(double[] rgbd) {
    return {(uint8)(rgbd[0] * 255.0), (uint8)(rgbd[1] * 255.0), (uint8)(rgbd[2] * 255.0)};
}

private float[] rgbd_to_rgbf(double[] rgbd) {
    return {(float)rgbd[0], (float)rgbd[1], (float)rgbd[2]};
}

private double[] angle_to_rgbd(double angle) {
    return Hsluv.hsluv_to_rgb(new double[] {angle, 100, 50});
}

public float[] string_to_rgbf(string s) {
    return rgbd_to_rgbf(angle_to_rgbd(string_to_angle(s)));
}

public uint8[] string_to_rgb(string s) {
    return rgbd_to_rgb(angle_to_rgbd(string_to_angle(s)));
}

}
