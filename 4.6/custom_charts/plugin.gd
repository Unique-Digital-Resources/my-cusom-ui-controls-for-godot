@tool
extends EditorPlugin

const PieChart := preload("res://addons/custom_charts/pie_chart/pie_chart.gd")
const PieSlice := preload("res://addons/custom_charts/pie_chart/pie_slice.gd")
const SliceBars := preload("res://addons/custom_charts/pie_chart/slice_bars.gd")
const SliceBar := preload("res://addons/custom_charts/pie_chart/slice_bar.gd")
const PieChartAxis := preload("res://addons/custom_charts/pie_chart/pie_chart_axis.gd")
const LineChart := preload("res://addons/custom_charts/line_chart/line_chart.gd")
const LineSeries := preload("res://addons/custom_charts/line_chart/line_series.gd")
const PointMarker := preload("res://addons/custom_charts/line_chart/point_marker.gd")
const ChartAxis := preload("res://addons/custom_charts/line_chart/chart_axis.gd")

func _enter_tree() -> void:
	add_custom_type("PieChart", "Container", PieChart, null)
	add_custom_type("PieSlice", "Control",  PieSlice, null)
	add_custom_type("SliceBars", "PieSlice", SliceBars, null)
	add_custom_type("SliceBar", "PieSlice",  SliceBar, null)
	add_custom_type("PieChartAxis", "Control", PieChartAxis, null)
	add_custom_type("LineChart", "Container", LineChart, null)
	add_custom_type("LineSeries", "Control", LineSeries, null)
	add_custom_type("PointMarker", "Control", PointMarker, null)
	add_custom_type("ChartAxis", "Container", ChartAxis, null)

func _exit_tree() -> void:
	remove_custom_type("ChartAxis")
	remove_custom_type("PointMarker")
	remove_custom_type("LineSeries")
	remove_custom_type("LineChart")
	remove_custom_type("PieChartAxis")
	remove_custom_type("SliceBar")
	remove_custom_type("SliceBars")
	remove_custom_type("PieSlice")
	remove_custom_type("PieChart")
