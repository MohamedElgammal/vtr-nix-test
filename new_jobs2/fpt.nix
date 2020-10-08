{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_test_fpt = vtr_test_fpt.summary;
    vtr_merge_fpt = vtr_merge_fpt.summary;
    vtr_prob_fpt = vtr_prob_fpt.summary;
}
