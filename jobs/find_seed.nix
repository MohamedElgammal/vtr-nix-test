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
in
listToAttrs (
  (map (seed: {
    name = "seed_${toString seed}";
    value = (make_regression_tests {
      vtr = vtr_dusty_sa;
      flags = { inherit seed; };
    }).vtr_reg_nightly.vtr_bidir.summary;
  }) (range 128 256)) ++
  (map (seed: {
    name = "seed_${toString seed}_baseline";
    value = (make_regression_tests {
      flags = { inherit seed; };
    }).vtr_reg_nightly.vtr_bidir.summary;
  }) (range 128 256)))

    
      
