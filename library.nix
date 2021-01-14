{ pkgs ? <nixpkgs> {},
  default_vtr_rev,
  ... }:

with pkgs;
with lib;

let # build custom versions of Python with the packages we need
  python_packages = p: with p; [
    pip
    virtualenv
    lxml
    python-utils
  ];
  python27 = pkgs.python27.withPackages python_packages;
  python3 = pkgs.python3.withPackages python_packages;
in
rec {
  inherit lib;

  # build and install binaries and vtr_flow
  vtrDerivation = { url ? "https://github.com/verilog-to-routing/vtr-verilog-to-routing.git", # git repo
                    variant ? "verilog-to-routing", # identifier
                    ref ? "master", # git ref
                    rev ? default_vtr_rev, # specific revision
                    patches ? [] # any patches to apply
                  }: stdenv.mkDerivation {
                    name = "vtr-${variant}-${rev}";
                    buildInputs = [ # dependencies
                      bison
                      flex
                      cmake
                      tbb
                      xorg.libX11
                      xorg.libXft
                      fontconfig
                      cairo
                      pkgconfig
                      gtk3
                      clang-tools
                      gperftools
                      perl
                      python27
                      python3
                      time
                      pcre
                      harfbuzz
                      xorg.libpthreadstubs
                      xorg.libXdmcp
                      mount
                      coreutils
                    ];
                    src = fetchGit { # get the source using git
                      url = url;
                      ref = ref;
                      rev = rev;
                    };
                    patches = [ ./install_abc.patch ] ++ patches;
                    postInstall = ''
            echo "variant: ${variant}" > $out/opts
            echo "url:     ${url}"    >> $out/opts
            echo "ref:     ${ref}"    >> $out/opts
            echo "rev:     ${rev}"    >> $out/opts
          '';
                    enableParallelBuilding = true;
                  };

  # download benchmarks
  benchmarkDerivation = attrs: stdenv.mkDerivation ({ # common base for benchmark derivations
    buildInputs = [ coreutils gnutar gzip ];
    builder = "${bash}/bin/bash";
    args = [ ./benchmarks_builder.sh ];
  } // attrs);
  titan_benchmarks = benchmarkDerivation rec {
    name = "titan_benchmarks-${version}";
    version = "1.3.1";
    tarball = fetchurl {
      url = "https://storage.googleapis.com/verilog-to-routing/titan/titan_release_1.3.1.tar.gz";
      sha512 = "4beace8286817ecb0abe3cee509fc84f61fe96eafc6cbfe484faa873221677dff50e642e848a89d9e2882da6229b7415253bd3a988b546947ab7ae1a676feaef";
    };
  };
  ispd_benchmarks = benchmarkDerivation rec { # common base for VTR tasks
    name = "ispd_benchmarks-${version}";
    version = "0.0.1";
    tarball = fetchurl {
      url = "https://storage.googleapis.com/verilog-to-routing/ispd/ispd_benchmarks_vtr_v0.0.1.tar.gz";
      sha512 = "215cac150507dedcb4050747940d6f3bd5925432a7c93afe35440438cb77e070be49765e0dd427380b37ac1efc279136fc344e34394c55af32b4db3ffdf6fda7";
    };
  };

  vtr_test_python = python3.withPackages (p: with p; [ pandas prettytable ]);

  vtr_test_setup = vtr: stdenv.mkDerivation {
    name = "vtr_test_setup";
    buildInputs = [ time coreutils perl vtr_test_python ];
    inherit titan_benchmarks ispd_benchmarks coreutils vtr;
    vtr_src = vtr.src;
    builder = "${bash}/bin/bash";
    args = [ ./vtr_test_setup_builder.sh ];
  };

  vtr_test_setup_default = vtr_test_setup (vtrDerivation {});

  # list of tasks to run (config.txt) with run_vtr_task
  # opts.flags: flags passed tp vpr
  # opts.
  pathToName = builtins.replaceStrings ["/"] ["_"];
  vtrFlowDerivation = cfg @ { flags ? "",
                              run_id ? "default",
                              vtr ? vtrDerivation {},
                              keep_all_files ? false,
                              okay_to_fail ? false,
                              name, ... }:
                                stdenv.mkDerivation (
                                  cfg // {
                                    buildInputs = [ time coreutils perl vtr_test_python valgrind ];
                                    vtr_test_setup = vtr_test_setup vtr;
                                    vtr_src = vtr.src;
                                    get_param = ./get_param.py;
                                    inherit coreutils vtr;
                                    builder = "${bash}/bin/bash";
                                    args = [ ./vtr_flow_builder.sh ];
                                    requiredSystemFeatures = [ "benchmark" ]; # only run these on benchmark machines
                                    meta = {
                                      timeout = 259200; # 3 days
                                      maxSilent = 259200; # 3 days
                                    };
                                    flags = if builtins.isAttrs flags then flags_to_string flags else flags;
                                    #nativeBuildInputs = [ breakpointHook ]; # debug
                                  });

  flags_to_string = attrs: foldl (flags: flag: "${flags} --${flag} ${toString (getAttr flag attrs)}") "" (attrNames attrs);
  removeExtension = str: builtins.head (builtins.match "([^\.]*).*" str);
  nameStr = builtins.replaceStrings [" " "/" "." "," ":"] ["_" "_" "_" "_" "_"];
  vtrTaskDerivations = root: cfg @ { arch_list, circuit_list, script_params_list ? [""],
                                     script_params ? "", script_params_common ? script_params, ... }:
                                       listToAttrs (map (arch:
                                         let arch_name = removeExtension arch; in
                                         {
                                           name = nameStr arch_name;
                                           value = addAll "${root}_${arch_name}" (listToAttrs (map (circuit:
                                             let circuit_name = removeExtension circuit; in
                                             {
                                               name = nameStr circuit_name;
                                               value = addAll "${root}_${arch_name}_${circuit_name}" (listToAttrs (map (script_params:
                                                 let script_params_name = if stringLength script_params == 0
                                                                          then "common"
                                                                          else "common_" + (builtins.replaceStrings [" "] ["_"] script_params); in
                                                   {
                                                     name = nameStr script_params_name;
                                                     value = vtrFlowDerivation (removeAttrs cfg ["arch_list" "circuit_list" "script_params_list"] // {
                                                       name = nameStr "${root}_${arch_name}_${circuit_name}_${script_params_name}";
                                                       inherit arch circuit script_params script_params_name script_params_common;
                                                     });
                                                   }) script_params_list));
                                             }) circuit_list));
                                         }) arch_list);

  # adds an .all derivation that links to all the other derivations in the set
  getAll = val: if isAttrs val && !(val ? out) then val.all else val;
  addAll = root: tests:
    let f = name: val: {
          name = name;
          path = getAll val;
        };
    in
      tests // rec {
        summary = mkSummary (nameStr root) (map (name: getAll (getAttr name tests)) (attrNames tests));
        all = linkFarm "${nameStr root}_all" ((mapAttrsToList f tests) ++ [{ name = "summary"; path = summary; }]);
      };

  mkTests = root: attrs: opts:
    if attrs ? task
    then
      vtrTaskDerivations root (attrs // opts // { name = root; })
    else
      let attrToTests = name: value: addAll root (mkTests "${root}_${name}" value opts);
      in builtins.mapAttrs attrToTests attrs;

  traceVal = val: builtins.trace (builtins.toJSON val) val;

  toString = x:
    with builtins;
    if isString x
    then x
    else
      assert isInt x || isFloat x;
      toJSON x;

  localDerivation = attrs: derivation ({
    system = builtins.currentSystem;
    preferLocalBuild = true; # these take a long time if run remotely
  } // attrs);

  mkSummary = root: drvs: localDerivation rec {
    name = "${root}_summary";
    python = python3.withPackages (p: with p; [ pandas pyarrow ]);
    builder = "${python}/bin/python";
    args = [ ./summarize_data.py ] ++ (map (drv: drv.out) drvs);
  };

  vtr_tests = vtr: localDerivation rec {
    name = "vtr_tests";
    python = python3.withPackages (p: with p; [ pandas ]);
    builder = "${python}/bin/python";
    args = [ ./convert_tests.py "${vtr.src}/vtr_flow/tasks/regression_tests" ];
  };

  # make a custom set of regression tests
  make_regression_tests = opts@{ vtr ? vtrDerivation {},
                                 tests ? (import (vtr_tests vtr)).regression_tests,
                                 ... }:
    addAll "regression_tests" (mkTests "regression_tests" tests (removeAttrs opts [ "tests" ]));

  summariesOf = mapAttrs (name: value: { of = value; } // value.summary);

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

}
