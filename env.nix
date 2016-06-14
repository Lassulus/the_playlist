with import <nixpkgs> {}; {
  env = stdenv.mkDerivation {
    name = "playlist-tools";
    buildInputs = [
      ffmpeg
      parallel
      python35Packages.youtube-dl
      sox
      vorbisgain
      mpv
    ];
    SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt";
  };
}
