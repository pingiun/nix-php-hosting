{ coreutils
, fetchurl
, gnugrep
, jre_headless
, lib
, makeBinaryWrapper
, nixosTests
, stdenv
, stdenvNoCC
, version
, hashes
}:

let
  info = lib.splitString "-" stdenv.hostPlatform.system;
  nixArch = lib.elemAt info 0;
  plat = lib.elemAt info 1;
  arch = {
    "x86_64" = "x64";
    "aarch64" = "arm64";
  }.${nixArch};
in
stdenvNoCC.mkDerivation {
  pname = "opensearch";
  version = version;

  src = fetchurl {
    url = "https://artifacts.opensearch.org/releases/bundle/opensearch/${version}/opensearch-${version}-linux-${arch}.tar.gz";
    sha256 = hashes.${stdenv.hostPlatform.system};
  };

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  buildInputs = [
    jre_headless
  ];

  patches = lib.optional (lib.versionOlder version "2.12") [ ./opensearch-home-old.patch ];

    installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R bin config lib modules plugins $out

    substituteInPlace $out/bin/opensearch \
      --replace 'bin/opensearch-keystore' "$out/bin/opensearch-keystore"

    wrapProgram $out/bin/opensearch \
      --prefix PATH : "${lib.makeBinPath [ gnugrep coreutils ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}:$out/plugins/opensearch-knn/lib/" \
      --set JAVA_HOME "${jre_headless}"

    wrapProgram $out/bin/opensearch-plugin --set JAVA_HOME "${jre_headless}"

    rm $out/bin/opensearch-cli

    runHook postInstall
  '';

  passthru.tests = nixosTests.opensearch;

  meta = {
    description = "Open Source, Distributed, RESTful Search Engine";
    homepage = "https://github.com/opensearch-project/OpenSearch";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ shyim ];
    platforms = lib.platforms.unix;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
}
