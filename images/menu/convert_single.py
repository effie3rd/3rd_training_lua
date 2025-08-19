import json
import subprocess
import os

cwd = os.path.dirname(os.path.realpath(__file__))
base_path = "images/menu/"
colors = {
    "white": "white"
    # "red": "#FF0000",
    # "green": "#00FF00",
    # "grey": "#999999"
    }
# with open("image_map.json") as f:
#     data = json.load(f)

for color,color_code in colors.items():
    # char = "P1+P2Pー１２３４５６７８９−賢者の石off"
    char = "0123456789０P１＋P２感情３４５６７８９"
    for c in char:
        print(ord(c))
    print(ord("("))
    # fragments = []
    # i = 0
    # lang = ""
    # text = ""
    # for c in char:
    #     _code = ord(c)
    #     if _code < 12288:
    #         if lang == "jp":
    #             i = i + 1
    #     elif _code <= 40879:
#jp
    size = "10"
    ucode = "test"
    filename = f"{ucode}_jp_{color}"
    subprocess.Popen(["bash", "./text_to_image.sh",char,filename,size,color_code,"jp"], cwd=cwd)
    # data["code"].setdefault(ucode, {})
    # data["code"][ucode][color] = base_path + filename + ".png"
    # data["code"][ucode]["char"] = char

# data = dict(sorted(data.items()))
# for k,v in data["code"].items():
#     data["code"][k] = {"char": data["code"][k].pop("char"), **data["code"][k]}
#     data["code"][k] = {"char": data["code"][k].pop("char"), **data["code"][k]}
# data = {"en":data.pop("en"), "jp": data.pop("jp"), "jp_ext": data.pop("jp_ext"), **data}
#
# with open("image_map.json", "w", encoding='utf8') as f:
#     json.dump(data, f, ensure_ascii=False, indent=2, separators=(',', ': '))
