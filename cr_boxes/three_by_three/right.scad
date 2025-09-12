use <fan_container.scad>
use <../handle.scad>

filter_z = get_filter_dim()[2];
grid_z = get_grid_z();
W = get_width();
L = get_length();
D = get_depth();

ofsX   = W/4;                 // 1/4 and 3/4 along TOP/BOTTOM (X)
ofsY   = L/4;                 // 1/4 and 3/4 along LEFT/RIGHT (Y)
z_drill = filter_z + grid_z - 10;


difference(){
    union(){
    fan_container(
      filter_z=filter_z,
      z=grid_z,
      top_left_corner_smoothed=false,
      bottom_left_corner_smoothed=false,
      bottom_right_corner_smoothed=false,
      top_right_corner_smoothed=false,
      edge_fan_top_smoothed=false,
      edge_fan_bottom_smoothed=false,
      edge_fan_right_smoothed=true,
      edge_fan_left_smoothed=false,
      edge_top_left_smoothed=false,
      edge_top_right_smoothed=false,
      edge_bottom_left_smoothed=false,
      edge_bottom_right_smoothed=false,
      top_screw_hole=false,
      left_screw_hole=false,
      bottom_screw_hole=false,
      right_screw_hole=false,
      long_wall="right",
      fan_hole=false,  
      left_wire_route_hole=false,
      right_wire_route_hole=false,
      top_wire_route_hole=false,
      bottom_wire_route_hole=false
      );
        // TOP
        for (a=[-ofsX, ofsX]) difference() {
          edge_nub_cube("bottom", a, nub_len=10, nub_proj=D, nub_h=10);
          edge_screw_cut(edge="bottom", at=a, z_drill=z_drill, nub_proj=D);
        }

        // LEFT (Y = ±ofsY)
        for (a=[-ofsY, ofsY]) difference() {
          edge_nub_cube("top", a, nub_len=10, nub_proj=D, nub_h=10);
          edge_screw_cut(edge="top", at=a, z_drill=z_drill, nub_proj=D);
        }

        // RIGHT
        for (a=[-ofsY, ofsY]) difference() {
          edge_nub_cube("left", a, nub_len=10, nub_proj=D, nub_h=10);
          edge_screw_cut(edge="left", at=a, z_drill=z_drill, nub_proj=D);
        }
        //Tabs
        place_tabs("right",  W, L-(D*2), D, filter_z, count=1);
  }
  bottom_labels(
    width=get_width(),
    length=get_length(),
    bottom_z=filter_z+grid_z-get_depth()+.8,
    part_code="CR",
    top_T_size=10,
    part_size=10,
    edge_margin=get_depth()*1.5
  );
}
