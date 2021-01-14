{ ... }: # ignore arguments

with import ../library.nix {
  pkgs = import <nixpkgs> {};
  default_vtr_rev = "d4ea40548ee30aa13e27df5268760a86e38ad289";
}; # import default.nix, passing in nixpkgs

let vtr_node_reordering = vtrDerivation {
      variant = "node_reordering";
      url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
      ref = "node_reordering_flag";
      rev = "70cbb48d50458999dee0566b286182e8ed387f60";
    };
in
summariesOf {
  base = (make_regression_tests {}).vtr_reg_nightly.titan_quick_qor;
  node_reordering =
    let test = {flags, ...}:
          (make_regression_tests {
            vtr = vtr_node_reordering;
            inherit flags;
          }).vtr_reg_nightly.titan_quick_qor;
    in
      flag_sweep "node_reordering" test {
        reorder_rr_graph_nodes_algorithm = ["none" "degree_bfs" "random_shuffle"];
      };
}

    
      
