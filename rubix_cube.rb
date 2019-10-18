class Cube

  # Mapper for selecting side of cube for rotation
  SIDE_ROTATION_MAPPING = {
    :left => {
      :vector => [-1,0,0],
      :extremum => :min,
      :cordinate => {:name => :x, :index => 0}
    },
    :right => {
      :vector => [1,0,0],
      :extremum => :max,
      :cordinate => {:name => :x, :index => 0}
    },
    :front => {
      :vector => [0,-1,0],
      :extremum => :min,
      :cordinate => {:name => :y, :index => 1}
    },
    :back => {
      :vector => [0,1,0],
      :extremum => :max,
      :cordinate => {:name => :y, :index => 1}
    },
    :up => {
      :vector => [0,0,1],
      :extremum => :max,
      :cordinate => {:name => :z, :index => 2}           
    },
    :down => {
      :vector => [0,0,-1],
      :extremum => :min,
      :cordinate => {:name => :z, :index => 2}  
    }
  }

  ANGLE = -90.degrees

  # Create a 3 x 3 cube in origin of SketchUp cordinate system
  #
  # edge - length of inner cube edge
  # margin - space between inner cubes
  def self.create_cube(edge = 10, margin = 1.5)
    model = Sketchup.active_model
    entities = model.entities
    view = model.active_view
    @cube = entities.add_group
    @history = []

    em = edge + margin
    cube_edge = (3 * em) - margin
    radius = cube_edge / 2
    move_vector = [-radius, -radius, -radius]

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
    all_faces.flatten!
    self.add_materials(all_faces, radius)
  end


  # Add right materials to sides of cube
  def self.add_materials(faces, radius)
    faces.each do |face|
      center = face.bounds.center.transform @transformation
      if center.x == (radius)
        face.material = "red"
      elsif center.x == (-radius)
        face.material = "darkorange"
      elsif center.y == (radius)
        face.material = "darkblue"
      elsif center.y == (-radius)
        face.material = "green"
      elsif center.z == (radius)
        face.material = "white"
      elsif center.z == (-radius)
        face.material = "yellow"
      else
        face.material = "dimgray"
      end 
    end
  end

  ############################################################
  # Rotate chosen side of cube in chosen direction
  #
  # @param side      [Symbol] of cube
  # @param direction [Symbol] of rotation
  #
  # @example: Cube.rotate(:left, :cw); Cube.rotate(:up, :ccw)
  ############################################################
  def self.rotate(side, direction)
    # Choose inner cubes
    inner_cubes = @cube.entities.grep(Sketchup::Group)
    # Get specs for chose side
    side_specs = SIDE_ROTATION_MAPPING[side]
    cordinate_name = side_specs[:cordinate][:name]
    cordinate_index = side_specs[:cordinate][:index]
    extremum = side_specs[:extremum]
    # Get extremum and calculate side center
    ext_cordinate = get_extremum(@cube, extremum, cordinate_name)
    side_center = @cube.bounds.center.clone
    side_center[cordinate_index] = ext_cordinate
    # Get rotation
    vector = Geom::Vector3d.new(side_specs[:vector])
    angle = direction == :cw ? ANGLE : -ANGLE
    view = Sketchup.active_model.active_view
    number_of_frames = 15
    angle_change = angle / number_of_frames.to_f
    rotation = Geom::Transformation.rotation(side_center, vector, angle_change)
    # Choose inner cubes on the chosen side of outer cube
    temp_group_arr = Array.new
    inner_cubes.each do |cub|
      cub_ext_cordinate = get_extremum(cub, extremum, cordinate_name)
      temp_group_arr << cub if cub_ext_cordinate == ext_cordinate
    end
    # Rotate the side
    number_of_frames.times do
      temp_group_arr.each{|cub| cub.transform!(rotation)}
      view.refresh
    end
    # Store in history
    @history << [side, direction]
  end


  ############################################################
  # Get chosen extremum coordinate (highest or lowes x, y or z)
  # of input group
  #
  # @param group      [Sketchup::Group]
  # @param extremum   [Symbol] :min or :max
  # @param cordinate  [Symbol] :x, :y or :z
  #
  # @example: get_extremum(grp, :max, :z)
  ############################################################
  def self.get_extremum(group, extremum, cordinate)
    return group.bounds.send(extremum).send(cordinate)
  end


  # Add toolbar with button for creating cube
  def self.add_toolbar
    return nil if @toolbar_added
    # Create new toolbar
    toolbar = UI::Toolbar.new("Rubix Cube")

    # Add command Create Cube
    cmd1 = UI::Command.new("Create Cube") {self.create_cube}
    cmd1.tooltip = "Create Cube"
    cmd1.small_icon = File.join(__dir__, 'rubix_cube', 'icons', 'create.png')
    cmd1.large_icon = File.join(__dir__, 'rubix_cube', 'icons', 'create.png')

    # Add command Create Cube
    cmd2 = UI::Command.new("Open Rotate Dialog") {self.open_rotate_dialog}
    cmd2.tooltip = "Open Rotate Dialog"
    cmd2.small_icon = File.join(__dir__, 'rubix_cube', 'icons', 'rotate.png')
    cmd2.large_icon = File.join(__dir__, 'rubix_cube', 'icons', 'rotate.png')

    # Add items and show toolbar
    toolbar = toolbar.add_item cmd1
    toolbar = toolbar.add_item cmd2
    toolbar.show
    @toolbar_added = true
  end

  # Add callbacks so actions can be performed on button clicks
  def self.add_callbacks(dialog)
    # Rotate part of cube baed on pressed button
    dialog.add_action_callback('rotate') do |ctx, side, direction|
      self.rotate(side.to_sym, direction.to_sym)
    end
  end

  # Open dialog with buttons for rotating sides of cube
  def self.open_rotate_dialog
    html_file = File.join(__dir__,'rubix_cube', 'rotate.html')
    options = {:dialog_title => "Rotate"}
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(html_file)
    dialog.set_size(280, 240)

    self.add_callbacks(dialog)
    dialog.show
  end

  # Revert changes made to the cube in reverse order
  def self.solve_cube
    # Make a deep copy of history
    history = Marshal.load(Marshal.dump(@history))

    while history.any?
      side, direction = history.pop
      if direction == :cw
        direction = :ccw
      else
        direction = :cw
      end
      self.rotate(side, direction)
    end
    @history.clear
  end
end

Cube.add_toolbar