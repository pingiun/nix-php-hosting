{ elk7Version
, lib
, stdenv
, fetchurl
, makeWrapper
, jre_headless
, util-linux
, gnugrep
, coreutils
, autoPatchelfHook
, zlib
}:

with lib;
let
  info = splitString "-" stdenv.hostPlatform.system;
  arch = elemAt info 0;
  plat = elemAt info 1;
  shas =
    {
      x86_64-linux   = "13apy368aizaxj6zp580r3jkgaknj6gib290lbmwah8vwdgd51j1";
      x86_64-darwin  = "0yp2zjhvpnfb6an81w96v638lpr7qzq958sp7p4q2jnx1a1a9b3k";
      aarch64-linux  = "09lcighnvbadx5vwnf2flf6kchqpzkcv1kw4fp3149rw6rzxhiw7";
      aarch64-darwin = "0riq8314ln1vdc4jvraqrkxq6py9gimfxm39qzbjlnqc56f5mmki";
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

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional (!stdenv.hostPlatform.isDarwin) autoPatchelfHook;

  buildInputs = [ jre_headless util-linux zlib ];

  runtimeDependencies = [ zlib ];

  installPhase = ''
    mkdir -p $out
    cp -R bin config lib modules plugins $out

    chmod +x $out/bin/*

    substituteInPlace $out/bin/elasticsearch \
      --replace 'bin/elasticsearch-keystore' "$out/bin/elasticsearch-keystore"

    wrapProgram $out/bin/elasticsearch \
      --prefix PATH : "${makeBinPath [ util-linux coreutils gnugrep ]}" \
      --set JAVA_HOME "${jre_headless}"

    wrapProgram $out/bin/elasticsearch-plugin --set JAVA_HOME "${jre_headless}"
  '';

  passthru = { enableUnfree = true; };

  meta = {
    description = "Open Source, Distributed, RESTful Search Engine";
    license = licenses.elastic20;
    platforms = platforms.unix;
    maintainers = with maintainers; [ apeschar basvandijk ];
  };
}
