{
  callPackage,
  AppKit,
  Carbon,
  Cocoa,
}:
callPackage ./generic.nix {
  version = "3.13.1";
  hash = "sha256-Yuw7xBho7zPg2396wIJpAVoeyPZJIvt4tnoPkVASYBA=";
  inherit AppKit Carbon Cocoa;
}
