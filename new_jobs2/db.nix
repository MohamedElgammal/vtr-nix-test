{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    titan_rl = titan_rl.summary;
    vtr_rl = vtr_rl.summary;
}
