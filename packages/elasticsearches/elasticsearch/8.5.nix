{
  elk7Version,
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  jre_headless,
  util-linux,
  gnugrep,
  coreutils,
  autoPatchelfHook,
  zlib,
}:

with lib;
let
  info = splitString "-" stdenv.hostPlatform.system;
  arch = elemAt info 0;
  plat = elemAt info 1;
  shas = {
    x86_64-linux = "13apy368aizaxj6zp580r3jkgaknj6gib290lbmwah8vwdgd51j1";
    x86_64-darwin = "0n3zh8r1rzg7jac6xnrxr5330wnhl9pnjljqsqxymy4sh29sciy3";
    aarch64-linux = "1cfq7467sam5pvrx26lrfa5r9jic2s71g0fdlqmscmpmhw4ix8hs";
    aarch64-darwin = "17mwcjv9bv592brf511yaymlpwdiq0anf4ac4qqrrc5l8szbizan";
  };
in
stdenv.mkDerivation rec {
  pname = "elasticsearch";
  version = elk7Version;

  src = fetchurl {
    url = "https://artifacts.elastic.co/downloads/elasticsearch/${pname}-${version}-${plat}-${arch}.tar.gz";
    sha256 = shas.${stdenv.hostPlatform.system} or (throw "Unknown architecture");
  };

  patches = [ ./es-home-6.x.patch ];

  postPatch = ''
    substituteInPlace bin/elasticsearch-env --replace \
      "ES_CLASSPATH=\"\$ES_HOME/lib/*\"" \
      "ES_CLASSPATH=\"$out/lib/*\""

    substituteInPlace bin/elasticsearch-cli --replace \
      "ES_CLASSPATH=\"\$ES_CLASSPATH:\$ES_HOME/\$additional_classpath_directory/*\"" \
      "ES_CLASSPATH=\"\$ES_CLASSPATH:$out/\$additional_classpath_directory/*\""
  '';

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optional (!stdenv.hostPlatform.isDarwin) autoPatchelfHook;

  buildInputs = [
    jre_headless
    util-linux
    zlib
  ];

  runtimeDependencies = [ zlib ];

  installPhase = ''
    mkdir -p $out
    cp -R bin config lib modules plugins $out

    chmod +x $out/bin/*

    substituteInPlace $out/bin/elasticsearch \
      --replace 'bin/elasticsearch-keystore' "$out/bin/elasticsearch-keystore"

    wrapProgram $out/bin/elasticsearch \
      --prefix PATH : "${
        makeBinPath [
          util-linux
          coreutils
          gnugrep
        ]
      }" \
      --set JAVA_HOME "${jre_headless}"

    wrapProgram $out/bin/elasticsearch-plugin --set JAVA_HOME "${jre_headless}"
  '';

  passthru = {
    enableUnfree = true;
  };

  meta = {
    description = "Open Source, Distributed, RESTful Search Engine";
    license = licenses.elastic20;
    platforms = platforms.unix;
    maintainers = with maintainers; [
      apeschar
      basvandijk
    ];
  };
}
