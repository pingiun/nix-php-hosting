nixpkgs:

final: prev:

let
  elixirs = prev.callPackage ./elixir { };
in

{
  rabbitmq_311 = prev.callPackage ./rabbitmq/3.11.nix {
    erlang = prev.erlang_26;
    elixir = elixirs.elixir_1_15;
  };
  rabbitmq_312 = prev.callPackage ./rabbitmq/3.12.nix {
    erlang = prev.erlang_26;
    elixir = elixirs.elixir_1_15;
  };
  rabbitmq_313 = prev.callPackage ./rabbitmq/3.13.nix {
    erlang = prev.erlang_26;
    elixir = elixirs.elixir_1_17;
  };
  rabbitmq_41 = prev.callPackage ./rabbitmq/4.1.nix {
    erlang = prev.erlang_27;
    elixir = elixirs.elixir_1_17;
  };
}
