nixpkgs:

final: prev:

let
  elixirs = prev.callPackage ./elixir { };
in

{
  # Currently not able to build these:
  # rabbitmq_38 = prev.callPackage ./rabbitmq/3.8.nix {
  #   inherit (prev.darwin) AppKit Carbon Cocoa;
  # };
  # rabbitmq_39 = prev.callPackage ./rabbitmq/3.9.nix {
  #   inherit (prev.darwin) AppKit Carbon Cocoa;
  # };
  rabbitmq_311 = prev.callPackage ./rabbitmq/3.11.nix {
    inherit (prev.darwin) AppKit Carbon Cocoa;
    elixir = prev.elixir_1_15;
  };
  rabbitmq_312 = prev.callPackage ./rabbitmq/3.12.nix {
    inherit (prev.darwin) AppKit Carbon Cocoa;
    erlang = prev.erlang_25;
    elixir = prev.elixir_1_15;
  };
  rabbitmq_313 = prev.callPackage ./rabbitmq/3.13.nix {
    inherit (prev.darwin) AppKit Carbon Cocoa;
    erlang = prev.erlang_26;
    elixir = elixirs.elixir_1_17;
  };
}
