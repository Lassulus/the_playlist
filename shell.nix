with import <stockholm>; {
  env = pkgs.stdenv.mkDerivation {
    name = "playlist-tools";
    buildInputs = with pkgs; [
      ffmpeg
      parallel
      youtube-dl
      sox
      vorbisgain
      mpv
    ];
    SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt";
    shellHook = ''
      PATH=$PATH:${./bin}
    '';
  };
}
