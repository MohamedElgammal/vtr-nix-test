{ ... }: # ignore arguments

with import ../library.nix {
  default_vtr_rev = "b4f390a7d9ae9a566944a5dbb8d89cd2498a79f1";
  pkgs = import <nixpkgs> {}; # import default.nix, passing in nixpkgs
};

let
  regression_tests = make_regression_tests {};
in

# each attribute is a job
summariesOf {
  vtr_reg_basic = regression_tests.vtr_reg_basic;
  vtr_reg_strong = regression_tests.vtr_reg_strong;
  vtr_reg_nightly = regression_tests.vtr_reg_nightly;
  vtr_reg_weekly = regression_tests.vtr_reg_weekly;
}
