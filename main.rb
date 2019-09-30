class Cube

  # Create a 3 x 3 cube in origin of SketchUp cordinate system
  #
  # edge - length of inner cube edge
  # margin - space between inner cubes
  def self.create_cube(edge = 10, margin = 1.5)
    model = Sketchup.active_model
    entities = model.entities
    view = model.active_view
    @cube = entities.add_group

    em = edge + margin
    cube_edge = (3 * em) - margin
    m = cube_edge / 2
    move_vector = [-m, -m, -m]

    all_faces = Array.new
    # Iterate 3 times in 3 directions
    (0..2).each do |i|
      (0..2).each do |j|
        (0..2).each do |k|
          inner_cube = @cube.entities.add_group
          # Calculate face points cordinates
          point1 = [i*em, j*em, k*em]
          point2 = [i*em, j*em+edge, k*em]
          point3 = [i*em+edge, j*em+edge, k*em]
          point4 = [i*em+edge, j*em, k*em]

          # Add face, make inner cube from it, store faces
          face = inner_cube.entities.add_face point1, point2, point3, point4
          face.reverse! if face.normal.z < -0.9
          face.pushpull edge
          all_faces << inner_cube.entities.grep(Sketchup::Face)

          # Move inner cube, store transformation, refresh view
          inner_cube.move!(move_vector)
          @transformation = inner_cube.transformation unless @transformation
          view.refresh
        end
      end
    end
  end

end

Cube.create_cube