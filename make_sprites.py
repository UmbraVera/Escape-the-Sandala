"""Bounce Back: Moroccan Edition - original pixel-art sprite generator.
Draws the boy (4 outfits) and Mama, seen from behind (top-down runner camera).
Outputs horizontal sprite strips ready for Godot's SpriteFrames."""
from PIL import Image, ImageDraw
import os

OUT = "bounce_back_sprites"
OUTLINE = (42, 26, 20, 255)
SKIN = (233, 181, 139, 255)
SKIN_D = (201, 145, 104, 255)
HAIR = (35, 25, 22, 255)
HAIR_L = (70, 52, 44, 255)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def outline(layer):
    """Add a 1px dark outline around every opaque pixel."""
    w, h = layer.size
    src = layer.load()
    out = layer.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        dst[x, y] = OUTLINE
                        break
    return out


def finish(body, shadow_box, size):
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(canvas).ellipse(shadow_box, fill=(0, 0, 0, 70))
    canvas.alpha_composite(outline(body))
    return canvas


# ---------------------------------------------------------------- BOY
OUTFITS = {
    # name: (top colour, top shade, legs colour, shoe colour, style)
    "base":     ("#2479bd", "#1a5b90", "#2c3e66", "#f2efe6", "tshirt"),
    "djellaba": ("#258b56", "#1b6a41", "#2c3e66", "#e8b923", "robe"),
    "babouche": ("#f2efe6", "#cfcabd", "#7a4a2a", "#e8b923", "fez"),
    "selham":   ("#258b56", "#1b6a41", "#2c3e66", "#e8b923", "selham"),
}
W, H = 32, 54
TOP = 6


