{ config, lib, pkgs, ... }:

with lib;

let
  systemBuilder =
    ''
      mkdir $out

      echo "$activationScript" > $out/activate
      echo "$dryActivationScript" > $out/dry-activate
      substituteInPlace $out/activate --subst-var out
      substituteInPlace $out/dry-activate --subst-var out
      chmod u+x $out/activate $out/dry-activate
    '';

  # Putting it all together.  This builds a store path containing
  # symlinks to the various parts of the built configuration (the
  # kernel, systemd units, init scripts, etc.) as well as a script
  # `switch-to-configuration' that activates the configuration and
  # makes it bootable. See `activatable-system.nix`.
  baseSystem = pkgs.stdenvNoCC.mkDerivation ({
    name = "project-${config.project.name}";
    preferLocalBuild = true;
    allowSubstitutes = false;
    buildCommand = systemBuilder;

    activationScript = config.system.activationScripts.script;
    dryActivationScript = config.system.dryActivationScript;
  });

  # Handle assertions and warnings

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  system = if failedAssertions != []
    then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings config.warnings baseSystem;
in

{
  imports = [
    ../build.nix
  ];

  options = {

    system.build = {
      toplevel = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          This option contains the store path that typically represents a NixOS system.

          You can read this path in a custom deployment tool for example.
        '';
      };
    };

  };


  config = {

    system.build.toplevel = system;

  };

}
