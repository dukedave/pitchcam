Segment = Struct.new :index, :world_origin, :world_transform do
  WIDTH = 0.63
  def render_to(canvas)
    p0 = CvPoint2D32f.new 0, 0
    p1 = CvPoint2D32f.new WIDTH, 0
    p2 = CvPoint2D32f.new WIDTH, 1
    p3 = CvPoint2D32f.new 0, 1
    [[p0, p1], [p1, p2], [p2, p3], [p3, p0]].each do |from, to|
      canvas.line! local_to_world(from), local_to_world(to), thickness: 1, color:CvColor::White
    end
    canvas.put_text!(index.to_s, local_to_world(p3), CvFont.new(:simplex), CvColor::White)
  end

  def inside?(point)
    world_scale = world_transform.scale

    x_lo = (0 * world_scale) + world_origin.x
    x_hi = (0.7 * world_scale) + world_origin.x
    return unless x_lo < point.x && point.x < x_hi

    y_lo = (0 * world_scale) + world_origin.y
    y_hi = (1 * world_scale) + world_origin.y
    y_lo < point.y && point.y < y_hi
  end

  def next_world_origin
    p = CvPoint2D32f.new 0, 1
    local_to_world p
  end

  def position_from_world(point)
    world_scale = world_transform.scale
    p = (point.y - world_origin.y) / world_scale # progress
    d = ((point.x - world_origin.x) / world_scale) / WIDTH # drift
    Track::Postition.new p, d
  end

  def world_from_position(position)
    local_point = CvPoint2D32f.new (position.d * WIDTH), position.p
    local_to_world local_point
  end

  private

  def local_to_world(point)
    world_scale = world_transform.scale
    x = (point.x * world_scale) + world_origin.x
    y = (point.y * world_scale) + world_origin.y
    CvPoint.new x, y
  end
end
