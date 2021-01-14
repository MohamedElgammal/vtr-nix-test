{ ... }: # ignore arguments

with import ../library.nix {
  pkgs = import <nixpkgs> {};
  default_vtr_rev = "461f8539372b36492d88e58a7b9675ebfe703760";
}; # import default.nix, passing in nixpkgs

let vtr_auto_high_fanout = vtrDerivation {
      variant = "auto_high_fanout";
      url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
      ref = "prevent_high_fanout_explosion";
      rev = "22ef4436b0961897b157f2e3aee54af3061d34f6";
    };
in
summariesOf {
  base = (make_regression_tests {}).vtr_reg_nightly.titan_quick_qor;
  auto_high_fanout =
    let test = {flags, ...}:
          (make_regression_tests {
            vtr = vtr_auto_high_fanout;
            inherit flags;
          }).vtr_reg_nightly.titan_quick_qor;
    in
      flag_sweep "auto_high_fanout" test {
        router_high_fanout_max_slope = ["-0.5" "-0.2" "-0.1"];
      };
}
