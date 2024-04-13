# This flake was initially generated by fh, the CLI for FlakeHub (version 0.1.10)
{
  # A helpful description of your flake
  description = "Every package you need for hosting MageOS (and Magento)";

  # Flake inputs
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2311.*.tar.gz";
  };

  # Flake outputs that other flakes can use
  outputs = { self, flake-schemas, nixpkgs }:
    let
      # Helpers for producing system-specific outputs
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      devSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = forSomeSupportedSystems supportedSystems;
      forEachDevSystem = forSomeSupportedSystems devSystems;
      forSomeSupportedSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            permittedInsecurePackages = [
              "openssl-1.1.1w" # Required by MySQL 5.7
            ];
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "elasticsearch"
            ];
          };
          overlays = [
            (import ./phps/phps.nix nixpkgs)
            (import ./mysqls/mysqls.nix nixpkgs)
            (import ./mariadbs/mariadbs.nix nixpkgs)
            (import ./redises/redises.nix nixpkgs)
            (import ./varnishes/varnishes.nix nixpkgs)
            (import ./elasticsearches/elasticsearches.nix nixpkgs)
            (import ./opensearches/opensearches.nix nixpkgs)
          ];
        };
      });
    in
    {
      # Schemas tell Nix about the structure of your flake's outputs
      schemas = flake-schemas.schemas;

      packages = forEachSupportedSystem ({ pkgs, ... }: {
        inherit (pkgs) php56 php70 php71 php72 php73 php74 php80 php81 php82 php83
          mariadb_104 mariadb_106
          mysql57 mysql80
          redis_60 redis_62 redis_70 redis_72
          varnish64 varnish65 varnish70 varnish71 varnish73 varnish75
          elasticsearch_79 elasticsearch_716 elasticsearch_717 elasticsearch_84 elasticsearch_85 elasticsearch_811
          opensearch_212;
      });

      # Development environments
      devShells = forEachDevSystem ({ pkgs, ... }:
        let
          mkNushellScript =
            { name
            , script
            , bin ? name
            , path ? [ ]
            }:

            let
              nu = "${pkgs.nushell}/bin/nu";
            in
            pkgs.writeTextFile {
              inherit name;
              destination = "/bin/${bin}";
              text = ''
                #!${nu}

                $env.PATH = (${builtins.toJSON (builtins.toJSON (map (x: "${x}/bin") path))} | from json);

                ${script}
              '';
              executable = true;
            };
        in
        {
          default = pkgs.mkShell {
            # Pinned packages available in the environment
            packages = with pkgs; [
              nixpkgs-fmt
              (mkNushellScript {
                name = "update-phps";
                script = builtins.readFile ./scripts/update-phps.nu;
                path = with pkgs; [ coreutils git rsync ];
              })
            ];
          };
        });
    };
}
