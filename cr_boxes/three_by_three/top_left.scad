use <fan_container.scad>

filter_z = get_filter_dim()[2];
grid_z = get_grid_z();

union(){
  fan_container(
      filter_z=filter_z,
      z=grid_z,
      top_left_corner_smoothed=true,
      bottom_left_corner_smoothed=false,
      bottom_right_corner_smoothed=false,
      top_right_corner_smoothed=false,
      edge_fan_top_smoothed=true,
      edge_fan_bottom_smoothed=false,
      edge_fan_right_smoothed=false,
      edge_fan_left_smoothed=true,
      edge_top_left_smoothed=true,
      edge_top_right_smoothed=false,
      edge_bottom_left_smoothed=false,
      edge_bottom_right_smoothed=false,
      top_screw_hole=false,
      left_screw_hole=false,
      bottom_screw_hole=true,
      right_screw_hole=true,
      long_wall="top-left",
      left_wire_route_hole=false,
      right_wire_route_hole=true,
      top_wire_route_hole=false,
      bottom_wire_route_hole=true
  );
  bottom_labels(
    width=get_width(),
    length=get_length(),
    bottom_z=filter_z+grid_z-get_depth()+.8,
    part_code="TL",
    top_T_size=10,
    part_size=10,
    edge_margin=get_depth()*1.5
  );
}
