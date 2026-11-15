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
