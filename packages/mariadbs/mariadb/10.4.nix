{ callPackage, darwin, openssl_1_1 }:

(callPackage ./generic.nix {
  # Supported until 2025-06-24
  version = "10.4.33";
  hash = "sha256-baTrg17iwimfWfgdSySpoVJNJdpswVbI0bny+rpZMIE=";
  openssl = openssl_1_1;
  inherit (darwin) cctools;
  inherit (darwin.apple_sdk.frameworks) CoreServices;
}).overrideAttrs (oldAttrs: {
  # > -- Looking for pcre_stack_guard in pcre - not found
  # > -- Performing Test PCRE_STACK_SIZE_OK
  # > -- Performing Test PCRE_STACK_SIZE_OK - Failed
  # > CMake Error at cmake/pcre.cmake:22 (MESSAGE):
  # >   system pcre is not found or unusable
  # > Call Stack (most recent call first):
  # >   CMakeLists.txt:387 (CHECK_PCRE)
  # Fix the above error by using the bundled pcre
  cmakeFlags = [
    "-DWITH_PCRE=bundled"
  ];
})
