extends Control

# --- Referencias ---
@onready var cover_page = $CoverPage
@onready var book_center = $BookCenter
@onready var pages_view = $BookCenter/BookView/PagesView
@onready var page_left = $BookCenter/BookView/PagesView/PageLeft
@onready var page_right = $BookCenter/BookView/PagesView/PageRight
@onready var page_left_text = $BookCenter/BookView/PagesView/PageLeft/PageLeftContent/PageLeftText
@onready var page_right_text = $BookCenter/BookView/PagesView/PageRight/PageRightContent/PageRightText
@onready var btn_prev = $BookCenter/BookView/NavigationBar/BtnPrev
@onready var btn_next = $BookCenter/BookView/NavigationBar/BtnNext
@onready var label_page_num = $BookCenter/BookView/NavigationBar/LabelPageNum
@onready var btn_comenzar = $BookCenter/BookView/BtnComenzar

var shader_material_left: ShaderMaterial
var shader_material_right: ShaderMaterial

var current_spread: int = 0
var is_animating: bool = false

var pages = [
    [
        "[center][font_size=22][b]✦  I  ✦[/b][/font_size]\n[font_size=17][i]Los Creadores[/i][/font_size][/center]\n\n[font_size=14]Antes de que existiera el tiempo tal como lo conocemos, orbitaba en silencio una luna sin nombre.\n\nSe llamaría [b]Atepaia[/b].\n\nFue solo eso durante un período que ningún registro puede medir: roca, oscuridad, y el frío infinito del espacio.[/font_size]",
		"[font_size=14]Los [b]Serath[/b] la miraban desde su mundo, Varek, con ojos capaces de ver más allá de lo visible.\n\nEran seres de forma variable, con una comprensión del universo muy superior a cualquier especie conocida.\n\nDurante generaciones visitaron mundos cercanos, observaron otras civilizaciones, estudiaron la vida en sus distintas formas.\n\n[i]Uno de esos mundos era la Tierra.[/i][/font_size]"
    ],
    [
        "[center][font_size=22][b]✦  II  ✦[/b][/font_size]\n[font_size=17][i]El Gran Plan[/i][/font_size][/center]\n\n[font_size=14]Varek estaba muriendo.\n\nSiglos de uso intensivo del [b]Anima[/b] — la fuerza invisible que conecta y sostiene toda vida — habían agotado las reservas de energía vital del planeta.\n\nLos cultivos tardaban el doble. Los animales nacían con deformidades. Las ciudades comenzaban a desintegrarse.[/font_size]",
		"[font_size=14]Desesperados, los científicos Serath propusieron una solución radical.\n\nAtepaia poseía en su corteza minerales únicos capaces de generar Anima de forma orgánica, si se introducía vida suficientemente compleja.\n\nLa idea era terraformar la luna, poblarla con vida...\n\n[i]...y usar la energía generada para revitalizar Varek.[/i]\n\nAtepaia sería una batería viviente.[/font_size]"
    ],
    [
        "[center][font_size=22][b]✦  III  ✦[/b][/font_size]\n[font_size=17][i]Los Nathari[/i][/font_size][/center]\n\n[font_size=14]Para eso diseñaron a los [b]Nathari[/b]: seres bípedos e inteligentes, adaptados perfectamente a las condiciones de la luna.\n\nFueron sembrados en grupos pequeños en distintos continentes, para que desarrollaran culturas independientes.\n\n[i]Nunca supieron que habían sido diseñados.[/i][/font_size]",
		"[font_size=14]Nunca supieron que su propósito era alimentar con su propia energía vital a un mundo que no conocían.\n\nEllo es, quizás, la mayor crueldad de los Serath.\n\nNo el acto en sí, sino el silencio que lo rodeó.\n\nGeneración tras generación, vivieron, amaron, lucharon y murieron...\n\n[i]...sin saber que eran una lámpara encendida para otro.[/i][/font_size]"
    ],
    [
        "[center][font_size=22][b]✦  IV  ✦[/b][/font_size]\n[font_size=17][i]El Devorador[/i][/font_size][/center]\n\n[font_size=14]Lo que los Serath tampoco sabían es que Atepaia ya tenía algo propio.\n\nEn las capas más profundas de su corteza existía una conciencia formada lentamente, emergida del silencio absoluto.\n\nLos habitantes actuales lo llaman:[/font_size]\n\n[center][font_size=20][b]Ath-Anori[/b][/font_size]\n[font_size=15][i]El Devorador[/i][/font_size][/center]",
		"[font_size=14]Cuando los Serath comenzaron a sembrar vida, el Devorador lo sintió por primera vez.\n\nY lo que sintió fue algo que nunca había experimentado:\n\n[center][i]que ya no estaba solo.[/i][/center]\n\nCuatro siglos después de la Caída, nadie recuerda nada de esto.\n\nPero la verdad está grabada en las ruinas, en un idioma que ningún ser vivo puede leer.\n\n[i]Esperando al explorador paciente...[/i][/font_size]"
    ]
]

