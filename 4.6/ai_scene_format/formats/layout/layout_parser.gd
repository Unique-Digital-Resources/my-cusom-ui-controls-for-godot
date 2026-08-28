@tool
class_name AILayoutParser
extends AIParserBase

## Legacy V1 Layout Parser. 
## V2 uses AIParserBase directly. This stub exists to prevent compile errors.

func parse_to_model(source: String) -> AISceneModel:
	var model = AISceneModel.new()
	# V1 parsing is deprecated in V2
	return model
