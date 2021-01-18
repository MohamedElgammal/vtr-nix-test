{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_baseline = vtr_baseline.summary;
    vtr_rl = vtr_rl.summary;
    vtr_random = vtr_random.summary;
    titan_baseline = titan_baseline.summary;
    titan_rl = titan_rl.summary;
    titan_random = titan_random.summary;
}
