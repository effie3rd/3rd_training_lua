import json
import subprocess
import os
import re
import time


cwd = os.path.dirname(os.path.realpath(__file__))
menu_dir = cwd + "/menu"

base_path = "images/menu/"
colors = {
    "white": "white"
    # "red": "#FF0000",
    # "green": "#00FF00",
    # "grey": "#999999"
    }
with open("../data/image_map.json") as f:
    data = json.load(f)
with open("../data/utf.json") as f:
    utf = json.load(f)


for color,color_code in colors.items():
    for char in utf["en"]:
        ucode = ord(char)
        key = f"utf_{ucode}"
        size = "5"
        filename = f"{key}_en_{size}_{color}"
        subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"en"], cwd=cwd)
        data.setdefault(key, {})
        data[key]["en"] = base_path + filename + ".png"

    for char in utf["jp"]:

        ucode = ord(char)
        key = f"utf_{ucode}"
        size = "10"
        filename = f"{key}_jp_{size}_{color}"
        subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp"], cwd=cwd)
        data.setdefault(key, {})
        data[key]["jp"] = base_path + filename + ".png"
 
        key = f"utf_{ucode}"
        size = "8"
        filename = f"{key}_jp_{size}_{color}"
        subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp"], cwd=cwd)
        data.setdefault(key, {})
        data[key]["jp_8"] = base_path + filename + ".png"

    for char in utf["jp_ext"]:
        ucode = ord(char)
        key = f"utf_{ucode}"
        size = "10"
        filename = f"{key}_jp_10_{color}"
        subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp_ext"], cwd=cwd)
        data.setdefault(key, {})
        data[key]["jp"] = base_path + filename + ".png"

        size = "8"
        filename = f"{key}_jp_8_{color}"
        subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp_8_ext"], cwd=cwd)
        data.setdefault(key, {})
        data[key]["jp_8"] = base_path + filename + ".png"



loc_files = ["../data/localization.json", "../data/localization_moves.json"]
to_stitch = []
to_remove = []

def all_processes_ended(processes):
    for process in processes:
        if process.poll() == None:
            return False
    return True

for loc_file in loc_files:
    with open(loc_file) as f:
        loc = json.load(f)

    for color,color_code in colors.items():
        for key,item in loc.items():
            for lang_code,text in item.items():
                #replace en chars in jp text with en font
                if lang_code == "jp":
                    size = "10"
                    lang = "jp"
                    parts = []
                    i = 0
                    parts.append({"text":"", "lang":""})
                    for c in text:
                        code = ord(c)
                        if code < 12288:
                            if parts[i]["lang"] == "jp":
                                i = i + 1
                                parts.append({"text":"", "lang":""})
                            parts[i]["lang"] = "en"
                        else:
                            if parts[i]["lang"] == "en":
                                i = i + 1
                                parts.append({"text":"", "lang":""})
                            parts[i]["lang"] = "jp"
                        parts[i]["text"] = parts[i]["text"] + c

                    processes = []
                    part_file_names = []
                    command = []


                    outfile = f"{key}_{lang}_{size}_{color}"

                    if len(parts) == 1:
                        char = parts[0]["text"]
                        lang = parts[0]["lang"]
                        if lang == "en":
                            size = "8"
                            filename = outfile #key_jp_10_white
                            part_file_names.append(filename + ".png")
                            command.append(filename + ".png")
                            subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp_ext"], cwd=cwd)
                        elif lang == "jp":
                            size = "10"
                            filename = outfile #key_jp_10_white
                            part_file_names.append(filename + ".png")
                            command.append(filename + ".png")
                            subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp"], cwd=cwd)
                    else:
                        for i, part in enumerate(parts):
                            char = part["text"]
                            lang = part["lang"]
                            process = None
                            if lang == "en":
                                size = "8"
                                filename = f"{key}_{lang}_{size}_{color}_{i}"
                                part_file_names.append(filename + ".png")
                                command.append(filename + ".png")
                                process = subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp_ext"], cwd=cwd)

                            elif lang == "jp":
                                size = "10"
                                filename = f"{key}_{lang}_{size}_{color}_{i}"
                                part_file_names.append(filename + ".png")
                                command.append(filename + ".png")
                                process = subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp"], cwd=cwd)

                            processes.append(process)
                        command.append("+append")
                        command.append(f"png32:{outfile}.png")
                        to_stitch.append({"processes":processes, "command":command, "files":part_file_names.copy()})

                    data.setdefault(key, {})
                    data[key].setdefault(lang_code, {})
                    data[key][lang_code] = base_path + outfile + ".png"
                elif lang_code == "jp_8":
                    size = "8"
                    lang = "jp"
                    filename = f"{key}_{lang}_{size}_{color}"
                    subprocess.Popen(["bash", "./text_to_image.sh",text,filename,size,color_code,"jp"], cwd=cwd)
                    data.setdefault(key, {})
                    data[key].setdefault(lang, {})
                    data[key][lang] = base_path + filename + ".png"
                elif lang_code == "jp_ext":
                    size = "8"
                    lang = "jp"
                    filename = f"{key}_{lang}_{size}_{color}"
                    subprocess.Popen(["bash", "./text_to_image.sh",text,filename,size,color_code,"jp_ext"], cwd=cwd)
                    data.setdefault(key, {})
                    data[key].setdefault(lang, {})
                    data[key][lang] = base_path + filename + ".png"
                elif lang_code == "en":
                    size = "5"
                    lang = "en"
                    filename = f"{key}_{lang}_{size}_{color}"
                    subprocess.Popen(["bash", "./text_to_image.sh",text,filename,size,color_code,"en"], cwd=cwd)
                    data.setdefault(key, {})
                    data[key].setdefault(lang, {})
                    data[key][lang] = base_path + filename + ".png"


#stitch
while len(to_stitch) > 0:
    for i,stitch in enumerate(to_stitch):
        if all_processes_ended(stitch["processes"]):
            p = subprocess.Popen(["magick"] + stitch["command"], cwd=menu_dir)
            to_remove.append({"processes":{p}, "files":stitch["files"]})
            to_stitch.pop(i)
    time.sleep(.001)

#remove
while len(to_remove) > 0:
    for i,remove in enumerate(to_remove):
        if all_processes_ended(remove["processes"]):
            for file_name in remove["files"]:
                subprocess.Popen(["rm", file_name], cwd=menu_dir)
            to_remove.pop(i)
    time.sleep(.001)

#copy exceptions
subprocess.Popen(["cp \"./exceptions/\"* ./menu"], cwd=cwd, shell=True)

top = []
bottom = []
for k, v in sorted(data.items()):
    if k.startswith("utf_"):
        code = int(k[4:])
        top.append((k, v, code))
    else:
        bottom.append((k, v))

top.sort(key=lambda t: t[2])
top = [(k, v) for k, v, _ in top]
data = dict(top + bottom)

with open("../data/image_map.json", "w", encoding='utf8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2, separators=(',', ': '))
