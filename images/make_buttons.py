import json
import math
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
    "hyper_reflector" : ["#ffffff", "#ef499c", "#9431ef", "#ffffff", "#ef499c", "#9431ef"],
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
    "01" : ["#8f5ec9", "#5348b0", "#a1db70", "#8f5ec9", "#5348b0", "#a1db70"],
    "dungeon" : ["#6adce2", "#ffeaac", "#bd3434", "#6adce2", "#ffeaac", "#bd3434"],
    "skeleton" : ["#f4ecd2", "#c7facd", "#47b6e4", "#f4ecd2", "#c7facd", "#47b6e4"],
    "beholder" : ["#fae4b9", "#cd2561", "#6f2583", "#fae4b9", "#cd2561", "#6f2583"],
    "cthulu" : ["#ffe78a", "#207d6d", "#4c094e", "#ffe78a", "#207d6d", "#4c094e"],
    "ghost" : ["#fff3f3", "#a17cf1", "#2c2c2a", "#fff3f3", "#a17cf1", "#2c2c2a"],
    "shroom" : ["#f5f5cd", "#e97c44", "#97d355", "#f5f5cd", "#e97c44", "#97d355"],
    "totem" : ["#adcb96", "#e86363", "#75285f", "#adcb96", "#e86363", "#75285f"],
    "dream_tree" : ["#65f4f4", "#f779f3", "#7c45e8", "#65f4f4", "#f779f3", "#7c45e8"],
    "neon" : ["#47f7b5", "#2646ed", "#ff5ef2", "#47f7b5", "#2646ed", "#ff5ef2"],
    "windbreaker" : ["#fe6ecd", "#48cedf", "#5c017e", "#fe6ecd", "#48cedf", "#5c017e"],
    "curiosity" : ["#05b9be", "#ff6973", "#5c519c", "#05b9be", "#ff6973", "#5c519c"],
    "shock" : ["#d2fdf3", "#52f59a", "#7a39bb", "#d2fdf3", "#52f59a", "#7a39bb"],
    "signal" : ["#f823c6", "#6b1cb4", "#160eec", "#f823c6", "#6b1cb4", "#160eec"],
    "berry_nebula" : ["#6ceded", "#cc2aa7", "#6320b3", "#6ceded", "#cc2aa7", "#6320b3"],
    "toxic" : ["#f5f518", "#6dfb62", "#1b1a1d", "#f5f518", "#6dfb62", "#1b1a1d"],
    "citrine" : ["#fcf66a", "#51c34b", "#286cb3", "#fcf66a", "#51c34b", "#286cb3"],
    "voltage" : ["#f5d689", "#eba254", "#2f729e", "#f5d689", "#eba254", "#2f729e"],
    "chill" : ["#dde0bd", "#61b8ae", "#6971a5", "#dde0bd", "#61b8ae", "#6971a5"],
    "neapolitan" : ["#ffefb8", "#ee6284", "#8c6253", "#ffefb8", "#ee6284", "#8c6253"],
    "candy_castle" : ["#ee6284", "#6ce9c4", "#ffcb4d", "#ee6284", "#6ce9c4", "#ffcb4d"],
    "concord" : ["#436cae", "#a63060", "#48457a", "#436cae", "#a63060", "#48457a"],
    "cyber_gum" : ["#ffd8ba", "#0b7475", "#bc4a9b", "#ffd8ba", "#0b7475", "#bc4a9b"],
    "powder" : ["#fcb1c8", "#f7ffae", "#96fbc7", "#fcb1c8", "#f7ffae", "#96fbc7"],
    "fluffy" : ["#ffecf0", "#ffc4cf", "#c1c3f3", "#ffecf0", "#ffc4cf", "#c1c3f3"],
    "matsuri" : ["#ff732e", "#c22f1f", "#392c42", "#ff732e", "#c22f1f", "#392c42"],
    "joker" : ["#eddddd", "#ef2837", "#1b1a1d", "#eddddd", "#ef2837", "#1b1a1d"],
    "koi" : ["#f3e8d8", "#f2533d", "#2f256b", "#f3e8d8", "#f2533d", "#2f256b"],
    "pale_sunset" : ["#f7ba90", "#ee8695", "#4a89ad", "#f7ba90", "#ee8695", "#4a89ad"],
    "mars" : ["#fadea5", "#fa6b4b", "#ba0502", "#fadea5", "#fa6b4b", "#ba0502"],
    "primary" : ["#efc644", "#1faade", "#d31d24", "#efc644", "#1faade", "#d31d24"],
    "sunbeam" : ["#ffebd8", "#ff7f00", "#4f67ff", "#ffebd8", "#ff7f00", "#4f67ff"],
    "orchid" : ["#f6eee6", "#e384b2", "#625bad", "#f6eee6", "#e384b2", "#625bad"],
    "sepia" : ["#e9f5da", "#efb594", "#625564", "#e9f5da", "#efb594", "#625564"],
    "night_sky" : ["#5eafb9", "#2c63ba", "#562cb9", "#5eafb9", "#2c63ba", "#562cb9"],
    "desert_night" : ["#ddb687", "#ac4c32", "#2c265c", "#ddb687", "#ac4c32", "#2c265c"],
    }

def get_brightness(hexstr):
    hexstr = hexstr.strip('#')

    if len(hexstr) != 6:
        return 0

    r, g, b = int(hexstr[:2], 16), int(hexstr[2:4], 16), int(hexstr[4:], 16)
    luma = math.sqrt(0.299 * r**2 + 0.587 * g**2 + 0.114 * b**2)
    return luma


print('{' + ', '.join(f'"{x}"' for x in list(styles.keys())) + '}')


for name, colors in styles.items():
    for i, color in enumerate(colors):
        text_color = "#000000"
        if get_brightness(color) <= 60:
            text_color = "#CCCCCC"
            print(name, get_brightness(color))

        if i <= 2:
            subprocess.Popen(f"magick P_button_base_s.png -fill '{colorscale(color,.8)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' -fill '{text_color}' -opaque '#FF0000' png32:{buttons[i]}_s_{name}.png", cwd=cwd, shell=True)
        else:
            subprocess.Popen(f"magick K_button_base_s.png -fill '{colorscale(color,.8)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' -fill '{text_color}' -opaque '#FF0000' png32:{buttons[i]}_s_{name}.png", cwd=cwd, shell=True)
        subprocess.Popen(f"magick button_base_b.png -fill '{colorscale(color,.1)}' -opaque '#00ff00' -fill '{color}' -opaque '#0000ff' png32:{buttons[i]}_b_{name}.png", cwd=cwd, shell=True)
