class_name VardhelmDiagnosticSandbox
extends SaveV2DiagnosticSandbox

## Bloco C6 — sandbox diagnóstico do Vardhelm para o SaveV2DiagnosticCoordinator.
##
## Cada create_targets() instancia uma experiência NOVA e isolada (nunca o jogo
## principal): sem Save V2 sombra, sem input (Ctrl+S/Ctrl+L do sandbox nunca
## disparam), sem processamento e invisível. Os alvos vêm do
## VardhelmRuntimeStateProvider (C5). discard() remove e libera a instância.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"

var _parent: Node
var _name: String
var slice: VardhelmVerticalSlice = null
var _discarded := false
## C10: câmera ativa do jogo principal antes de criar o sandbox.
var _game_camera: Camera3D = null


func _init(parent: Node, sandbox_name: String = "SaveV2DiagnosticSandbox") -> void:
    _parent = parent
    _name = sandbox_name


func create_targets() -> RuntimeRestoreTargets:
    if _discarded or slice != null or _parent == null or not is_instance_valid(_parent):
        return null
    slice = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
    slice.name = _name
    # C10: guarda a câmera ativa do jogo; o Player do sandbox nasce com Camera3D.current.
    var viewport := _parent.get_viewport()
    var game_camera: Camera3D = viewport.get_camera_3d() if viewport != null else null
    _parent.add_child(slice)
    # Isolamento: nada do sandbox participa do jogo.
    slice.shadow_save_v2 = null
    slice.player.set_physics_process(false)
    slice.set_process_unhandled_input(false)
    slice.set_process_input(false)
    slice.process_mode = Node.PROCESS_MODE_DISABLED
    slice.visible = false
    for child in slice.get_children():
        if child is CanvasLayer:
            (child as CanvasLayer).visible = false
    # C10: nenhuma câmera do sandbox pode continuar ativa; a do jogo volta a ser a atual.
    for camera in slice.find_children("*", "Camera3D", true, false):
        (camera as Camera3D).current = false
    _game_camera = game_camera
    _restore_game_camera()
    var targets := VardhelmRuntimeStateProvider.new(slice).build_targets()
    targets.is_sandbox = true
    return targets


func discard() -> void:
    if slice != null and is_instance_valid(slice):
        if slice.get_parent() != null:
            slice.get_parent().remove_child(slice)
        slice.queue_free()
    slice = null
    _discarded = true
    _restore_game_camera()


func is_discarded() -> bool:
    return _discarded


func spawn() -> SaveV2DiagnosticSandbox:
    return VardhelmDiagnosticSandbox.new(_parent, _name + "Next")


## C10: a câmera do jogo principal continua a atual (o sandbox não a rouba).
func _restore_game_camera() -> void:
    if _game_camera != null and is_instance_valid(_game_camera) and _game_camera.is_inside_tree() and not _game_camera.current:
        _game_camera.make_current()
