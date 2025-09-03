use <fan_container.scad>
use <../handle.scad>

filter_z = get_filter_dim()[2];
grid_z = get_grid_z();
barrel_plug_dia = get_barrel_plug();
thickness = get_depth();



difference() {
  fan_container(
    filter_z=filter_z,
    z=grid_z,
    top_left_corner_smoothed=false,
    bottom_left_corner_smoothed=false,
    bottom_right_corner_smoothed=false,
    top_right_corner_smoothed=false,
    edge_fan_top_smoothed=true,
    edge_fan_bottom_smoothed=false,
    edge_fan_right_smoothed=false,
    edge_fan_left_smoothed=false,
    edge_top_left_smoothed=false,
    edge_top_right_smoothed=false,
    edge_bottom_left_smoothed=false,
    edge_bottom_right_smoothed=false,
    top_screw_hole=false,
    left_screw_hole=true,
    bottom_screw_hole=true,
    right_screw_hole=true,
    left_wire_route_hole=true,
    right_wire_route_hole=true,
    top_wire_route_hole=false,
    bottom_wire_route_hole=true,
    long_wall="top",
    fan_hole=true
  );
  translate([0,get_length() - 37 - 5.1, (grid_z + filter_z)/2]) {
    rotate([90,0,0]) {
      rotate([0,90,0]) {
        handle(screws_only=true);
      }
    }
  };
  // barrel plug hole
  translate([0, get_length()/2, (grid_z + filter_z)/2]) {
      rotate([90,0,0]) {
          cylinder(d=barrel_plug_dia, h=thickness*10, $fn=64, center=true);
      }
  };
  //Deboss part
  bottom_labels(
    width=get_width(),
    length=get_length(),
    bottom_z=filter_z+grid_z-get_depth()+.8,
    part_code="TC",
    top_T_size=10,
    part_size=10,
    edge_margin=get_depth()*1.5
  );
}

