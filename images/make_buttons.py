import json
import subprocess
import os

cwd = os.path.dirname(os.path.realpath(__file__))
cwd = cwd + "/controller/"
def clamp(val, minimum=0, maximum=255):
    if val < minimum:
        return minimum
    if val > maximum:
        return maximum
    return val

def colorscale(hexstr, scalefactor):
    """
    Scales a hex string by ``scalefactor``. Returns scaled hex string.

    To darken the color, use a float value between 0 and 1.
    To brighten the color, use a float value greater than 1.

    >>> colorscale("#DF3C3C", .5)
    #6F1E1E
    >>> colorscale("#52D24F", 1.6)
    #83FF7E
    >>> colorscale("#4F75D2", 1)
    #4F75D2
    """

    hexstr = hexstr.strip('#')

    if scalefactor < 0 or len(hexstr) != 6:
        return hexstr

    r, g, b = int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:], 16)

    r = int(clamp(r * scalefactor))
    g = int(clamp(g * scalefactor))
    b = int(clamp(b * scalefactor))

    return "#%02x%02x%02x" % (r, g, b)

prefix = "buttons_"

buttons = ["LP","MP","HP","LK","MK","HK"]
styles ={
    "hyper_reflector" : ["#ec4899", "#ec4899", "#ec4899", "#9333ea", "#9333ea", "#9333ea"],
    "rose" : ["#ff66b3", "#ff0080", "#890045", "#ff66b3", "#ff0080", "#890045"],
    "cherry" : ["#93121c", "#7f151d", "#5b0f14", "#93121c", "#7f151d", "#5b0f14"],
    "blueberry" : ["#2c678d", "#2e4b7d", "#2c244e", "#2c678d", "#2e4b7d", "#2c244e"],
    "sky" : ["#66a3ea", "#378aea", "#006deb", "#66a3ea", "#378aea", "#006deb"],
    "blood_orange" : ["#bf5233", "#ab412c", "#8d2e23", "#bf5233", "#ab412c", "#8d2e23"],
    "salmon" : ["#f39d94", "#f98071", "#ec7263", "#f39d94", "#f98071", "#ec7263"],
    "grape" : ["#570095", "#420071", "#36015b", "#570095", "#420071", "#36015b"],
    "lavender" : ["#dcd0f8", "#bfaeef", "#a18ede", "#dcd0f8", "#bfaeef", "#a18ede"],
    "lemon" : ["#fbd871", "#eec459", "#daaf4f", "#fbd871", "#eec459", "#daaf4f"],
    "champagne" : ["#f6e6ce", "#f5debb", "#eed2a5", "#f6e6ce", "#f5debb", "#eed2a5"],
    "matcha" : ["#2b772a", "#185316", "#144319", "#2b772a", "#185316", "#144319"],
    "lime" : ["#2bf541", "#21bb47", "#1ba33e", "#2bf541", "#21bb47", "#1ba33e"],
    "retro_scifi" : ["#add79c", "#3c9691", "#324b6e", "#8a1f52", "#4d2e69", "#531750"],
    "watermelon" : ["#db6161", "#c43d3d", "#ac2525", "#75b855", "#298940", "#157241"],
    "macaron" : ["#fee97f", "#a3da69", "#8db1ec", "#edb05f", "#e85c7d", "#ac8ef3"],
    "famicom" : ["#008b52", "#0050ad", "#9491c6", "#f7ba0b", "#c1121c", "#6859af"],
    "van_gogh" : ["#bec075", "#c2a500", "#382b26", "#4b73a7", "#233c8e", "#1f2f51"],
    "munch" : ["#e35321", "#f6a800", "#f28d01", "#265171", "#233c50", "#143a47"],
    "hokusai" : ["#d4d2c2", "#c0bb9e", "#c19661", "#75a39b", "#2a5774", "#001c5b"],
    "monet" : ["#7a7d9e", "#3e76b1", "#d4946e", "#1e4566", "#3a5c66", "#d25058"],
    "dali" : ["#d9d3b3", "#3097c0", "#5f84aa", "#db7d1b", "#a7381a", "#441e0b"],
    "classic" : ["#ffd300", "#ff7108", "#c80d0d", "#ffd300", "#ff7108", "#c80d0d"],
    "2077" : ["#fdf500", "#46d4de", "#f237c2", "#fdf500", "#46d4de", "#f237c2"],
    "aurora" : ["#00eeac", "#00cbad", "#1f82a7", "#7f28b9", "#562a84", "#4d379d"],
    "ursa_major" : ["#7084ff", "#702686", "#512475", "#13b8ce", "#069bbb", "#065977"],
    "pillars_of_creation" : ["#319cbe", "#2b4f77", "#b27b9f", "#f4c261", "#d09354", "#521014"],
    "sunset" : ["#f8a93d", "#df6553", "#ce445a", "#962660", "#5a0e67", "#3917c0"],
    "fly_by_night" : ["#afbccd", "#819cba", "#65779d", "#6b69a6", "#514f81", "#433e76"],
    "lake" : ["#2185b6", "#08445c", "#195c32", "#2d6479", "#122d42", "#034f42"],
    "traffic_lights" : ["#49ceb3", "#44c9eb", "#40dd56", "#f7e664", "#f57448", "#dd3a38"],
    "warm_rainbow" : ["#f6dcac", "#faaa68", "#f65625", "#55b1bc", "#028393", "#0a3a82"],
    "soft_rainbow" : ["#fed48b", "#91b67a", "#427b7f", "#fa9452", "#f55553", "#713b73"],
    "pearl" : ["#eed3d0", "#d4c6d9", "#9ac6d4", "#74c1ee", "#699cc2", "#867fa5"],
    "beach" : ["#e6d996", "#d6b782", "#d6ae69", "#6ab0c3", "#3685a1", "#173bb7"],
    "nether" : ["#b4d07c", "#6db588", "#137d73", "#203562", "#6d4179", "#312d6b"],
    "blue_planet" : ["#7ed8fa", "#50b6fe", "#2197fa", "#94adfd", "#8e92ee", "#7f82d5"],
    "poison" : ["#3e9e58", "#27886a", "#18676e", "#473382", "#412374", "#3a1358"],
    "moon" : ["#9ba9ab", "#7c8893", "#5d687c", "#444a65", "#30324d", "#26203a"],
    "blood_moon" : ["#edc0c0", "#a28e8e", "#504545", "#911226", "#740c1c", "#4e0a1a"],
    "volcano" : ["#fd724e", "#a02f40", "#69223a", "#382d43", "#352641", "#261b2e"],
    "desert_sun" : ["#fb9c32", "#e44c1d", "#cf3122", "#313b9a", "#6f3799", "#503f89"],
    "canyon" : ["#a9d4f6", "#6391dc", "#6b8cc2", "#e188a8", "#db5381", "#825389"],
    "acid" : ["#fcf660", "#b2d942", "#52c33f", "#166e7a", "#254d70", "#252446"],
    "dawn" : ["#ffb48f", "#ef9d7f", "#cc8c83", "#adc0de", "#9aabc9", "#8797b5"],
    "picnic" : ["#96bbdb", "#5e6ea0", "#3e3c65", "#fffbd9", "#e3d8bb", "#b1725b"],
    "gelato" : ["#5e4a71", "#ce9358", "#ac546a", "#ddcc99", "#7bac62", "#526d88"],
    "patrick" : ["#f38f80", "#a9d055", "#674892", "#f38f80", "#a9d055", "#674892"],
    "01" : ["#8f5ec9", "#5348b0", "#a1db70", "#8f5ec9", "#5348b0", "#a1db70"]
    }

def get_brightness(hexstr):
    hexstr = hexstr.strip('#')

    if len(hexstr) != 6:
        return 0

    r, g, b = int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:], 16)
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    return luma


print('{' + ', '.join(f'"{x}"' for x in list(styles.keys())) + '}')


for name, colors in styles.items():
    for i, color in enumerate(colors):
        text_color = "#000000"
        if get_brightness(color) <= 40:
            text_color = "#CCCCCC"
            print(name, get_brightness(color))

        if i <= 2:
            subprocess.Popen(f"magick P_button_base_s.png -fill '{colorscale(color,.8)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' -fill '{text_color}' -opaque '#FF0000' png32:{buttons[i]}_s_{name}.png", cwd=cwd, shell=True)
        else:
            subprocess.Popen(f"magick K_button_base_s.png -fill '{colorscale(color,.8)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' -fill '{text_color}' -opaque '#FF0000' png32:{buttons[i]}_s_{name}.png", cwd=cwd, shell=True)
        subprocess.Popen(f"magick button_base_b.png -fill '{colorscale(color,.1)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' png32:{buttons[i]}_b_{name}.png", cwd=cwd, shell=True)
