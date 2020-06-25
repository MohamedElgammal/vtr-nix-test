# test runs
#
# configuration for make_regression_tests:
# flags: passed to vpr for each task
# vtr.variant: an identifier for a specific variant
# vtr.url: location of the VTR repo
# vtr.rev: git revision
# vtr.patches: list of patches to apply to VTR
{ pkgs ? import <nixpkgs> {}, ... }:

with pkgs;
with lib;
with import ./library.nix {
  inherit pkgs;

  # default VTR revision
  default_vtr_rev = "6428b63f06eccf5ead8c27158e22a46b0ad4cd19";
};

rec {
  # unmodified tests
  regression_tests = make_regression_tests {};

  vtr_dusty_sa = vtrDerivation {
    variant = "dusty_sa";
    url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
    ref = "dusty_sa";
    rev = "b46fd7d22f25fb0f787ce2e7217d44f4960aad6b";
  };

  vtr_node_reordering = vtrDerivation {
    variant = "node_reordering_flag";
    url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
    ref = "node_reordering_flag";
    rev = "7872c8f6cb32efb988138b50e3caf198bb2212ac";
  };

  vtr_node_reordering_may5 = vtrDerivation {
    variant = "node_reordering_flag_may5";
    url = "https://github.com/HackerFoo/vtr-verilog-to-routing.git";
    ref = "node_reordering_flag";
    rev = "fb381c011f3b83deb1c63275ee0b923ea9c8151c";
  };

  # a sweep over a few values of --inner_num
  dot_to_us = builtins.replaceStrings ["."] ["_"];
  make_inner_num_sweep = test_type: fn: values: builtins.listToAttrs (map (val: {
    name = "${test_type}_inner_num_${dot_to_us val}";
    value = (make_regression_tests (fn val)).${test_type};
  }) values);
  make_inner_num_sweep_comparison = test_type: values: opts: addAll "inner_num_sweep_${test_type}" {
    baseline = addAll "baseline" (make_inner_num_sweep test_type (val: { flags = "--inner_num ${val}"; } // opts) values);
    no_flag = addAll "no_flag" (make_inner_num_sweep test_type (val: { vtr = vtr_dusty_sa; flags = "--inner_num ${val}"; } // opts) values);
    with_flag = addAll "with_flag" (make_inner_num_sweep test_type (val: { vtr = vtr_dusty_sa; flags = "--alpha_min 0.2 --inner_num ${val}"; } // opts) values);
  };
  inner_num_sweep_weekly = make_inner_num_sweep_comparison "vtr_reg_weekly_no_he" ["0.5" "1.0" "2.0"] { };
  inner_num_sweep_nightly = make_inner_num_sweep_comparison "vtr_reg_nightly" ["0.125" "0.25" "0.5" "1.0" "2.0"] { run_id = "1"; };
  inner_num_sweep_nightly_2 = make_inner_num_sweep_comparison "vtr_reg_nightly" ["0.125" "0.25" "0.5" "1.0" "2.0"] { run_id = "2"; };
  inner_num_sweep_nightly_3 = make_inner_num_sweep_comparison "vtr_reg_nightly" ["0.125" "0.25" "0.5" "1.0" "2.0"] { run_id = "3"; };
  dusty_sa = make_regression_tests { vtr = vtr_dusty_sa; flags = "--alpha_min 0.2"; };
  inner_num_sweep_with_flag_high = addAll "with_flag" (make_inner_num_sweep "vtr_reg_nightly" (val: { run_id = "with_flag_high"; vtr = vtr_dusty_sa; flags = "--alpha_min 0.2 --inner_num ${val}"; }) ["4.0" "10.0"]);

  # flag_sweep :: root -> attrs -> ({root, flags} -> derivation) -> derivations
  flag_sweep = root: test: attrs:
    foldl (test: flag:
      {root, flags}:
      addAll root (listToAttrs (filter ({value, ...}: value != null) (map (value:
        let name = nameStr "${flag} ${toString value}"; in
        {
          inherit name;
          value = test {
            root = "${root}_${name}";
            flags = flags // { ${flag} = value; };
          };
        }) (getAttr flag attrs))))) test (attrNames attrs) { inherit root; flags = {}; };

  flags_to_string = attrs: foldl (flags: flag: "${flags} --${flag} ${toString (getAttr flag attrs)}") "" (attrNames attrs);

  dusty_sa_sweep =
    let test = {root, flags}:
          if flags.anneal_success_min >= flags.anneal_success_target then null else
          (make_regression_tests {
            vtr = vtr_dusty_sa;
            flags = flags_to_string flags;
          }).vtr_reg_nightly.titan_quick_qor.all;
    in
      flag_sweep "dusty_sa_sweep" test {
        alpha_min = [0.4 0.5 0.7 0.8];
        alpha_max = [0.9 0.95 0.99];
        alpha_decay = [0.7 0.6 0.5 0.4];
        anneal_success_target = [0.4 0.5 0.6];
        anneal_success_min = [0.1 0.15];
      };


  baseline_inner_num_sweep =
    let test = {flags, ...}:
          (make_regression_tests {
            flags = flags_to_string flags;
          }).vtr_reg_weekly.vtr_reg_titan.all;
    in
      flag_sweep "baseline_inner_num_sweep" test {
        inner_num = [0.25 0.5 1.0 2.0];
        seed = range 1 20;
    };

  dusty_sa_new_inner_num_sweep =
    let test = {flags, ...}:
          (make_regression_tests {
            vtr = vtr_dusty_sa;
            flags = flags_to_string (flags // {
              alpha_min = 0.8;
              alpha_max = 0.9;
              alpha_decay = 0.4;
              anneal_success_target = 0.6;
              anneal_success_min = 0.15;
            });
          }).vtr_reg_weekly.vtr_reg_titan.all;
    in
      flag_sweep "dusty_sa_new_inner_num_sweep" test {
        inner_num = [0.5 1 2 3 4];
        seed = range 1 10;
    };

  node_reordering =
    let test = {flags, ...}:
          (make_regression_tests {
            vtr = vtr_node_reordering_may5;
            flags = if flags.reorder_rr_graph_nodes_threshold == (-1)
                    then "" # default
                    else flags_to_string flags;
          }).vtr_reg_nightly.titan_quick_qor.all;
    in
      flag_sweep "node_reordering" test {
        reorder_rr_graph_nodes_threshold = [(-1) 1];
        reorder_rr_graph_nodes_algorithm = ["degree_bfs" "random_shuffle"];
      };

  various_seeds =
    let test = {flags, ...}:
          (make_regression_tests {
            flags = flags_to_string flags;
          }).vtr_reg_nightly.titan_quick_qor.stratixiv_arch.sparcT1_core_stratixiv_arch_timing.common;
    in
      flag_sweep "various_seeds" test {
        seed = range 1 960;
      };

  many_runs =
    let test = {flags, ...}:
          (make_regression_tests flags).vtr_reg_nightly.titan_quick_qor.stratixiv_arch.sparcT1_core_stratixiv_arch_timing.common;
    in
      flag_sweep "many_runs" test {
        run_id = range 1 960;
      };

  dusty_sa_no_flags =
    let test = {flags, ...}:
          (make_regression_tests {
            vtr = vtr_dusty_sa;
            flags = flags_to_string flags;
          }).vtr_reg_weekly.all;
    in
      flag_sweep "dusty_sa_no_flags" test {
        seed = range 1 20;
      };



  mohameds_test = attrs:
    make_regression_tests (attrs // {
      tests = {
        custom = {
          task = "mohameds_test/custom";
          qor_parse_file = "qor_large.txt";
          pass_requirements_file = "pass_requirements.txt";
          arch_list = ["k6_frac_N10_frac_chain_mem32K_40nm.xml"];
          circuit_list = ["bgm.v" "LU8PEEng.v" "LU32PEEng.v" "mcml.v"  "stereovision0.v" "stereovision1.v" "stereovision2.v"];
          archs_dir = "arch/timing";
          circuits_dir = "benchmarks/verilog";
          script_params = "-track_memory_usage --routing_failure_predictor off";
          parse_file = "vpr_standard.txt";
        };
      };
    });


  vtr_master = vtrDerivation {
    variant = "latest_master";
    url = "https://github.com/verilog-to-routing/vtr-verilog-to-routing.git";
    ref = "master";
    rev = "1b9065116a6939eea16204885d9d53997a646186";
  };
  
  vtr_exploration = vtrDerivation {
    variant = "rl_dm";
    url = "https://github.com/MohamedElgammal/exploration.git";
    ref = "rl_dm";
    rev = "67cfb5077276b30c11371b644958f7341bf261d8";
    #rev = "6ccca52e9a85f596387722c50d25281162c445f3";
  };
  
  
  master_baseline =
    let test = { flags, ...}: (mohameds_test {
          flags = "--pack --place ${flags_to_string flags}";
          vtr = vtr_master;
        }).custom;
    in
      flag_sweep "master_baseline" test {
        inner_num = [0.125 0.25 0.5 1 2];
        seed = range 1 3;
      };



  branch_baseline =
    let test = { flags, ...}: (mohameds_test {
          flags = "--simpleRL_agent_placement off --pack --place --place_dm_rlim 3  ${flags_to_string flags}";
          vtr = vtr_exploration;
        }).custom;
    in
      flag_sweep "branch_baseline" test {
        place_static_move_prob = ["10,10,10,10,10,10,10"];
        inner_num = [0.125 1];
        seed = range 1 2;
      };
      

  branch_rl =
    let test = { flags, ...}: (mohameds_test {
          flags = "--simpleRL_agent_placement on --pack --place  ${flags_to_string flags}";
          vtr = vtr_exploration;
        }).custom;
    in
      flag_sweep "branch_rl" test {
        #place_dm_rlim = [1 2 3 7 1000];
        #place_agent_gamma = [0.0001 0.001 0.01 0.05 0.1 0.5];
        #place_agent_epsilon = [0.1 0.2 0.3 0.4 0.5];
        #place_agent_algorithm = ["softmax" "e_greedy"];
        inner_num = [0.025];
        seed = range 1 2;
      };
      
   branch_rl_sweep =
     let test = { flags, ...}: (mohameds_test {
           flags = "--simpleRL_agent_placement on --pack --place --place_agent_epsilon 0.3 --place_agent_gamma 0.05 --place_agent_algorithm e_greedy --place_dm_rlim 3  ${flags_to_string flags}";
           vtr = vtr_exploration;
         }).custom;
     in
       flag_sweep "branch_rl" test {
         place_reward_num = [0 1 2 3];
         inner_num = [0.125 0.25 0.5 1 2];
         seed = range 1 3;
       };      



   branch_test =
    let test = { flags, ...}: (mohameds_test {
          flags = "--pack --place --place_dm_rlim 3  ${flags_to_string flags}";
          vtr = vtr_exploration;
        }).custom;
    in
      flag_sweep "branch_test" test {
        place_static_move_prob = ["100 0 0 0 0 0 0" "0 100 0 0 0 0 0" "50 50 0 0 0 0 0" "0 0 100 0 0 0 0" "50 0 50 0 0 0 0" "0 0 0 100 0 0 0" "50 0 0 50 0 0 0" "0 0 0 0 100 0 0" "50 0 0 0 50 0 0" "0 0 0 0 0 100 0" "50 0 0 0 0 50 0" "0 0 0 0 0 0 100" "50 0 0 0 0 0 50" "50 0 0 0 0 5 0" "50 0 0 0 0 0 5"];
        #place_static_move_prob = ["0 100 0 0 0 0 0" "50 50 0 0 0 0 0"];
        inner_num = [0.125 1.0];
        seed = range 1 3;
        place_timing_cost_func = [0 1];
      };

   titan_test =
    let test = {flags, ...}:
        (make_regression_tests {
            vtr = vtr_exploration;
            flags = "--pack --place --place_dm_rlim 3 --seed 1 ${flags_to_string flags}";
        }).vtr_reg_nightly.titan_quick_qor;
    in
      flag_sweep "titan_test" test {
        place_static_move_prob = ["100 0 0 0 0 0 0" "0 100 0 0 0 0 0" "50 50 0 0 0 0 0" "0 0 100 0 0 0 0" "50 0 50 0 0 0 0" "0 0 0 100 0 0 0" "50 0 0 50 0 0 0" "0 0 0 0 100 0 0" "50 0 0 0 50 0 0" "0 0 0 0 0 100 0" "50 0 0 0 0 50 0" "0 0 0 0 0 0 100" "50 0 0 0 0 0 50" "50 0 0 0 0 5 0" "50 0 0 0 0 0 5"];
        #place_static_move_prob = ["0 100 0 0 0 0 0" "50 50 0 0 0 0 0"];
        inner_num = [0.125  1.0];
        #seed = range 1 1;
        place_timing_cost_func = [0 1];
    };
}

