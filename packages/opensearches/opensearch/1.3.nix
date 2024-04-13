{ callPackage, jre_headless }:
callPackage ./generic.nix {
  version = "1.3.15";
  hashes = {
    "x86_64-linux" = "0wjy711s3k1k9jm8n73qdiwjwr8y2q7py1bx13f29d2ikynhgfk4";
    "aarch64-linux" = "05nw73xhflz487jzq3zjq07dwvmb36nh4xxpiaqi0ni45jhr0848";
  };
  inherit jre_headless;
}
