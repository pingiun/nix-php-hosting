# generate the script used to activate the configuration.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  addAttributeName = mapAttrs (
    a: v:
    v
    // {
      text = ''
        #### Activation script snippet ${a}:
        _localstatus=0
        ${v.text}

        if (( _localstatus > 0 )); then
          printf "Activation script snippet '%s' failed (%s)\n" "${a}" "$_localstatus"
        fi
      '';
    }
  );

  systemActivationScript =
    set: onlyDry:
    let
      set' = mapAttrs (
        _: v: if isString v then (noDepEntry v) // { supportsDryActivation = false; } else v
      ) set;
      withHeadlines = addAttributeName set';
      # When building a dry activation script, this replaces all activation scripts
      # that do not support dry mode with a comment that does nothing. Filtering these
      # activation scripts out so they don't get generated into the dry activation script
      # does not work because when an activation script that supports dry mode depends on
      # an activation script that does not, the dependency cannot be resolved and the eval
      # fails.
      withDrySnippets = mapAttrs (
        a: v:
        if onlyDry && !v.supportsDryActivation then
          v // { text = "#### Activation script snippet ${a} does not support dry activation."; }
        else
          v
      ) withHeadlines;
    in
    ''
      #!${pkgs.runtimeShell}

      projectConfig='@out@'

      export PATH=/empty
      for i in ${toString path}; do
          PATH=$PATH:$i/bin:$i/sbin
      done

      _status=0
      trap "_status=1 _localstatus=\$?" ERR

      # Ensure a consistent umask.
      umask 0022

      ${textClosureMap id (withDrySnippets) (attrNames withDrySnippets)}

    ''
    + optionalString (!onlyDry) ''
      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $projectConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$projectConfig")" /run/user/$UID/current-project

      exit $_status
    '';

  path =
    with pkgs;
    map getBin [
      coreutils
      gnugrep
      findutils
      getent
      shadow
      nettools # needed for hostname
    ];

  scriptType =
    withDry:
    with types;
    let
      scriptOptions =
        {
          deps = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "List of dependencies. The script will run after these.";
          };
          text = mkOption {
            type = types.lines;
            description = "The content of the script.";
          };
        }
        // optionalAttrs withDry {
          supportsDryActivation = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether this activation script supports being dry-activated.
              These activation scripts will also be executed on dry-activate
              activations with the environment variable
              `NIXOS_ACTION` being set to `dry-activate`.
              it's important that these activation scripts  don't
              modify anything about the system when the variable is set.
            '';
          };
        };
    in
    either str (submodule {
      options = scriptOptions;
    });

in

{

  ###### interface

  options = {

    system.activationScripts = mkOption {
      default = { };

      example = literalExpression ''
        { text =
          '''
            mkdir $HOME/.config
          ''';
        }
      '';

      description = ''
        A set of shell script fragments that are executed when the project is activated
      '';

      type = types.attrsOf (scriptType true);
      apply = set: set // { script = systemActivationScript set false; };
    };

    system.dryActivationScript = mkOption {
      description = "The shell script that is to be run when dry-activating the project.";
      readOnly = true;
      internal = true;
      default = systemActivationScript (removeAttrs config.system.activationScripts [ "script" ]) true;
      defaultText = literalMD "generated activation script";
    };
  };
}
