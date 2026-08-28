class_name SVGAnimationWriter
extends RefCounted

# Converts RenderAnimation objects into SVG SMIL animation tags (<animate>, <animateTransform>)

func write_animations(animations: Array[RenderAnimation]) -> PackedStringArray:
    var tags: PackedStringArray = PackedStringArray()
    
    for anim in animations:
        var tag = _write_single_animation(anim)
        if tag != "":
            tags.append(tag)
            
    return tags

func _write_single_animation(anim: RenderAnimation) -> String:
    var values: PackedStringArray = PackedStringArray()
    var key_times: PackedStringArray = PackedStringArray()
    
    # Format keyframes
    for key in anim.keyframes:
        values.append(_format_value(anim.target_property, key.value))
        var t = key.time / anim.duration if anim.duration > 0 else 0.0
        key_times.append("%.3f" % t)
        
    var dur_str = "%.3fs" % anim.duration
    var repeat_str = "indefinite" if anim.loop else "1"
    var values_str = ";".join(values)
    var key_times_str = ";".join(key_times)
    
    # Transform animations
    if anim.target_property.begins_with("transform."):
        var type_str = anim.target_property.split(".")[1]
        return "<animateTransform attributeName=\"transform\" type=\"%s\" values=\"%s\" keyTimes=\"%s\" dur=\"%s\" repeatCount=\"%s\" additive=\"sum\" />" % [type_str, values_str, key_times_str, dur_str, repeat_str]
    
    # Attribute animations (opacity, fill, etc.)
    var attr_name = "opacity" if anim.target_property == "opacity" else "fill"
    return "<animate attributeName=\"%s\" values=\"%s\" keyTimes=\"%s\" dur=\"%s\" repeatCount=\"%s\" />" % [attr_name, values_str, key_times_str, dur_str, repeat_str]

func _format_value(prop: String, value: Variant) -> String:
    match prop:
        "transform.translate":
            return "%.2f,%.2f" % [value.x, value.y]
        "transform.rotate":
            return "%.2f" % rad_to_deg(value)
        "transform.scale":
            return "%.2f,%.2f" % [value.x, value.y]
        "opacity":
            return "%.3f" % float(value)
        "fill":
            return "#%s" % (value as Color).to_html(false) if value is Color else str(value)
        _:
            return str(value)