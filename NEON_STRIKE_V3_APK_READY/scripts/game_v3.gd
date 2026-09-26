extends Node3D

enum GameState { MENU, PLAYING, PAUSED, GAMEOVER }
var state=GameState.MENU
var player
var camera
var weapon_mesh
var enemies=[]
var effects=[]
var hp=100
var score=0
var wave=0
var wave_remaining=0
var spawn_timer=0.0
var fire_cd=0.0
var yaw=0.0
var pitch=-0.08
var recoil=0.0
var sway=0.0
var move_vec=Vector2.ZERO
var move_touch_id=-1
var look_touch_id=-1
var last_look=Vector2.ZERO
var mission_kills=0
var boss_alive=false
var kill_streak=0
var max_enemies=12

var weapons=[
 {"name":"PULSE RIFLE","mag":30,"ammo":30,"reserve":150,"damage":25,"cooldown":0.105,"spread":0.018,"recoil":0.028},
 {"name":"SCATTER SHOT","mag":8,"ammo":8,"reserve":48,"damage":18,"cooldown":0.60,"spread":0.11,"recoil":0.085},
 {"name":"RAILGUN","mag":4,"ammo":4,"reserve":20,"damage":145,"cooldown":1.25,"spread":0.0,"recoil":0.14}
]
var weapon_index=0

var ui
var hud
var mission_label
var center_label
var weapon_label
var ammo_label
var hp_bar
var menu_panel
var crosshair
var damage_flash
var pause_button
var fire_button
var reload_button
var switch_button

func _ready():
    randomize()
    _build_world()
    _build_player()
    _build_ui()
    _show_menu()

func _mat(c, emission=0.0, metallic=0.5):
    var m=StandardMaterial3D.new()
    m.albedo_color=c; m.metallic=metallic; m.roughness=0.26
    if emission>0:
        m.emission_enabled=true; m.emission=c; m.emission_energy_multiplier=emission
    return m

func _build_world():
    var env=WorldEnvironment.new()
    var e=Environment.new()
    e.background_mode=Environment.BG_COLOR
    e.background_color=Color("#040611")
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color=Color("#536aa0")
    e.ambient_light_energy=0.68
    e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env.environment=e; add_child(env)

    var sun=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-55,-25,0)
    sun.light_energy=1.0
    sun.shadow_enabled=false
    add_child(sun)

    var floor=CSGBox3D.new()
    floor.size=Vector3(70,0.4,70); floor.position.y=-0.2
    floor.material=_mat(Color("#0d1424"),0,0.8); add_child(floor)

    # Cover + skyline silhouettes, kept intentionally light for mobile GPUs.
    var props=[
      [Vector3(0,2,-16),Vector3(10,4,2)],
      [Vector3(15,2,-5),Vector3(2,4,10)],
      [Vector3(-15,2,-5),Vector3(2,4,10)],
      [Vector3(10,2,13),Vector3(8,4,2)],
      [Vector3(-11,2,14),Vector3(8,4,2)],
      [Vector3(0,2,25),Vector3(12,4,2)]
    ]
    for item in props:
        var b=CSGBox3D.new()
        b.position=item[0]; b.size=item[1]
        b.material=_mat(Color("#182740"),0.12)
        add_child(b)

    for i in range(14):
        var pole=CSGCylinder3D.new()
        pole.radius=0.10; pole.height=3.8
        pole.position=Vector3(randf_range(-27,27),1.9,randf_range(-27,27))
        pole.material=_mat(Color("#233b5e"),0.15)
        add_child(pole)

    for p in [Vector3(-25,2,0),Vector3(25,2,0),Vector3(0,2,-25),Vector3(0,2,25)]:
        var l=OmniLight3D.new()
        l.position=p; l.omni_range=13; l.light_energy=3.0
        l.light_color=Color("#00e5ff") if abs(p.x)<1 else Color("#ff2bd6")
        l.shadow_enabled=false
        add_child(l)

