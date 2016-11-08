#!/usr/bin/env ruby
# convexhull.rb
# Draw contours and convexity defect points to captured image
require "rubygems"
require "opencv"
require 'yaml'
require 'ruby_dig'

include OpenCV

@config = YAML.load_file 'config.yml'

color_window_on = @config['color_window_on']

source_window = GUI::Window.new 'source'
capture = CvCapture::open

def get_attr(color, name, kind)
  color_attr = @config.dig 'colors', color, name, kind
  default_attr = @config.dig('defaults', name, kind)
  color_attr || default_attr
end

colors = {}
@config['colors'].each do |color, attrs|
  color_attrs = {}
  color_attrs[:low] = CvScalar.new get_attr(color, 'hue', 'low'), get_attr(color, 'saturation', 'low'), get_attr(color, 'value', 'low')
  color_attrs[:high] = CvScalar.new get_attr(color, 'hue', 'high'), get_attr(color, 'saturation', 'high'), get_attr(color, 'value', 'high')

  if color_window_on
    color_window = GUI::Window.new color

    color_window.set_trackbar("h low", 255, color_attrs[:low][0])  { |v| color_attrs[:low][0] = v }
    color_window.set_trackbar("h high", 255, color_attrs[:high][0]) { |v| color_attrs[:high][0] = v }

    color_window.set_trackbar("s low", 255, color_attrs[:low][1]) { |v| color_attrs[:low][1] = v }
    color_window.set_trackbar("s high", 255, color_attrs[:high][1]) { |v| color_attrs[:high][1] = v }

    color_window.set_trackbar("v low", 255, color_attrs[:low][2]) { |v| color_attrs[:low][2] = v }
    color_window.set_trackbar("v high", 255, color_attrs[:high][2]) { |v| color_attrs[:high][2] = v }

    color_attrs[:window] = color_window
  end

  colors[color] = color_attrs
end

WorldTransform = Struct.new :scale, :rotation

start_origin = CvPoint.new 200, 300
world_transform = WorldTransform.new 110, 0

source_window.set_trackbar("origin x", 640, start_origin.x)  { |v| start_origin.x = v }
source_window.set_trackbar("origin y", 640, start_origin.y)  { |v| start_origin.y = v }
source_window.set_trackbar("scale", 200, world_transform.scale)  { |v| world_transform.scale = v }

Segment = Struct.new :world_origin, :world_transform do
  def render(canvas)
    p0 = CvPoint2D32f.new 0, 0
    p1 = CvPoint2D32f.new 0.7, 0
    p2 = CvPoint2D32f.new 0.7, 1
    p3 = CvPoint2D32f.new 0, 1
    [[p0, p1], [p1, p2], [p2, p3], [p3, p0]].each do |from, to|
      canvas.line! point_to_world(from), point_to_world(to), thickness: 2
    end
  end

  private

  def point_to_world(point)
    world_scale = world_transform.scale
    x = (point.x * world_scale) + world_origin.x
    y = (point.y * world_scale) + world_origin.y
    CvPoint.new x, y
  end
end

start_segment = Segment.new start_origin, world_transform

loop do
  image = capture.query
  result = image.clone

  hsv = image.BGR2HSV

  colors.each do |color, color_attrs|
    color_map = hsv.in_range(color_attrs[:low], color_attrs[:high]).dilate(nil, 2)
    color_attrs[:window].show color_map if color_window_on


    unless color_window_on
      hough = color_map.hough_circles CV_HOUGH_GRADIENT, 2, 5, 200, 40
      if hough.size > 0
        circle = hough.first
        cv_color = CvColor::const_get color.capitalize
        result.circle! circle.center, circle.radius, thickness: 3, color: cv_color
      end
    end
  end

  start_segment.render result

  source_window.show result
  GUI::wait_key(1)
end
