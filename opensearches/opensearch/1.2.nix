{ callPackage }:
callPackage ./generic.nix {
  version = "1.2.4";
  hashes = {
    "x86_64-linux" = "1a6q9dsik8lj68bvmm0md0i1lrkcga2f55sr4fm6crrvcab2c3yl";
    "aarch64-linux" = "19b37sfzf67blkp004cqa27cwhvcq42lacsld8l4l7l3s4xd332y";
  };
}