func _build_player():
    player=CharacterBody3D.new(); player.position=Vector3(0,1.1,10); add_child(player)
    var cs=CollisionShape3D.new()
    var cap=CapsuleShape3D.new(); cap.radius=0.38; cap.height=1.8
    cs.shape=cap; player.add_child(cs)
    camera=Camera3D.new(); camera.position=Vector3(0,0.65,0); camera.current=true
    player.add_child(camera)
    var ray=RayCast3D.new(); ray.name="WeaponRay"; ray.target_position=Vector3(0,0,-80); ray.enabled=true
    camera.add_child(ray)
    weapon_mesh=MeshInstance3D.new(); camera.add_child(weapon_mesh)
    _refresh_weapon()

func _refresh_weapon():
    var w=weapons[weapon_index]
    var box=BoxMesh.new()
    box.size=[Vector3(0.18,0.18,0.75),Vector3(0.30,0.18,0.55),Vector3(0.14,0.14,1.15)][weapon_index]
    weapon_mesh.mesh=box
    weapon_mesh.position=Vector3(0.28,-0.25,-0.55)
    weapon_mesh.material_override=_mat([Color("#27e8ff"),Color("#ff4acb"),Color("#ffd447")][weapon_index],3.5,0.8)

func _build_ui():
    ui=CanvasLayer.new(); add_child(ui)
    hud=Label.new(); hud.position=Vector2(24,18); hud.add_theme_font_size_override("font_size",23); ui.add_child(hud)
    hp_bar=ProgressBar.new(); hp_bar.position=Vector2(24,76); hp_bar.size=Vector2(260,22); hp_bar.max_value=100; ui.add_child(hp_bar)
    mission_label=Label.new(); mission_label.position=Vector2(24,112); mission_label.add_theme_font_size_override("font_size",17); ui.add_child(mission_label)
    crosshair=Label.new(); crosshair.text="+"; crosshair.position=Vector2(634,330); crosshair.add_theme_font_size_override("font_size",30); ui.add_child(crosshair)
    center_label=Label.new(); center_label.position=Vector2(540,250); center_label.add_theme_font_size_override("font_size",34); ui.add_child(center_label)
    weapon_label=Label.new(); weapon_label.position=Vector2(1010,600); weapon_label.add_theme_font_size_override("font_size",20); ui.add_child(weapon_label)
    ammo_label=Label.new(); ammo_label.position=Vector2(1010,635); ammo_label.add_theme_font_size_override("font_size",27); ui.add_child(ammo_label)

    fire_button=_button("FIRE",Vector2(1060,490),Vector2(150,80),_shoot)
    reload_button=_button("RELOAD",Vector2(880,610),Vector2(115,55),_reload)
    switch_button=_button("WEAPON",Vector2(880,545),Vector2(115,55),_next_weapon)
    pause_button=_button("Ⅱ",Vector2(1190,25),Vector2(60,55),_toggle_pause)

    damage_flash=ColorRect.new()
    damage_flash.color=Color(1,0,0,0)
    damage_flash.position=Vector2.ZERO
    damage_flash.size=Vector2(1280,720)
    ui.add_child(damage_flash)

func _button(text,pos,size,callback):
    var b=Button.new(); b.text=text; b.position=pos; b.size=size
    b.add_theme_font_size_override("font_size",20); b.pressed.connect(callback); ui.add_child(b); return b

