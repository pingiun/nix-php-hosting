nixpkgs:
final:
prev:

{
  redis_70 = prev.callPackage ./redis/7.0.nix { };
  redis_72 = prev.redis;
}
