Using Nix to run VTR tests
==========================

#### Install Nix on your machine

`curl -L https://nixos.org/nix/install | sh`

#### Create some NixOS instances

Create an image

```shell
gcloud compute images create nixos-18091228-a4c4cbb613c-x86-64-linux --source-uri gs://nixos-cloud-images/nixos-image-18.09.1228.a4c4cbb613c-x86_64-linux.raw.tar.gz
```

Create instances with that image and at least a 2TB SSD and an external IP.

Update the included `configuration.nix` and then for each instance:

```shell
gcloud compute scp configuration.nix root@<machine>:/etc/nixos/configuration.nix
gcloud compute ssh root@<machine> -- nixos-rebuild switch

nix ping-store --store ssh://<machine> # shouldn't print anything
```

#### LET'S DO SOME TESTS

```shell
mkdir out
nix build -f . tests.regression_tests.vtr_reg_strong.all -j0 --builders "ssh://<ip> - - <jobs> ; ...<for each ip>"
```

If you'd like to see all the output:

```shell
nix-build -A tests.regression_tests.vtr_reg_strong.all -j0 --builders "ssh://<ip> - - <jobs> ; ...<for each ip>"
```

#### Creating a new test

Add a top level attribute to `tests.nix`, with sub-attributes for what you want to run using `make_regression_tests`.

See the top of that file for configuration options passed to `make_regression_tests`. You can select sub-tests by appending `.<test name>`.

You can use `nix repl` to explore:

```
~/src/vtr-nix-test$ nix repl
Welcome to Nix version 2.4. Type :? for help.

nix-repl> :l
Added 20 variables.

nix-repl> tests.<TAB>
tests.default_vtr_rev                  tests.dusty_sa_sweep                   tests.inner_num_sweep_nightly_2        tests.make_inner_num_sweep             tests.vtr_dusty_sa
tests.dot_to_us                        tests.flag_sweep                       tests.inner_num_sweep_nightly_3        tests.make_inner_num_sweep_comparison  tests.vtr_node_reordering
tests.dusty_sa                         tests.flags_to_string                  tests.inner_num_sweep_weekly           tests.node_reordering
tests.dusty_sa_new_inner_num_sweep     tests.inner_num_sweep_nightly          tests.inner_num_sweep_with_flag_high   tests.regression_tests
```
