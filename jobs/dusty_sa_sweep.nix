{ ... }: # ignore arguments

with import ../library.nix {
  pkgs = import <nixpkgs> {};
  default_vtr_rev = "6428b63f06eccf5ead8c27158e22a46b0ad4cd19";
};

let vtr_dusty_sa = vtrDerivation {
      variant = "dusty_sa";
      url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
      ref = "dusty_sa";
      rev = "b46fd7d22f25fb0f787ce2e7217d44f4960aad6b";
    };
in
summariesOf {
  base = (make_regression_tests {}).vtr_reg_nightly.titan_quick_qor;
  dusty_sa_sweep =
    let test = {root, flags}:
          if flags.anneal_success_min >= flags.anneal_success_target then null else
            (make_regression_tests {
              vtr = vtr_dusty_sa;
              inherit flags;
            }).vtr_reg_nightly.titan_quick_qor;
    in
      flag_sweep "dusty_sa_sweep" test {
        alpha_min = [0.7 0.8 0.85];
        alpha_max = [0.86 0.9];
        alpha_decay = [0.55 0.5 0.45 0.4];
        anneal_success_target = [0.5 0.55 0.6 0.65];
        anneal_success_min = [0.1 0.15];
      };
}
