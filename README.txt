BOUNCE BACK: MOROCCAN EDITION - character sprites
Original pixel art, made for this game. Free to use and modify.

FILES (each file is a horizontal strip of frames)
  Boy  - frame size 32 x 54 px
    boy_<outfit>_run.png    4 frames  (loop)
    boy_<outfit>_jump.png   2 frames  (no loop)
    boy_<outfit>_slide.png  2 frames  (loop)
    boy_<outfit>_hit.png    1 frame   (stumble when he hits an obstacle)
    outfits: base (t-shirt), djellaba (green + babouches),
             babouche (gandoura + fez + golden babouches), selham (purple hooded cloak)
  Mama - frame size 40 x 56 px
    mama_run.png            4 frames  (loop, waving her slipper!)

HOW TO USE IN GODOT 4
1. Drag the whole folder into res://assets/
2. Project > Project Settings > Rendering > Textures > Default Texture Filter = Nearest
   (keeps pixel art sharp)
3. Player scene: select the AnimatedSprite2D > Sprite Frames > New SpriteFrames > click it
4. In the SpriteFrames panel at the bottom: rename "default" to "run",
   click the grid icon "Add frames from sprite sheet", pick boy_base_run.png,
   set Horizontal = 4, Vertical = 1, select all frames, Add.
5. Add animations "jump" (Horizontal 2), "slide" (Horizontal 2), "hit" (Horizontal 1).
   Turn Loop OFF for jump and hit. Speed: run 10 FPS, slide 8 FPS.
6. Scale the AnimatedSprite2D to 2 (or 3) so he is big enough on a 540x960 screen.
7. Mama: same steps with mama_run.png, Horizontal = 4.

CHANGING OUTFIT WHEN HE WINS A PRIZE
Make one SpriteFrames resource per outfit (boy_base.tres, boy_djellaba.tres...)
and swap it in code:  $AnimatedSprite2D.sprite_frames = load("res://assets/boy_djellaba.tres")
