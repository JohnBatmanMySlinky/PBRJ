import sys
import re
import json
import numpy as np

if len(sys.argv) != 3:
	assert False

f1 = sys.argv[1]
f2 = sys.argv[2]

with open(f1, "r") as f:
	julia = f.readlines()

with open(f2, "r") as f:
	cpp = f.readlines()

ROUND = 5

def convert_a(s):
	tmp = []
	for each in s.split(","):
		tmp += [round(eval(each.strip()), ROUND)]
	return tmp

def convert_b(s):
	tmp = []
	for each in s.split(", "):
		tmp += [eval(each)]
	return tmp

j_results = []
for j_line in julia:
	if "FIN:" in j_line:
		a, b = j_line.split("@")
		a = re.findall(r"\[(.*)\]", a)[0].strip()
		a = convert_a(a)
		b = re.findall(r"\[(.*)\]", b)[0].strip()
		b = convert_b(b)
		j_results += [(b, a)]
j_results.sort()


c_results = []
for c_line in cpp:
	if "FIN:" in c_line:
		a, b = c_line.split("@")
		a = re.findall(r"\[(.*)\]", a)[0].strip().replace("0,", "0.0,")
		if a.endswith(", 0"):
			a += ".0"
		a = convert_a(a)

		b = re.findall(r"\[(.*)\]", b)[0].strip()
		b = convert_b(b)
		c_results += [(b, a)]
c_results.sort()

JLL = min([x for (x,y),z in j_results])
JLU = max([x for (x,y),z in j_results])
JRL = min([y for (x,y),z in j_results])
JRU = max([y for (x,y),z in j_results])
CLL = min([x for (x,y),z in c_results])
CLU = max([x for (x,y),z in c_results])
CRL = min([y for (x,y),z in c_results])
CRU = max([y for (x,y),z in c_results])

LL = min(JLL, CLL)
LU = min(JLU, CLU)
RL = min(JRL, CRL)
RU = min(JRU, CRU)

j_dict = {(x,y):z for (x,y),z in j_results}
c_dict = {(x,y):z for (x,y),z in c_results}
results = {}
for x in range(LL, LU+1):
	for y in range(RL, RU+1):
		j = j_dict.get((x,y), "NOPE")
		c = c_dict.get((x,y), "NOPE")
		if (j != "NOPE") & (c != "NOPE"):
			d = [abs(a-b) for a,b in zip(j, c)]
		else:
			d = "NOPE"
		results[f"{x}, {y}"] = {
			"J": j_dict.get((x,y), "NOPE"),
			"C": c_dict.get((x,y), "NOPE"),
			"D": d
		}

urg = [[k,v] for k,v in results.items() if v["D"] != "NOPE"]
urg.sort(key = lambda x: max(x[1]["D"]))
urg.reverse()
agh = [[k,v] for k,v in results.items() if v["D"] == "NOPE"]
print(f"There are {len(agh)} NOPES")
fin = urg + agh

max_errors = [max(v["D"]) for k,v in urg]
for p in [0, 25, 50, 75, 90, 100]:
	print(f"Abs error {p}th percentile: {np.percentile(max_errors, q=p):.5}")
print(f"{len([x for x in max_errors if x < 1e-6])/len(urg):.2%} percent of pixels are the SAME")
print(f"Abs error mean: {sum(max_errors)/len(max_errors):.5}")
print(f"Abs error mean | there is an error: {sum([x for x in max_errors if x >= 1e-6])/len([x for x in max_errors if x >= 1e-6]):.5}")


with open("RESULTS.txt", "w") as f:
	json.dump(fin, f, indent=1)

print("DONE")