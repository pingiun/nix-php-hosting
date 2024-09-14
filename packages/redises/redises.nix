nixpkgs: final: prev:

{
  redis_60 = prev.callPackage ./redis/6.0.nix { };
  redis_62 = prev.callPackage ./redis/6.2.nix { };
  redis_70 = prev.callPackage ./redis/7.0.nix { };
  redis_72 = prev.redis;
}
