import os
import sys
import re

def process_task_list(root, out):
    with open(os.path.join(root, "task_list.txt")) as f:
        for l in f.readlines():
            process_task(l.strip(), out)

def process_task(task_name, out):
    out.write("  " + task_name.replace("/", ".") + " = {\n")
    task = {}
    task["task"] = task_name
    with open(os.path.join(task_name, "config", "config.txt")) as f:
        for l in f.readlines():
            l = l.split("#", 1)[0] # remove comments
            xs = l.split("=", 1)
            if len(xs) == 2:
                lhs = xs[0].strip()
                rhs = xs[1].strip().replace("../", "./") # prevent breaking out of the current directory
                if lhs.endswith("_list_add"):
                    lhs = lhs[:-4] # remove "_add"
                    if lhs not in task:
                        task[lhs] = []
                    task[lhs] += [rhs]
                else:
                    task[lhs] = rhs
    for key, val in task.items():
        if isinstance(val, list):
            out.write("    {} = [''{}''];\n".format(key, "'' ''".join(val)))
        else:
            out.write("    {} = ''{}'';\n".format(key, val))
    out.write("  };\n")

os.chdir(sys.argv[1])
os.chdir('..')
with open(os.getenv('out'), 'w+') as out:
    out.write("{\n")
    for root, dirs, files in os.walk(sys.argv[1]):
        if "task_list.txt" in files:
            dirs = []
            process_task_list(root, out)
    out.write("}\n")
