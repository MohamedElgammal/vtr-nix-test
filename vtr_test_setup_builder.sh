source $stdenv/setup

set -euo pipefail

link_blif_and_sdc() {
    src="$1"
    dst="$2"
    mkdir -p "$dst"
    for i in ${src}; do
        dir=`dirname $i`
        base=`basename $i .blif`
        cp -fs ${dir}/${base}.blif ${dst}/${base}.blif
        cp -fs ${dir}/../sdc/vpr.sdc ${dst}/${base}.sdc
    done
}

# build a lightweight copy of resources needed
# use symlinks when possible
mkdir $out
cd $out
vtr_flow=$vtr_src/vtr_flow

mkdir vpr
mkdir ODIN_II

mkdir -p vtr_flow/scripts
cp -nrs $vtr_flow/* vtr_flow/

cp -s $vtr/bin/vpr vpr
cp -s $vtr_src/vpr/*.supp vpr
cp -s $vtr/bin/odin_II ODIN_II
cp -rs $vtr_src/abc .
cp -rs $vtr_src/ace2 .
chmod -R +w .
cp -fs $vtr/bin/abc abc/abc
cp -fs $vtr/bin/ace ace2/ace

#patchShebangs vtr_flow/scripts

# no /usr/bin/env, so replace with absolute path from coreutils
sed -i "s+/usr/bin/env+$coreutils/bin/env+g" \
  vtr_flow/scripts/*.{py,pl} \
  ace2/scripts/extract_clk_from_blif.py

# copy arch, blifs, and sdcs
for i in $titan_benchmarks/titan_release_*/arch/stratixiv*.xml; do
    dst=vtr_flow/arch/`basename $i`
    mkdir -p $(dirname $dst)
    cp -f $i $dst
    chmod +w $dst
    python vtr_flow/scripts/upgrade_arch.py $dst &> /dev/null
    chmod -w $dst
done

link_blif_and_sdc "$titan_benchmarks/titan_release_*/benchmarks/titan23/*/*/*.blif" vtr_flow/benchmarks/titan_blif
link_blif_and_sdc "$titan_benchmarks/titan_release_*/benchmarks/other_benchmarks/*/*/*.blif" vtr_flow/benchmarks/titan_other_blif
cp -s $ispd_benchmarks/ispd_benchmarks_*/benchmarks/*/*.blif vtr_flow/benchmarks/ispd_blif

chmod -R -w .
