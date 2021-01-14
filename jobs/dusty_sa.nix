{
  pkgs ? import <nixpkgs> {}
}:

with import ../library.nix {
  inherit pkgs;
  default_vtr_rev = "0a6ce4d388ecee8aa6564307df71c3a5c26107ec";
};

with pkgs.lib;

let
  vtr_dusty_sa = vtrDerivation {
    variant = "dusty_sa";
    url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
    ref = "dusty_sa";
    rev = "c12ab323885b6fdbe3d55adf086a59f2ce04587d";
  };
  dusty_sa_flags = {
    alpha_min = 0.8;
    alpha_max = 0.9;
    alpha_decay = 0.4;
    anneal_success_target = 0.6;
    anneal_success_min = 0.18;
  };
in
summariesOf {
  no_flag_regression_tests = make_regression_tests {
    vtr = vtr_dusty_sa;
  };
  with_flags_titan = (make_regression_tests {
    vtr = vtr_dusty_sa;
    flags = dusty_sa_flags;
  }).vtr_reg_nightly.titan_quick_qor;
  no_flag_regression_seeds = let
    test = { flags, ... }:
      (make_regression_tests {
        vtr = vtr_dusty_sa;
        inherit flags;
      }).vtr_reg_nightly;
  in
    flag_sweep "no_flag_regression_seeds" test {
      seed = range 32 64;
    };
  no_flag_regression_seeds_bitcoin = let
    test = { flags, ... }:
      (make_regression_tests {
        vtr = vtr_dusty_sa;
        inherit flags;
      }).vtr_reg_nightly.titan_quick_qor.stratixiv_arch.bitcoin_miner_stratixiv_arch_timing;
  in
    flag_sweep "no_flag_regression_seeds_bitcoin" test {
      seed = range 128 256;
    };
  no_flag_regression_seeds_vtr_bidir = let
    test = { flags, ... }:
      (make_regression_tests {
        vtr = vtr_dusty_sa;
        inherit flags;
      }).vtr_reg_nightly.vtr_bidir;
  in
    flag_sweep "no_flag_regression_seeds_vtr_bidir" test {
      seed = range 128 256;
    };
}

    
      
