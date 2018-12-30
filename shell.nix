let
  opkgs = import <nixpkgs> {};
  nixWriters = builtins.fetchGit { url = "https://github.com/krebs/nix-writers"; rev = "f6b2139310546574942a1319cadab973b616d888"; };
  pkgs = import (builtins.fetchGit { url = "https://github.com/nixos/nixpkgs-channels"; ref = "ae002fe44e96b868c62581e8066d559ca2179e01"; }) { overlays = [(import "${nixWriters}/pkgs")]; };
  lib = pkgs.lib;

  commands.review = let
    moveToDir = key: dir: pkgs.writeText "move-with-${key}.lua" ''
      tmp_dir = "${dir}"

      function move_current_track_${key}()
        track = mp.get_property("path")
        os.execute("mkdir -p '" .. tmp_dir .. "'")
        os.execute("mv '" .. track .. "' '" .. tmp_dir .. "'")
        print("moved '" .. track .. "' to " .. tmp_dir)
      end

      mp.add_key_binding("${key}", "move_current_track_${key}", move_current_track_${key})
    '';

    delete = moveToDir "D" "./.graveyard";
    good = moveToDir "G" "./.good";

    #scripts = lib.concatStringsSep "," [
    #  delete
    #  good
    #];
  in pkgs.writers.writeDash "review" ''
    exec ${pkgs.mpv}/bin/mpv --no-config --script=${delete} --script=${good} "$@"
  '';

  # add_link
  # download new music from source
  # example: add_link
  commands.add_link = pkgs.writers.writeDash "commands.add_link" ''
    ${utils.prepare_stream} "$@"
  '';

  # get_new
  # download new music from source
  commands.pull = pkgs.writers.writeDash "commands.pull" ''
    set -euf
    ${common_header}
    echo "run1"
    ${utils.download_stream} || :
    echo "getting new links"
    cat "$meta_folder/source" | ${pkgs.findutils}/bin/xargs -n 1 ${utils.get_stream_links}
    echo "run2"
    ${utils.download_stream}
  '';

  utils.extract_playlist = pkgs.writers.writeDash "utils.extract_playlist" ''
    set -euf

    ${pkgs.youtube-dl}/bin/youtube-dl \
      -i -o "http://www.youtube.com/watch?v=%(id)s#%(title)s" \
      --restrict-filenames --get-filename $1
  '';

  commands.add_new = pkgs.writers.writeDash "commands.add_new" ''
    set -euf
    ${common_header}
    ${utils.log_untracked_files} | ${utils.get_links_from_files} >> $meta_folder/links
  '';

  common_header = ''
    target_folder=''${target_folder-./}
    meta_folder="$target_folder/.meta"

    mkdir -p $meta_folder
    touch "$meta_folder/links"
    touch "$meta_folder/finished"
    touch "$meta_folder/source"
  '';

  utils.files2links_prefix = pkgs.writers.writeDash "utils.files2links_prefix" ''
    ${pkgs.gnused}/bin/sed 's,.*\(.\{11\}\)\.ogg,http://www.youtube.com/watch?v=\1,'
  '';

  utils.links2files_suffix = pkgs.writers.writeDash "utils.links2files_suffix" ''
    ${pkgs.gnused}/bin/sed 's/.*v=\([^#]*\).*/\1.ogg/'
  '';

  utils.log_undownloaded_links = pkgs.writers.writeDash "utils.log_undownloaded_links" ''
    set -euf
    target_folder=''${target_folder-./}
    if ! test -e "$target_folder/.meta"; then
      echo "run in directory with .meta files"
      exit 23
    fi
    ${common_header}
    filter_downloaded_links="${pkgs.gnugrep}/bin/grep -v -e $(ls "$target_folder" | ${utils.files2links_prefix} | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/ -e /g')"
    cat "$meta_folder/links" | $filter_downloaded_links

  '';

  utils.log_untracked_files = pkgs.writers.writeDash "utils.log_untracked_files" ''
    set -euf
    target_folder=''${target_folder-./}
    if ! test -e "$target_folder/.meta"; then
      echo "run in directory with .meta files"
      exit 23
    fi
    ${common_header}
    filter_tracked_files="${pkgs.gnugrep}/bin/grep -v -e $(cat "$meta_folder/links" |${pkgs.gnused}/bin/sed 's/.*v=\([^#]*\).*/\1.ogg/' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/ -e /g')"
    ls | $filter_tracked_files
  '';

  utils.get_links_from_files = pkgs.writers.writeDash "utils.get_link_from_file" ''
    ${pkgs.gnused}/bin/sed 's,.*\(.\{11\}\)\.ogg,http://www.youtube.com/watch?v=\1,' | \
      ${pkgs.findutils}/bin/xargs -n 1 ${utils.extract_playlist}
  '';

  utils.prepare_stream = pkgs.writers.writeDash "utils.prepare_stream" ''
    set -euf
    ${common_header}
    echo "$@" | ${pkgs.gnugrep}/bin/grep -v -f "$meta_folder/source" >> "$meta_folder/source"
  '';

  utils.download_stream = pkgs.writers.writeDash "utils.download_stream" ''
    set -euf
    ${common_header}
    cd "$target_folder"
    new_links="$(cat "$meta_folder/links" | ${pkgs.gnugrep}/bin/grep -v -f "$meta_folder/finished" || :)"
    if test "$(echo "$new_links" | wc -l)" -gt 0; then
      echo "$new_links" | ${pkgs.findutils}/bin/xargs -n 1 ${utils.download_ogg} || :
    fi
  '';

  utils.get_stream_links = pkgs.writers.writeDash "utils.get_stream_links" ''
    set -euf
    ${common_header}
    ${utils.extract_playlist} "$1" | ${pkgs.gnugrep}/bin/grep -v -f "$meta_folder/links" | tee -a "$meta_folder/links"
  '';

  utils.download_ogg = pkgs.writers.writeDash "utils.download_ogg" ''
    set -xeuf
    ${common_header}

    if ! test "$#" -eq 1; then
      echo "wrong number of args"
    else
      if echo "$1.ogg" | ${pkgs.gnugrep}/bin/grep -qf "$meta_folder/finished"; then

        echo "already in finished: $1"
      fi
      id="$(echo "$1" | ${pkgs.gnused}/bin/sed 's@.*youtube.com/watch?v=\([^#]*\)#.*@\1@')"
      if ls "$target_folder" | ${pkgs.gnugrep}/bin/grep -Fe "$id.ogg"; then
        echo "file already exists: $1"
      else
        ${pkgs.youtube-dl}/bin/youtube-dl \
          -i -o "%(title)s-%(id)s.%(ext)s" \
          --restrict-filenames --add-metadata \
          --audio-format vorbis \
          -x "$1"
      fi


      echo "$1" >> "$target_folder/.meta/finished"
    fi

  '';

  shell.utilspkg = pkgs.write "shell.utilspkg" (lib.mapAttrs' (name: link:
    lib.nameValuePair "/bin/${name}" { inherit link; }
  ) utils);

  shell.cmdspkg = pkgs.write "shell.cmdspkg" (lib.mapAttrs' (name: link:
    lib.nameValuePair "/bin/${name}" { inherit link; }
  ) commands);

in pkgs.stdenv.mkDerivation {
  name = "youtube-tools";
  shellHook = /* sh */ ''
    export PATH=${lib.makeBinPath [
      shell.cmdspkg
      shell.utilspkg
      pkgs.which
      pkgs.coreutils
      pkgs.gnugrep
    ]}:$PATH
  '';
}
