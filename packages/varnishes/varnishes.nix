nixpkgs: final: prev:

{
  varnish64 = prev.callPackage ./varnish/6.4.nix { };
  varnish65 = prev.callPackage ./varnish/6.5.nix { };
  varnish70 = prev.callPackage ./varnish/7.0.nix { };
  varnish71 = prev.callPackage ./varnish/7.1.nix { };
  varnish73 = prev.callPackage ./varnish/7.3.nix { };
  varnish75 = prev.callPackage ./varnish/7.5.nix { };
  varnish76 = prev.callPackage ./varnish/7.6.nix { };
}
