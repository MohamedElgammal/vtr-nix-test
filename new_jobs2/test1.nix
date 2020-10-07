{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_master_test = vtr_master_test.summary;
    titan_master_test = titan_master_test.summary;
    vtr_test_1 = vtr_test_1.summary;
    titan_test_1 = titan_test_1.summary;
    vtr_prob_test = vtr_prob_test.summary;
    titan_prob_test = titan_prob_test.summary;
}
