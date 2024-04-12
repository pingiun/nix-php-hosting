nixpkgs:
final:
prev:

{
  varnish_64 = prev.callPackage ./varnish/6.4.nix {};
  varnish_65 = prev.callPackage ./varnish/6.5.nix {};
  varnish_70 = prev.callPackage ./varnish/7.0.nix {};
  varnish_71 = prev.callPackage ./varnish/7.1.nix {};
  varnish_73 = prev.callPackage ./varnish/7.3.nix {};
  varnish_75 = prev.callPackage ./varnish/7.5.nix {};
}