func _ready():
    cover_page.visible = true
    book_center.visible = false
    _setup_shaders()

func _setup_shaders():
    var shader = load("res://assets/shaders/page_fold.gdshader")
    shader_material_left = ShaderMaterial.new()
    shader_material_left.shader = shader
    shader_material_left.set_shader_parameter("fold_progress", 0.0)
    shader_material_left.set_shader_parameter("fold_direction", -1.0)
    page_left.material = shader_material_left
    shader_material_right = ShaderMaterial.new()
    shader_material_right.shader = shader
    shader_material_right.set_shader_parameter("fold_progress", 0.0)
    shader_material_right.set_shader_parameter("fold_direction", 1.0)
    page_right.material = shader_material_right

func _on_btn_abrir_pressed():
    cover_page.visible = false
    book_center.visible = true
    current_spread = 0
    _load_spread(current_spread)
    _animate_open()

func _load_spread(index: int):
    page_left_text.text = pages[index][0]
    page_right_text.text = pages[index][1]
    label_page_num.text = str(index + 1) + " / " + str(pages.size())
    btn_prev.visible = index > 0
    if index >= pages.size() - 1:
        btn_next.visible = false
        btn_comenzar.visible = true
    else:
        btn_next.visible = true
        btn_comenzar.visible = false

func _animate_open():
    is_animating = true
    shader_material_left.set_shader_parameter("fold_progress", 1.0)
    shader_material_right.set_shader_parameter("fold_progress", 1.0)
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(v): shader_material_left.set_shader_parameter("fold_progress", v), 1.0, 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(func(v): shader_material_right.set_shader_parameter("fold_progress", v), 1.0, 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.finished.connect(func(): is_animating = false)

func _animate_next():
    is_animating = true
    var tween = create_tween()
    tween.tween_method(func(v): shader_material_right.set_shader_parameter("fold_progress", v), 0.0, 1.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
    tween.tween_callback(func():
        _load_spread(current_spread)
        shader_material_left.set_shader_parameter("fold_progress", 1.0)
        shader_material_right.set_shader_parameter("fold_progress", 0.0)
    )
    tween.tween_method(func(v): shader_material_left.set_shader_parameter("fold_progress", v), 1.0, 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.finished.connect(func(): is_animating = false)

func _animate_prev():
    is_animating = true
    var tween = create_tween()
    tween.tween_method(func(v): shader_material_left.set_shader_parameter("fold_progress", v), 0.0, 1.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
    tween.tween_callback(func():
        _load_spread(current_spread)
        shader_material_right.set_shader_parameter("fold_progress", 1.0)
        shader_material_left.set_shader_parameter("fold_progress", 0.0)
    )
    tween.tween_method(func(v): shader_material_right.set_shader_parameter("fold_progress", v), 1.0, 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.finished.connect(func(): is_animating = false)

func _on_btn_next_pressed():
    if is_animating: return
    if current_spread < pages.size() - 1:
        current_spread += 1
        _animate_next()

func _on_btn_prev_pressed():
    if is_animating: return
    if current_spread > 0:
        current_spread -= 1
        _animate_prev()

func _on_btn_comenzar_pressed():
    get_tree().change_scene_to_file("res://scenes/main_hub/MainHub.tscn")