def boy_frame(outfit, pose, f):
    top, top_d, legs, shoes, style = OUTFITS[outfit]
    top, top_d, legs, shoes = hexc(top), hexc(top_d), hexc(legs), hexc(shoes)
    body = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)

    # pose parameters
    if pose == "run":
        oy = [0, -1, 0, -1][f]
        ll, rl = [(4, 8), (7, 7), (8, 4), (7, 7)][f]       # leg lengths (short = lifted)
        la, ra = [(9, 6), (8, 8), (6, 9), (8, 8)][f]       # arm lengths (short = forward)
        arms_up = False
        shadow = (8, 42, 23, 46)
    elif pose == "jump":
        oy = [-7, -10][f]
        ll, rl = 4, 4
        la = ra = 7
        arms_up = True
        shadow = (11, 43, 20, 46) if f else (10, 42, 21, 46)
    elif pose == "slide":
        oy = 9
        ll, rl = 3, 3
        la = ra = 0
        arms_up = False
        shadow = (5, 43, 26, 47)
    else:  # hit
        oy = 0
        ll, rl = 8, 6
        la, ra = 5, 5
        arms_up = True
        shadow = (8, 42, 23, 46)

    oy += TOP
    shadow = (shadow[0], shadow[1] + TOP, shadow[2], shadow[3] + TOP)
    torso_bottom = 30 if pose != "slide" else 26
    robe = style in ("robe", "selham")

    # legs / feet
    if pose == "slide":
        d.rectangle((8, 27 + oy, 13, 29 + oy), fill=legs)
        d.rectangle((18, 27 + oy, 23, 29 + oy), fill=legs)
        d.rectangle((6, 29 + oy, 9, 30 + oy), fill=shoes)
        d.rectangle((22, 29 + oy, 25, 30 + oy), fill=shoes)
    elif robe:
        # only the feet poke out under the long robe
        for x0, ln in ((11, ll), (17, rl)):
            if ln <= 5:
                d.rectangle((x0, 38 + oy, x0 + 3, 39 + oy), fill=hexc("#c9a227"))   # sole, lifted foot
            else:
                d.rectangle((x0, 39 + oy, x0 + 3, 41 + oy), fill=shoes)
    else:
        for x0, ln in ((11, ll), (17, rl)):
            d.rectangle((x0, 31 + oy, x0 + 3, 31 + oy + ln - 2), fill=legs)
            sole = hexc("#c9a227") if (shoes == hexc("#e8b923") and ln <= 5) else shoes
            d.rectangle((x0 - (1 if x0 == 11 else 0), 31 + oy + ln - 1,
                         x0 + 3 + (1 if x0 == 17 else 0), 31 + oy + ln), fill=sole)

    # torso / robe
    if robe:
        hem = 38 if pose != "slide" else 29
        d.polygon([(10, 18 + oy), (21, 18 + oy), (23, hem + oy), (8, hem + oy)], fill=top)
        d.polygon([(19, 18 + oy), (21, 18 + oy), (23, hem + oy), (20, hem + oy)], fill=top_d)
    else:
        d.rounded_rectangle((10, 18 + oy, 21, torso_bottom + oy), radius=3, fill=top)
        d.rectangle((19, 20 + oy, 21, torso_bottom + oy), fill=top_d)
        if style == "fez":  # gandoura with a little embroidered collar
            d.rectangle((14, 18 + oy, 17, 19 + oy), fill=hexc("#c9a227"))

    # arms
    sleeve = top if style != "selham" else hexc("#6b3fa0")
    if pose == "slide":
        d.rectangle((3, 20 + oy, 9, 22 + oy), fill=sleeve)
        d.rectangle((22, 20 + oy, 28, 22 + oy), fill=sleeve)
        d.rectangle((1, 20 + oy, 2, 22 + oy), fill=SKIN)
        d.rectangle((29, 20 + oy, 30, 22 + oy), fill=SKIN)
    elif arms_up:
        lift = 3 if pose == "hit" else 0
        d.rectangle((7, 11 + oy + lift, 9, 20 + oy), fill=sleeve)
        d.rectangle((22, 11 + oy + lift, 24, 20 + oy), fill=sleeve)
        d.rectangle((7, 9 + oy + lift, 9, 10 + oy + lift), fill=SKIN)
        d.rectangle((22, 9 + oy + lift, 24, 10 + oy + lift), fill=SKIN)
    else:
        for x0, ln in ((7, la), (22, ra)):
            d.rectangle((x0, 19 + oy, x0 + 2, 19 + oy + ln - 2), fill=sleeve)
            d.rectangle((x0, 19 + oy + ln - 1, x0 + 2, 19 + oy + ln), fill=SKIN)

    # selham cloak over the shoulders
    if style == "selham":
        hem = 35 if pose != "slide" else 28
        d.polygon([(9, 18 + oy), (22, 18 + oy), (24, hem + oy), (7, hem + oy)], fill=hexc("#6b3fa0"))
        d.polygon([(19, 18 + oy), (22, 18 + oy), (24, hem + oy), (21, hem + oy)], fill=hexc("#53307d"))
        d.line([(7, hem + oy), (24, hem + oy)], fill=hexc("#c9a227"))

    # djellaba pointed hood hanging on the back
    if style == "robe":
        d.polygon([(12, 18 + oy), (19, 18 + oy), (16, 26 + oy)], fill=top_d)
        d.line([(12, 18 + oy), (16, 26 + oy), (19, 18 + oy)], fill=hexc("#c9a227"))

    if style == "selham" and arms_up:   # fill the gap between raised arms and hood
        d.rectangle((9, 10 + oy, 22, 19 + oy), fill=hexc("#6b3fa0"))

    # neck + head (seen from behind)
    d.rectangle((14, 16 + oy, 17, 18 + oy), fill=SKIN_D)
    if style == "selham":   # hood up, pointed tip
        d.ellipse((9, 4 + oy, 22, 17 + oy), fill=hexc("#6b3fa0"))
        d.polygon([(13, 6 + oy), (19, 6 + oy), (16, 1 + oy)], fill=hexc("#6b3fa0"))
        d.line([(16, 2 + oy), (16, 16 + oy)], fill=hexc("#53307d"))
    else:
        d.point([(9, 11 + oy), (9, 12 + oy), (22, 11 + oy), (22, 12 + oy)], fill=SKIN)  # ears
        d.ellipse((10, 5 + oy, 21, 16 + oy), fill=HAIR)
        d.arc((11, 6 + oy, 20, 14 + oy), 200, 290, fill=HAIR_L)                       # hair shine
        if style == "fez":
            d.rectangle((12, 2 + oy, 19, 7 + oy), fill=hexc("#b3261e"))
            d.rectangle((12, 2 + oy, 19, 2 + oy), fill=hexc("#8a1c16"))
            d.point([(19, 3 + oy), (20, 4 + oy), (20, 5 + oy), (20, 6 + oy)], fill=HAIR)  # tassel

    frame = finish(body, shadow, (W, H))
    if pose == "slide":  # dust puffs, drawn after the outline
        fd = ImageDraw.Draw(frame)
        pts = [(2, 46), (4, 48), (26, 47)] if f == 0 else [(1, 48), (27, 46), (28, 48)]
        for x, y in pts:
            fd.rectangle((x, y, x + 1, y + 1), fill=(240, 228, 200, 220))
    if pose == "hit":
        frame = frame.rotate(12, resample=Image.NEAREST, center=(16, 46))
    return frame


