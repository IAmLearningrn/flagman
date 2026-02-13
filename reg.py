import re
import sys
res=sys.argv[1]
f=sys.argv[2]
regex = r"[ ]{3}[-]{1,2}[\S ]*([\n]{1}[ ]{3}[\S ]*)*"
matches = re.finditer(regex, res)
found=[]
for matchNum, match in enumerate(matches, start=1):
    g=match.group()
    if f in g:
      found.append(g)

if len(g) == 0:
    print("No Result")
else:
    for p in found:
        print(p)

