import glob
import json
import os
import re

PAT = re.compile(r"^(?P<prefix>.+?)_(?P<suffix>[^.]+)\.json$")


def lexical_value(s: str) -> int:
    s = s.lower()
    total = 0
    for ch in s:
        # if not 'a' <= ch <= 'z':
        #     print(s)
        #     raise ValueError("only letters a–z allowed")
        total = total * 26 + (ord(ch) - ord('a') + 1)
    return total

priority = ["LP","MP","HP","LK","MK","HK","d_","cl_","f_","b_","db_","0","1","2","3","4","5","6","7","8","9","10","11","12","13 ","EXP","EXK"]
prio = {substring: i for i, substring in enumerate(priority)}

def sort_key(item):
    key, value = item
    score = 990
    if isinstance(value, dict):
        name = value.get("name", "")
        match_index = next((prio[substr] for substr in priority if substr in name), len(priority))
        if name in priority:
            score = match_index
        elif "d_" in name and len(name) <=4:
            score = 100 + match_index
        elif "cl_" in name and len(name) <=5:
            score = 200 + match_index
        elif "f_" in name and len(name) <=4:
            score = 300 + match_index
        elif "b_" in name and len(name) <=4:
            score = 400 + match_index
        elif "db_" in name and len(name) <=5:
            score = 500 + match_index
        elif "u_" in name and len(name) <=4:
            score = 600 + match_index
        elif "uf_" in name and len(name) <=5:
            score = 700 + match_index
        elif "ub_" in name and len(name) <=5:
            score = 800 + match_index
        elif "tc_" in name and len(name) <=9:
            score = 900 + match_index
            if "ext" in name:
                score = score + 1
        elif "throw_" in name:
            score = 1000 + match_index
        elif "uoh" in name:
            score = 1100 + match_index
        elif "pa" in name:
            score = 1200 + match_index
        else:
            m = re.match(r'(.+)_', name)
            if m:
                pre = m.group(1)
                pre = pre.replace("_","")
                pre = pre.replace("1","a")
                pre = pre.replace("2","b")
                pre = pre.replace("3","c")
                pre = pre.replace("4","d")
                score = 1300 + lexical_value(pre) + match_index
            else:
                score = 2000
        # print(name, score)

    else:
        match_index = len(priority) + 1
        group = 2
    return (score, key)

with open('fdm.txt', 'w') as fdm:
    fdm.write("")
for filepath in glob.glob("/home/epi/Scripts/3rd_training_effie/data/sfiii3nr1/framedata/*framedata.json"):
    fname = os.path.basename(filepath)
    match = PAT.match(fname)
    char = match.group("prefix")[1:]
    suffix = match.group("suffix")
    with open(filepath) as f:
        head = f"--{char}"
        print()
        print(head)
        with open('fdm.txt', 'a') as fdm:
            fdm.write(head+"\n")
        data = json.load(f)
        sorted_items = sorted(data.items(), key=sort_key)
        data = dict(sorted_items)
        for anim, frame_data in data.items():
            if isinstance(frame_data, dict):
                if (
                # not "u_" in frame_data["name"]
                # and not "uf_" in frame_data["name"]
                # and not "ub_" in frame_data["name"]
                "hit_frames" in frame_data
                and len(frame_data["hit_frames"]) > 0
                or char == "projectiles"):
                    comment = f"--{frame_data["name"]}"
                    line = ""
                    is_throw = False
                    if "throw" in frame_data["name"]:
                        line = f"frame_data_meta[\"{char}\"][\"{anim}\"] = {{ throw = true"
                        is_throw = True
                    else:
                        line = f"frame_data_meta[\"{char}\"][\"{anim}\"] = {{ hit_type = {{"
                    sep = ", "
                    defval = "3"
                    if "air" in frame_data["name"]:
                        defval = "3"
                    if "d_" in frame_data["name"]:
                        defval = "2"
                    if frame_data["name"] == "uoh":
                        defval = "4"

                    if not is_throw:
                        if not char == "projectiles":
                            line = line + sep.join([defval] * len(frame_data["hit_frames"]))
                        else:
                            line = line + defval
                    line = line + "}}"
                    template = "{:<80} {:<100}"
                    with open('fdm.txt', 'a') as fdm:
                        fdm.write(template.format(line, comment)+"\n")
                    print(template.format(line, comment))
        with open('fdm.txt', 'a') as fdm:
            fdm.write("\n")