# ---------------------------------------------------------------- MAMA
MW, MH = 40, 56


def mama_frame(f):
    body = Image.new("RGBA", (MW, MH), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    oy = [0, -1, 0, -1][f]
    kaftan, kaftan_d = hexc("#993c1d"), hexc("#712b13")
    gold = hexc("#d9a521")
    scarf, scarf_d = hexc("#d4537e"), hexc("#993556")
    slipper = hexc("#3a7bd5")

    # feet: one blue slipper, one bare foot (the other slipper is in her hand!)
    for x0, has_slipper in ((13, True), (23, False)):
        lifted = (f == 0 and x0 == 13) or (f == 2 and x0 == 23)
        y0 = 44 if lifted else 47
        col = slipper if has_slipper else SKIN
        d.rectangle((x0, y0 + oy, x0 + 4, y0 + 2 + oy), fill=col)

    # kaftan with mdamma belt and gold hem
    d.polygon([(11, 21 + oy), (29, 21 + oy), (32, 47 + oy), (8, 47 + oy)], fill=kaftan)
    d.polygon([(25, 21 + oy), (29, 21 + oy), (32, 47 + oy), (27, 47 + oy)], fill=kaftan_d)
    d.rectangle((10, 30 + oy, 30, 32 + oy), fill=gold)
    d.line([(8, 46 + oy), (32, 46 + oy)], fill=gold)
    d.line([(20, 33 + oy), (20, 45 + oy)], fill=gold)

    # right arm reaching forward to grab the boy
    reach = [6, 7, 6, 5][f]
    d.rectangle((29, 22 + oy, 32, 22 + oy + reach), fill=kaftan)
    d.rectangle((29, 23 + oy + reach, 32, 25 + oy + reach), fill=SKIN)

    # left arm raised, waving the slipper
    sx = [-2, 0, 2, 0][f]
    d.rectangle((7 + sx // 2, 11 + oy, 10 + sx // 2, 23 + oy), fill=kaftan)
    d.rectangle((7 + sx // 2, 9 + oy, 10 + sx // 2, 11 + oy), fill=SKIN)
    d.rounded_rectangle((4 + sx, 1 + oy, 9 + sx, 9 + oy), radius=2, fill=slipper)
    d.rectangle((5 + sx, 4 + oy, 8 + sx, 5 + oy), fill=hexc("#2a5ea8"))  # strap

    # headscarf + drape
    d.polygon([(12, 14 + oy), (28, 14 + oy), (30, 24 + oy), (10, 24 + oy)], fill=scarf_d)
    d.ellipse((13, 5 + oy, 27, 19 + oy), fill=scarf)
    d.arc((14, 6 + oy, 26, 17 + oy), 200, 290, fill=hexc("#ed93b1"))
    d.point([(17, 10 + oy), (22, 13 + oy), (19, 16 + oy), (24, 9 + oy)], fill=hexc("#fbeaf0"))  # pattern dots

    return finish(body, (9, 49, 31, 54), (MW, MH))


# ---------------------------------------------------------------- EXPORT
def strip(frames):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        s.paste(fr, (i * w, 0))
    return s


def main():
    os.makedirs(OUT, exist_ok=True)
    anims = {"run": 4, "jump": 2, "slide": 2, "hit": 1}
    all_strips = {}
    for outfit in OUTFITS:
        for pose, n in anims.items():
            frames = [boy_frame(outfit, pose, i) for i in range(n)]
            s = strip(frames)
            name = f"boy_{outfit}_{pose}.png"
            s.save(os.path.join(OUT, name))
            all_strips[name] = frames
    mama = [mama_frame(i) for i in range(4)]
    strip(mama).save(os.path.join(OUT, "mama_run.png"))
    all_strips["mama_run.png"] = mama
    return all_strips


if __name__ == "__main__":
    main()
    print("done:", sorted(os.listdir(OUT)))
