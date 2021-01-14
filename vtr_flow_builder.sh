source $stdenv/setup

shopt -s extglob
set -eo pipefail

ln -s $vtr_test_setup/* .
vtr_flow=$vtr_src/vtr_flow
task_dir=$vtr_flow/tasks/$task

if [ -e "$task_dir/config/golden_results.txt" ]; then
    expected_min_W=`python $get_param $task_dir/config/golden_results.txt $arch $circuit $script_params_name min_chan_width`
    expected_min_W=$((expected_min_W + expected_min_W % 2))
    if (($expected_min_W > 0)); then
        hint="--min_route_chan_width_hint $expected_min_W"
    fi
    expected_vpr_status=`python $get_param $task_dir/config/golden_results.txt $arch $circuit $script_params_name vpr_status`
    if [[ ( -n "$expected_vpr_status" ) && ( "$expected_vpr_status" != "success" ) ]]; then
        expect_fail="-expect_fail '$expected_vpr_status'"
    fi
fi

if [[ -n "$cmos_tech_behavior" ]]; then
    cmos_tech="-cmos_tech $vtr_flow/tech/$cmos_tech_behavior"
fi

# run the task
mkdir -p run
cd run

# copy files at root of $task_dir
for f in $task_dir/*; do
    if [[ -f "$f" ]]; then
        cp "$f" .
    fi
done

cat <<EOF > vtr_flow.sh
../vtr_flow/scripts/run_vtr_flow.py \
../vtr_flow/$circuits_dir/$circuit \
../vtr_flow/$archs_dir/$arch \
-temp_dir . \
-show_failures \
$script_params_common \
$script_params \
$cmos_tech \
$hint \
$expect_fail \
$flags
EOF

if [[ "$okay_to_fail" == "1" ]]; then
    bash vtr_flow.sh |& tee vtr_flow.out || true
else
    bash vtr_flow.sh |& tee vtr_flow.out
fi

# parse the results
if [ -n "$parse_file" ]; then
    python $vtr_flow/scripts/python_libs/vtr/parse_vtr_flow.py . $vtr_flow/parse/parse_config/$parse_file arch=$arch circuit=$circuit script_params=$script_params_name > parse_results.txt
fi
if [ -n "$qor_parse_file" ]; then
    python $vtr_flow/scripts/python_libs/vtr/parse_vtr_flow.py . $vtr_flow/parse/qor_config/$qor_parse_file > qor_results.txt
fi

# remove references
find . -type f -name '*.out' -print0 | xargs -0 sed -i \
  -e "s+$coreutils+\$coreutils+g" \
  -e "s+$titan_benchmarks+\$titan_benchmarks+g" \
  -e "s+$ispd_benchmarks+\$ispd_benchmarks+g"

# store the results
mkdir -p $out

if [ "$keep_all_files" != "1" ]; then
  # copy all but the largest files
  cp !(*.net|*.route|*.blif) $out
else
  cp * $out
fi

# record parameters
cat <<EOF > $out/params
task: $task
flags: $flags
run_id: $run_id
arch: $arch
circuit: $circuit
script_params_common: $script_params_common
script_params: $script_params
hint: $hint
EOF
cp "$vtr/opts" $out/vtr_opts

# make all files build products
mkdir -p $out/nix-support
find $out -type f -printf "file data %p\n" >> $out/nix-support/hydra-build-products
