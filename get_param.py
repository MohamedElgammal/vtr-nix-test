import sys
import pandas as pd

arch = sys.argv[2]
circuit = sys.argv[3]
script_params = sys.argv[4]
query = sys.argv[5]

df = pd.read_table(sys.argv[1], sep=' *\t *', engine='python')
df = df.rename({'+arch': 'arch'}, axis=1) # vtr_reg_strong.strong_soft_multipliers requires this

if query in df:
    df = df[(df.arch == arch) & (df.circuit == circuit)]
    if 'script_params' in df:
        df = df[df.script_params == script_params]

    values = df[query].values;
    if len(values) > 0:
        print(values[0])
