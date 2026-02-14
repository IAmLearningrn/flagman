import re
import sys
file=sys.argv[1]
flag=sys.argv[2]
regex = r"[ ]{3}[-]{1,2}[\S ]*([\n]{1}[ ]{3}[\S ]*)*"
data=open(file).read()
matches = re.finditer(regex, data)
found=[]
for matchNum, match in enumerate(matches, start=1):
    g=match.group()
    if flag in g:
      found.append(g)

if len(g) == 0:
    print("No Result")
else:
    for p in found:
        print(p)

