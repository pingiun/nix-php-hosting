nixpkgs:

final: prev:

{
  # https://github.com/NixOS/nixpkgs/blob/611bf8f183e6360c2a215fa70dfd659943a9857f/pkgs/servers/sql/mysql/5.7.x.nix
  # https://github.com/NixOS/nixpkgs/blob/611bf8f183e6360c2a215fa70dfd659943a9857f/pkgs/top-level/all-packages.nix#L23812
  mysql57 =
    prev.callPackage ./mysql/5.7.nix
      {
        inherit (prev.darwin) cctools developer_cmds;
        inherit (prev.darwin.apple_sdk.frameworks) CoreServices;
        boost = prev.callPackage ./boost/1.59.nix { };
        protobuf = prev.callPackage ./protobuf/3.7.nix { };
        openssl = prev.openssl_1_1;
      }
      .overrideAttrs
      (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
        postFixup = ''
          wrapProgram $out/bin/mysql --add-flags '--defaults-file=''${XDG_CONFIG_HOME:-$HOME/.config}/mysql/my.cnf'
        '';
      });
  mysql80 = prev.mysql80.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
    postFixup = ''
      wrapProgram $out/bin/mysql --add-flags '--defaults-file=''${XDG_CONFIG_HOME:-$HOME/.config}/mysql/my.cnf'
    '';
  });
}
