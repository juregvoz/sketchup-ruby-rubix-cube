class Cube

  # Make a 3 x 3 cube in origin of SketchUp cordinate system
  def self.create_cube(edge = 10, margin = 1.5)
    model = Sketchup.active_model
    entities = model.entities
    view = model.active_view

    # Create cube group
    @cube = entities.add_group

    em = edge + margin

    # Half cube
    m = -((3*em)-margin)/2

    move_vector = [m,m,m]

    all_faces = Array.new

    # Iterate 3 times in 3 directions
    (0..2).each do |i|
      (0..2).each do |j|
        (0..2).each do |k|
          inner_cube = @cube.entities.add_group

          # Calculate points cordinates
          point1 = [i*em, j*em, k*em]
          point2 = [i*em, j*em+edge, k*em]
          point3 = [i*em+edge, j*em+edge, k*em]
          point4 = [i*em+edge, j*em, k*em]

          face = inner_cube.entities.add_face point1, point2, point3, point4
          face.reverse! if face.normal.z < -0.9
          face.pushpull edge

          all_faces << inner_cube.entities.grep(Sketchup::Face)

          inner_cube.move!(move_vector)


          @transformation = inner_cube.transformation unless @transformation

          view.refresh
        end
      end
    end

  end

end

Cube.create_cube