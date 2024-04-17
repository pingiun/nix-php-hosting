{ config, lib, pkgs, ... }:
{
  options = {
    projects = {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.string);
      default = {};
    };
  }
}
