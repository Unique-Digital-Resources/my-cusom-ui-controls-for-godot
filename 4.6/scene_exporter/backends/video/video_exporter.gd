class_name VideoExporter
extends RefCounted

# Handles exporting a sequence of SVG frames and compiling them into a video using FFmpeg.
# Passes camera settings down to each frame capture.

var exporter: Exporter

func _init():
	exporter = Exporter.new()

func export_video(root_node: Node, settings: ExportSettings) -> ExportReport:
	var report = ExportReport.new()
	var players = root_node.find_children("*", "AnimationPlayer", true, false)
	
	if players.is_empty():
		ExportUtils.log_error("Video Export: No AnimationPlayer found in scene.")
		return report
		
	# Fix: Play all animation players in the scene to ensure camera animations are captured
	for p in players:
		var anim_name = ""
		if p.has_animation("RESET"):
			anim_name = "RESET"
		elif p.get_animation_list().size() > 0:
			anim_name = p.get_animation_list()[0]
		else:
			continue
			
		ExportUtils.log_message("Video Export: Playing '" + anim_name + "' on " + p.name)
		p.play(anim_name)
		
	# Fix: Wait for the tree to process so Camera2D updates its initial state
	await root_node.get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	var total_frames = int(settings.duration * settings.fps)
	var temp_dir = "user://video_frames/"
	DirAccess.make_dir_recursive_absolute(temp_dir)
	
	ExportUtils.log_message("Video Export: Starting frame generation (%d frames)..." % total_frames)
	
	for i in range(total_frames):
		var time = float(i) / float(settings.fps)
		
		# Seek all animation players
		for p in players:
			p.seek(time, true)
			
		# Fix: Wait for the tree to process the frame. 
		# This is crucial for Camera2D to update its smoothing and transform.
		await root_node.get_tree().process_frame
		await RenderingServer.frame_post_draw
		
		# Create a temporary export setting for this specific frame
		var frame_settings = settings.duplicate()
		frame_settings.is_video_export = false
		frame_settings.export_animations = false # Prevent SMIL tags in static frames
		frame_settings.output_path = temp_dir + "frame_%05d.svg" % i
		
		# Phase 4: Explicitly ensure the camera_node_path is passed down for each frame
		frame_settings.camera_node_path = settings.camera_node_path
		
		# Run the standard SVG pipeline for this frame (it will apply the camera transform)
		exporter.export_scene(root_node, frame_settings)
		
	# Stop all animations and reset
	for p in players:
		p.stop()
		p.seek(0.0, true)
		
	await root_node.get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	var success = await _compile_video(temp_dir, settings.output_path, settings.fps)
	
	_remove_dir_contents(temp_dir)
	DirAccess.remove_absolute(temp_dir)
	
	if success:
		ExportUtils.log_message("Video export complete: " + settings.output_path)
	else:
		ExportUtils.log_error("Video export failed during FFmpeg compilation.")
		
	return report

func _compile_video(input_dir: String, output_path: String, fps: int) -> bool:
	var input_pattern = ProjectSettings.globalize_path(input_dir) + "frame_%05d.svg"
	var global_output = ProjectSettings.globalize_path(output_path)
	
	var args = [
		"-y",
		"-r", str(fps),
		"-i", input_pattern,
		"-c:v", "libx264",
		"-pix_fmt", "yuv420p",
		global_output
	]
	
	ExportUtils.log_message("Video Export: Running FFmpeg...")
	var output = []
	var exit_code = OS.execute("ffmpeg", args, output, true)
	
	if exit_code != 0:
		ExportUtils.log_error("FFmpeg failed. Ensure FFmpeg is installed and in your system PATH.")
		for line in output:
			ExportUtils.log_error(line)
		return false
		
	return true

func _remove_dir_contents(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
