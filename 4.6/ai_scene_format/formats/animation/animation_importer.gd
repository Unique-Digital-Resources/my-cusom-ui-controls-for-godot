@tool
class_name AIAnimationImporter
extends RefCounted

## Converts a Godot AnimationPlayer into an internal AIAnimationModel.

class AIAnimKeyframe:
    var time: float
    var value: Variant
    var transition: float

class AIAnimTrack:
    var path: String # NodePath (e.g., "Sprite:position")
    var type: int # Animation.TrackType
    var interp: int # Animation.InterpolationType
    var keyframes: Array[AIAnimKeyframe] = []

class AIAnim:
    var name: String
    var length: float
    var loop: bool
    var tracks: Array[AIAnimTrack] = []

static func import_player(player: AnimationPlayer) -> Array[AIAnim]:
    var animations: Array[AIAnim] = []
    if not player: return animations
    
    var lib = player.get_animation_library("")
    if not lib: return animations
    
    for anim_name in lib.get_animation_list():
        var godot_anim = lib.get_animation(anim_name)
        var ai_anim = AIAnim.new()
        ai_anim.name = anim_name
        ai_anim.length = godot_anim.length
        ai_anim.loop = godot_anim.loop_mode == Animation.LOOP_LINEAR
        
        for track_idx in range(godot_anim.get_track_count()):
            var track = AIAnimTrack.new()
            track.path = godot_anim.track_get_path(track_idx)
            track.type = godot_anim.track_get_type(track_idx)
            track.interp = godot_anim.track_get_interpolation_type(track_idx)
            
            for key_idx in range(godot_anim.track_get_key_count(track_idx)):
                var key = AIAnimKeyframe.new()
                key.time = godot_anim.track_get_key_time(track_idx, key_idx)
                key.value = godot_anim.track_get_key_value(track_idx, key_idx)
                key.transition = godot_anim.track_get_key_transition(track_idx, key_idx)
                track.keyframes.append(key)
                
            ai_anim.tracks.append(track)
            
        animations.append(ai_anim)
        
    return animations