func _show_menu():
    state=GameState.MENU
    menu_panel=Panel.new(); menu_panel.position=Vector2(350,130); menu_panel.size=Vector2(580,460); ui.add_child(menu_panel)
    var title=Label.new(); title.text="NEON STRIKE"; title.position=Vector2(130,45); title.add_theme_font_size_override("font_size",52); menu_panel.add_child(title)
    var sub=Label.new(); sub.text="V3 // CYBER ARENA"; sub.position=Vector2(205,110); sub.add_theme_font_size_override("font_size",18); menu_panel.add_child(sub)
    var start=Button.new(); start.text="START MISSION"; start.position=Vector2(150,175); start.size=Vector2(280,68); start.add_theme_font_size_override("font_size",25); start.pressed.connect(_start_game); menu_panel.add_child(start)
    var info=Label.new(); info.text="3 ARMAS  •  4 ENEMIGOS  •  BOSS CADA 5 OLEADAS\nRECOIL  •  HIT FX  •  MISIONES  •  MOBILE HUD\n\nWASD + MOUSE / TOUCH"; info.position=Vector2(120,285); info.add_theme_font_size_override("font_size",16); menu_panel.add_child(info)

func _start_game():
    if is_instance_valid(menu_panel): menu_panel.queue_free()
    state=GameState.PLAYING; hp=100; score=0; wave=0; mission_kills=0; boss_alive=false; enemies.clear()
    weapon_index=0
    for i in range(weapons.size()):
        weapons[i].ammo=weapons[i].mag
    player.position=Vector3(0,1.1,10); yaw=0; pitch=-0.08
    _refresh_weapon(); _next_wave()

func _next_wave():
    wave+=1
    wave_remaining=min(5+wave*2,20)
    boss_alive=(wave%5==0)
    if boss_alive: wave_remaining+=1
    center_label.text=("BOSS WAVE %d" if boss_alive else "WAVE %d") % wave
    get_tree().create_timer(1.4).timeout.connect(func(): center_label.text="")
    spawn_timer=0

func _physics_process(delta):
    if state!=GameState.PLAYING: return
    fire_cd=max(0.0,fire_cd-delta)
    recoil=lerp(recoil,0.0,delta*9.0)
    sway=sin(Time.get_ticks_msec()*0.006)*0.004
    weapon_mesh.rotation.x=-recoil
    weapon_mesh.position.x=0.28+sway
    spawn_timer-=delta
    _move_player()
    if wave_remaining>0 and spawn_timer<=0 and enemies.size()<max_enemies:
        _spawn_enemy()
        wave_remaining-=1; spawn_timer=0.38
    if wave_remaining==0 and enemies.is_empty(): _next_wave()
    if damage_flash.color.a>0: damage_flash.color.a=max(0.0,damage_flash.color.a-delta*3.0)
    _update_ui()

func _move_player():
    var v=Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_back")-Input.get_action_strength("move_forward"))
    if move_vec.length()>0.1: v=move_vec
    var dir=(player.transform.basis*Vector3(v.x,0,v.y)).normalized()
    player.velocity=Vector3(dir.x*7.0,0,dir.z*7.0); player.move_and_slide()
    player.rotation.y=yaw; camera.rotation.x=pitch

func _input(event):
    if event is InputEventMouseMotion and state==GameState.PLAYING:
        yaw-=event.relative.x*0.0025; pitch=clamp(pitch-event.relative.y*0.002,-1.25,1.0)
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: _shoot()
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x<get_viewport().size.x*0.45: move_touch_id=event.index
            else: look_touch_id=event.index; last_look=event.position
        else:
            if event.index==move_touch_id: move_touch_id=-1; move_vec=Vector2.ZERO
            if event.index==look_touch_id: look_touch_id=-1
    if event is InputEventScreenDrag:
        if event.index==move_touch_id: move_vec=(event.position-last_look).limit_length(70)/70.0
        elif event.index==look_touch_id:
            var d=event.position-last_look; yaw-=d.x*0.006; pitch=clamp(pitch-d.y*0.004,-1.25,1.0); last_look=event.position
    if Input.is_action_just_pressed("reload"): _reload()
    if Input.is_action_just_pressed("weapon_next"): _next_weapon()
    if Input.is_action_just_pressed("pause_game"): _toggle_pause()

