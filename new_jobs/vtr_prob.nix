{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_prob = vtr_prob.summary;
    titan_prob = titan_prob.summary;
}
