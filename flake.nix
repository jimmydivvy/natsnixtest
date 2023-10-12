{
  description = "A simple Go package";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      #version = builtins.substring 0 8 self.lastModifiedDate;
      version = "2.10.2";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          # The default package for 'nix build'. This makes sense if the
          # flake provides only one package or there is a clear "main"
          # package.
          xfoobar = pkgs.buildGoModule {
            pname = "xfoobar";
            inherit version;
            # In 'nix develop', we don't need a copy of the source tree
            # in the Nix store.
            #src = ./.;
            src = pkgs.fetchFromGitHub {
                owner = "nats-io";
                repo = "nats-server";
                rev = "v${version}";

                hash = "sha256-99U6z7ncUSu49ozPU2Fc1jDxZyn5C2fE7EeTwGF76WQ=";

                #hash = pkgs.lib.fakeSha256;
                # hash = "sha256-Gjw1dRrgM8D3G7v6WIM2+50r4HmTXvx0Xxme2fH9TlQ=";
                # hash = "sha256-KQr0DtyH3xzlFwsDl3MGLRRLQC4+EtdTOG7IhmNCzV4=";
                #hash = "sha256-99U6z7ncUSu49ozPU2Fc1jDxZyn5C2fE7EeTwGF76WQ=";
            };

            vendorHash = "sha256-T9dwNDbse59abetKx0wXuzFSXTx+5CaMpf0H9/Z40kE=";

            doCheck = false;
            postInstall = ''
                mv $out/bin/nats-server $out/bin/natsnix2x
            '';

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake sha256 and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remeber to bump this hash when your dependencies change.
            #vendorSha256 = pkgs.lib.fakeSha256;

            #vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";

            #vendorSha256 = pkgs.lib.fakeSha256;
          };
        });


        # Add dependencies that are only needed for development
      devShells = forAllSystems (system:
        let 
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls gotools go-tools ];
          };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.xfoobar);
    };
}