func _shoot():
    if state!=GameState.PLAYING or fire_cd>0: return
    var w=weapons[weapon_index]
    if w.ammo<=0: _reload(); return
    w.ammo-=1; weapons[weapon_index]=w
    fire_cd=w.cooldown; recoil=w.recoil
    weapon_mesh.position.z=-0.82
    get_tree().create_timer(0.055).timeout.connect(func(): weapon_mesh.position.z=-0.55)
    var ray:RayCast3D=camera.get_node("WeaponRay"); ray.force_raycast_update()
    if ray.is_colliding():
        var hit=ray.get_collider()
        if hit and hit.has_method("take_damage"):
            var crit=randf()<0.12 and weapon_index!=1
            hit.take_damage(w.damage,crit)
        else: hit_feedback(ray.get_collision_point(),false)

func _reload():
    var w=weapons[weapon_index]
    var need=w.mag-w.ammo
    var take=min(need,w.reserve)
    w.ammo+=take; w.reserve-=take; weapons[weapon_index]=w

func _next_weapon():
    weapon_index=(weapon_index+1)%weapons.size(); _refresh_weapon()

func _spawn_enemy():
    var types=["DRONE","ASSAULT","BRUTE","HUNTER"]
    var t
    if boss_alive and wave_remaining==1: t="BRUTE"
    else: t=types[randi()%types.size()]
    var e=CharacterBody3D.new()
    e.position=Vector3(randf_range(-24,24),1,randf_range(-24,24))
    if e.position.distance_to(player.position)<10: e.position+=Vector3(14,0,14)
    add_child(e)
    var cs=CollisionShape3D.new(); var sh=CapsuleShape3D.new()
    var s=1.0 if t!="BRUTE" else 1.45
    sh.radius=0.42*s; sh.height=1.7*s; cs.shape=sh; e.add_child(cs)
    var mesh=MeshInstance3D.new(); var cap=CapsuleMesh.new()
    cap.radius=0.42*s; cap.height=1.7*s; mesh.mesh=cap
    mesh.material_override=_mat(
        Color("#00e5ff") if t=="DRONE" else Color("#ff2d76") if t=="ASSAULT" else Color("#ff9a2e") if t=="BRUTE" else Color("#a85cff"),2.8)
    e.add_child(mesh)
    e.set_script(load("res://scripts/enemy_v3.gd")); e.setup(player,self,t)
    enemies.append(e)

func enemy_died(e):
    enemies.erase(e); mission_kills+=1
    score+=300 if e.enemy_type=="BRUTE" else 200 if e.enemy_type=="HUNTER" else 150 if e.enemy_type=="ASSAULT" else 100
    kill_streak+=1

func damage_player(d):
    hp=max(0,hp-d); damage_flash.color.a=0.22
    if hp<=0: _game_over()

func hit_feedback(pos,crit=false):
    # Lightweight pooled-style impact marker; auto-deletes quickly.
    var omni=OmniLight3D.new(); omni.position=pos; omni.omni_range=2.5 if crit else 1.4
    omni.light_color=Color("#fff36a") if crit else Color("#00e5ff"); omni.light_energy=4
    add_child(omni)
    get_tree().create_timer(0.07).timeout.connect(func(): omni.queue_free())

func _toggle_pause():
    if state==GameState.PLAYING:
        state=GameState.PAUSED; center_label.text="PAUSED"
    elif state==GameState.PAUSED:
        state=GameState.PLAYING; center_label.text=""

func _game_over():
    state=GameState.GAMEOVER; center_label.text="MISSION FAILED\nSCORE %d" % score
    get_tree().create_timer(2.0).timeout.connect(_show_menu)

func _update_ui():
    hp_bar.value=hp
    var w=weapons[weapon_index]
    hud.text="HP %d    SCORE %d    WAVE %d    ENEMIES %d" % [hp,score,wave,enemies.size()]
    mission_label.text="MISSION  |  SURVIVE WAVE 5+  |  KILLS %d  |  STREAK x%d" % [mission_kills,kill_streak]
    weapon_label.text=w.name
    ammo_label.text="%02d / %03d" % [w.ammo,w.reserve]
