nixpkgs: final: prev: {
  opensearch_12 = prev.callPackage ./opensearch/1.2.nix { jre_headless = prev.jdk11_headless; };
  opensearch_13 = prev.callPackage ./opensearch/1.3.nix { jre_headless = prev.jdk11_headless; };
  opensearch_25 = prev.callPackage ./opensearch/2.5.nix { jre_headless = prev.jdk17_headless; };
  opensearch_212 = prev.callPackage ./opensearch/2.12.nix { };
  opensearch_219 = prev.callPackage ./opensearch/2.19.nix { };
}
