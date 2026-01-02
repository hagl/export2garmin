{
  inputs = { utils.url = "github:numtide/flake-utils"; };
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python-with-deps = pkgs.python3.withPackages (ps: [
          ps.bleak
          ps.bluepy
          ps.garth
          ps.garminconnect
          ps.requests
          ps.xiaomi-ble
        ]);
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            procmail
            python-with-deps
            bashInteractive
            bc
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          # ... (pname, version, src are the same)
          name = "export2garmin";
          nativeBuildInputs = [ pkgs.makeWrapper ];
          src = ./.;
          buildInputs = with pkgs; [ python-with-deps ];
          meta = {
            mainProgram = "import_data.sh";
          };
          installPhase = ''
            mkdir -p $out/bin
            cp -r miscale $out/bin
            cp import_data.sh $out/bin/_import_data.sh
            printf "${pkgs.bashInteractive}/bin/bash $out/bin/_import_data.sh \$@" > $out/bin/import_data.sh
            chmod +x $out/bin/import_data.sh

            wrapProgram $out/bin/import_data.sh \
              --prefix PATH : ${
                with pkgs; lib.makeBinPath [
                  python-with-deps
                  procmail
                  bashInteractive
                  bc
                  coreutils
                  gnugrep
                  gawk
                  gnused
                  bluez
                ]
              }:$out/bin
          '';
        };
      });
}
