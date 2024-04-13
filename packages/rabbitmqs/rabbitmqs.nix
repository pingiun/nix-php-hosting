nixpkgs:

final:
prev:

{
  rabbitmq_312 = prev.rabbitmq-server;
  rabbitmq_313 = prev.callPackage ./rabbitmq/3.13.nix {};
}
