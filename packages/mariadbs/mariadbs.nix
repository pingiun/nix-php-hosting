nixpkgs:

final: prev:

{
  mariadb_104 = prev.callPackage ./mariadb/10.4.nix { };
  mariadb_106 = prev.mariadb_106;
}
