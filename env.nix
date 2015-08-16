with import <nixpkgs> {}; {
  env = stdenv.mkDerivation {
    name = "playlist-tools";
    buildInputs = [
      sox
      pypyPackages.youtube-dl-light
      ffmpeg
      vorbisgain
    ];
    SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt";
  };
}
