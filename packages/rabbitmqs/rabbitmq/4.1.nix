{
  callPackage,
  AppKit,
  Carbon,
  Cocoa,
  erlang,
  elixir,
}:
callPackage ./generic.nix {
  version = "4.1.1";
  hash = "sha256-eIoa8ZwnVNhV+6yQOT5LqfhgvT1TfYaPIgSyVkV5HFI=";
  inherit
    AppKit
    Carbon
    Cocoa
    erlang
    elixir
    ;
}
