{ callPackage }:
callPackage ./generic.nix {
  version = "2.19.2";
  hashes = {
    "x86_64-linux" = "sha256-EaOx8vs3y00ln7rUiaCGoD+HhiQY4bhQAzu18VfaTYw=";
    "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
