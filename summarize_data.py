import os
from os.path import join
import sys
import re
import pandas as pd

summary_file_name = 'data.feather'
results_file_name = 'parse_results.txt'

def process_data(root):
  df = pd.read_table(join(root, results_file_name), sep=' *\t *', engine='python')
  params = read_params(root, 'params')
  vtr_opts = read_params(root, 'vtr_opts')
  df['vtr_variant'] = vtr_opts['variant']
  df['task'] = params['task']
  df['run_id'] = params['run_id']
  df['path'] = root
  for f in params['flags'].split('--'):
    l = f.split(' ', 1)
    if(len(l) == 2):
      df[l[0].strip()] = l[1].strip()
  return df

def read_params(root, fn):
  data = {}
  with open(join(root, fn)) as f:
    for l in f.readlines():
      l = l.split(':', 1)
      if(len(l) < 2): continue
      data[l[0]] = l[1].strip()
  return data

out_dir = os.getenv('out')
os.mkdir(out_dir)
dfs = []
summary_out = join(out_dir, summary_file_name)
for root in sys.argv[1:]:
  files = os.listdir(root)
  if 'summary' in files:
    summary_path = join(root, 'summary', summary_file_name)
    if os.path.exists(summary_path):
      dfs += [pd.read_feather(summary_path)]
  else:
    if results_file_name in files:
      dfs += [process_data(root)]
if len(dfs) > 0:
  df = pd.concat(dfs, ignore_index=True, sort=False)
  df = df.replace(-1, pd.NA) # -1 is treated as a missing value
  df = df.convert_dtypes() # without this, may not be able to serialize missing values
  df.to_feather(summary_out)

nix_support = join(out_dir, 'nix-support')
os.mkdir(nix_support)
with open(join(nix_support, 'hydra-build-products'), 'w') as f:
  f.write('file feather {}\n'.format(summary_out))
