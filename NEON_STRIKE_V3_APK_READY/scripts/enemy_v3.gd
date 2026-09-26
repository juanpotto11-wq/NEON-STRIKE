extends CharacterBody3D

var target
var game
var enemy_type="ASSAULT"
var hp=100
var speed=2.5
var attack=8
var cooldown=0.0
var preferred_range=2.0
var orbit_sign=1.0

func setup(p,g,t):
    target=p; game=g; enemy_type=t
    orbit_sign = -1.0 if randf() < 0.5 else 1.0
    match t:
        "DRONE": hp=55; speed=4.2; attack=5; preferred_range=3.0
        "ASSAULT": hp=100; speed=2.7; attack=8; preferred_range=2.0
        "BRUTE": hp=320; speed=1.35; attack=18; preferred_range=2.1
        "HUNTER": hp=130; speed=3.5; attack=11; preferred_range=5.5

func take_damage(d, crit=false):
    hp -= d * (1.8 if crit else 1.0)
    game.hit_feedback(global_position, crit)
    if hp <= 0:
        game.enemy_died(self)

func _physics_process(delta):
    if not is_instance_valid(target) or game.state != game.GameState.PLAYING:
        return
    cooldown=max(0.0,cooldown-delta)
    var v=target.global_position-global_position
    v.y=0
    var dist=v.length()
    if enemy_type=="HUNTER" and dist<preferred_range:
        var side=Vector3(-v.z,0,v.x).normalized()*orbit_sign
        velocity=(side*1.8 - v.normalized()*0.7)*speed
    elif dist>preferred_range:
        velocity=v.normalized()*speed
    else:
        velocity=Vector3.ZERO
    if velocity.length()>0.1:
        look_at(global_position+velocity,Vector3.UP)
        move_and_slide()
    if dist<=preferred_range+0.8 and cooldown<=0:
        cooldown=1.0 if enemy_type!="BRUTE" else 1.3
        game.damage_player(attack)
