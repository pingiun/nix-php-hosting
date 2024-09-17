{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let

  cfg = filterAttrs (n: f: f.enable) config.project.file;

  homeDirectory = config.project.homeDirectory;

  fileType = (import lib/file-type.nix { inherit homeDirectory lib pkgs; }).fileType;

  make-project-files = pkgs.rustPlatform.buildRustPackage {
    pname = "make-project-files";
    version = "0.1.0";
    src = ../../helpers/make-project-files;
    cargoSha256 = "sha256-mGUl18r5kBzxNgwpzGc7ndc72liLyMAufK8vCiir4Bw=";
  };

  replace-project-files = pkgs.rustPlatform.buildRustPackage {
    pname = "replace-project-files";
    version = "0.1.0";
    src = ../../helpers/replace-project-files;
    cargoSha256 = "sha256-BHA0Y3tS1Ep7qqFI/eoiLfeMW6aILQJsbgNam/JT644=";
  };

in

{
  options = {
    project.file = mkOption {
      description = "Attribute set of files to link into the user home.";
      default = { };
      type = fileType "project.file" "{env}`HOME`" homeDirectory;
    };

    project-files = mkOption {
      type = types.package;
      internal = true;
      description = "Package to contain all project files";
    };
  };

  config = {
    assertions = [
      (
        let
          dups = attrNames (
            filterAttrs (n: v: v > 1) (
              foldAttrs (acc: v: acc + v) 0 (mapAttrsToList (n: v: { ${v.target} = 1; }) cfg)
            )
          );
          dupsStr = concatStringsSep ", " dups;
        in
        {
          assertion = dups == [ ];
          message = ''
            Conflicting managed target files: ${dupsStr}

            This may happen, for example, if you have a configuration similar to

                project.file = {
                  conflict1 = { source = ./foo.nix; target = "baz"; };
                  conflict2 = { source = ./bar.nix; target = "baz"; };
                }
          '';
        }
      )
    ];

    system.activationScripts.linkGeneration = ''
      ${replace-project-files}/bin/replace-project-files $oldGenPath/project-files $projectConfig/project-files $HOME
    '';

    # This activation script will
    #
    # 1. Remove files from the old generation that are not in the new
    #    generation.
    #
    # 2. Switch over the Home Manager gcroot and current profile
    #    links.
    #
    # 3. Symlink files from the new generation into $HOME.
    #
    # This order is needed to ensure that we always know which links
    # belong to which generation. Specifically, if we're moving from
    # generation A to generation B having sets of home file links FA
    # and FB, respectively then cleaning before linking produces state
    # transitions similar to
    #
    #      FA   →   FA ∩ FB   →   (FA ∩ FB) ∪ FB = FB
    #
    # and a failure during the intermediate state FA ∩ FB will not
    # result in lost links because this set of links are in both the
    # source and target generation.
    # system.activationScripts.linkGeneration = (
    #   let
    #     link = pkgs.writeShellScript "link" ''
    #       ${homeManagerLib}

    #       newGenFiles="$1"
    #       shift
    #       for sourcePath in "$@" ; do
    #         relativePath="''${sourcePath#$newGenFiles/}"
    #         targetPath="$HOME/$relativePath"
    #         if [[ -e "$targetPath" && ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
    #           # The target exists, back it up
    #           backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
    #           run mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Moving '$targetPath' failed!"
    #         fi

    #         if [[ -e "$targetPath" && ! -L "$targetPath" ]] && cmp -s "$sourcePath" "$targetPath" ; then
    #           # The target exists but is identical – don't do anything.
    #           verboseEcho "Skipping '$targetPath' as it is identical to '$sourcePath'"
    #         else
    #           # Place that symlink, --force
    #           # This can still fail if the target is a directory, in which case we bail out.
    #           run mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
    #           run ln -Tsf $VERBOSE_ARG "$sourcePath" "$targetPath" || exit 1
    #         fi
    #       done
    #     '';

    #     cleanup = pkgs.writeShellScript "cleanup" ''
    #       ${homeManagerLib}

    #       # A symbolic link whose target path matches this pattern will be
    #       # considered part of a Home Manager generation.
    #       homeFilePattern="$(readlink -e ${escapeShellArg builtins.storeDir})/*-project-files/*"

    #       newGenFiles="$1"
    #       shift 1
    #       for relativePath in "$@" ; do
    #         targetPath="$HOME/$relativePath"
    #         if [[ -e "$newGenFiles/$relativePath" ]] ; then
    #           verboseEcho "Checking $targetPath: exists"
    #         elif [[ ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
    #           warnEcho "Path '$targetPath' does not link into a Home Manager generation. Skipping delete."
    #         else
    #           verboseEcho "Checking $targetPath: gone (deleting)"
    #           run rm $VERBOSE_ARG "$targetPath"

    #           # Recursively delete empty parent directories.
    #           targetDir="$(dirname "$relativePath")"
    #           if [[ "$targetDir" != "." ]] ; then
    #             pushd "$HOME" > /dev/null

    #             # Call rmdir with a relative path excluding $HOME.
    #             # Otherwise, it might try to delete $HOME and exit
    #             # with a permission error.
    #             run rmdir $VERBOSE_ARG \
    #                 -p --ignore-fail-on-non-empty \
    #                 "$targetDir"

    #             popd > /dev/null
    #           fi
    #         fi
    #       done
    #     '';
    #   in
    #   ''
    #     function linkNewGen() {
    #       _i "Creating home file links in %s" "$HOME"

    #       local newGenFiles
    #       newGenFiles="$(readlink -e "$newGenPath/project-files")"
    #       find "$newGenFiles" \( -type f -or -type l \) \
    #         -exec bash ${link} "$newGenFiles" {} +
    #     }

    #     function cleanOldGen() {
    #       if [[ ! -v oldGenPath || ! -e "$oldGenPath/project-files" ]] ; then
    #         return
    #       fi

    #       _i "Cleaning up orphan links from %s" "$HOME"

    #       local newGenFiles oldGenFiles
    #       newGenFiles="$(readlink -e "$newGenPath/project-files")"
    #       oldGenFiles="$(readlink -e "$oldGenPath/project-files")"

    #       # Apply the cleanup script on each leaf in the old
    #       # generation. The find command below will print the
    #       # relative path of the entry.
    #       find "$oldGenFiles" '(' -type f -or -type l ')' -printf '%P\0' \
    #         | xargs -0 bash ${cleanup} "$newGenFiles"
    #     }

    #     cleanOldGen

    #     if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]] ; then
    #       _i "Creating profile generation %s" $newGenNum
    #       if [[ -e "$genProfilePath"/manifest.json ]] ; then
    #         # Remove all packages from "$genProfilePath"
    #         # `nix profile remove '.*' --profile "$genProfilePath"` was not working, so here is a workaround:
    #         nix profile list --profile "$genProfilePath" \
    #           | cut -d ' ' -f 4 \
    #           | xargs -rt $DRY_RUN_CMD nix profile remove $VERBOSE_ARG --profile "$genProfilePath"
    #         run nix profile install $VERBOSE_ARG --profile "$genProfilePath" "$newGenPath"
    #       else
    #         run nix-env $VERBOSE_ARG --profile "$genProfilePath" --set "$newGenPath"
    #       fi

    #       # run --quiet nix-store --realise "$newGenPath" --add-root "$newGenGcPath" --indirect
    #       if [[ -e "$legacyGenGcPath" ]]; then
    #         run rm $VERBOSE_ARG "$legacyGenGcPath"
    #       fi
    #     else
    #       _i "No change so reusing latest profile generation %s" "$oldGenNum"
    #     fi

    #     linkNewGen
    #   ''
    # );

    # Symlink directories and files that have the right execute bit.
    # Copy files that need their execute bit changed.
    # project-files = pkgs.runCommandLocal "project-files" { } ''
    #   exec ${make-project-files}/bin/make-project-files '${builtins.toJSON (mapAttrsToList (name: f: {
    #     target = f.target;
    #     source = "${f.source}";
    #     executable = f.executable;
    #   }) cfg)}' $out
    # '';

    project-files = builtins.derivation {
      name = "project-files";
      builder = "${make-project-files}/bin/make-project-files";
      system = pkgs.stdenv.buildPlatform.system;
      args = [
        "${builtins.toJSON (
          mapAttrsToList (name: f: {
            target = f.target;
            source = "${f.source}";
            executable = f.executable;
          }) cfg
        )}"
      ];
    };
  };
}
