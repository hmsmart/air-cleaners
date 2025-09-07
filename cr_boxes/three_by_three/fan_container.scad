use <../row_fan.scad>
use <../builder.scad>
use <../../common/screw_with_nut.scad>
use <../../common/usbc_female.scad>
use <../../laminair/filter_louvers_container.scad>
use <../../laminair/foot.scad>
// Lennox Model HCF14-13
// Replaces Filter Parn No. 19L14

grid_z =  48;
depth = 5;
num_fan_rows = 3;
num_fan_cols = 3;
barrel_plug_dia = 10.96;
wire_route_dia = 6.942;
filter_x = 502;
filter_y = 502;
filter_z = 25.4;
fan_diameter = 140;
//Text Writing
deboss_depth = 1;         
deboss_font  = "Berkeley Mono:style=Bold";
deboss_stroke = 0.18;      
deboss_eps = 0.05;        

function get_length(fy=filter_y, d=depth, n=num_fan_cols) = (d * 2 + fy) / n;
function get_width(fx=filter_x, d=depth, n=num_fan_rows) = (d * 2 + fx) / n;
function get_barrel_plug() = barrel_plug_dia;
function get_depth() = depth;

function get_x_spacing(width, fan_diameter) = (width - fan_diameter) / 2;
function get_y_spacing(length, fan_diameter) = (length - fan_diameter) / 2;

width = get_width(filter_x, depth, num_fan_rows);
length = get_length(filter_y, depth, num_fan_cols);

x_spacing = get_x_spacing(width, fan_diameter);
y_spacing = get_y_spacing(length, fan_diameter);
threaded_height = 8;
cone_top_radius = 8;

function get_filter_dim() = [filter_x, filter_y, filter_z];
function get_grid_z() = grid_z;

function z_offset(long=false) = long ? -(grid_z + filter_z) / 2 - depth / 2 : -grid_z / 2 - depth / 2;

module wall_remover(long_wall, width, length, filter_z, z) {
  x_offset = long_wall == "center" ? 0 : long_wall == "top-left" || long_wall == "bottom-left" || long_wall == "left" ? depth : ((long_wall == "top" || long_wall == "bottom" || long_wall == "None") ? 0 : -depth);

  y_offset = long_wall == "top-left" || long_wall == "top" || long_wall == "top-right" ? -depth : (long_wall == "bottom-left" || long_wall == "bottom" || long_wall == "bottom-right" ? depth : 0);


  translate([x_offset,y_offset,(filter_z+grid_z-depth)/2]) {
    cube([width, length,filter_z+grid_z-depth], center=true);
  }
}

// --- helpers ---
function clamp(v, lo, hi) = max(lo, min(hi, v));

// Triangular ramp tab that prints support-free (≤45° if tab_out ≥ tab_thick)
// edge: "top" | "bottom" | "left" | "right"
// at:   distance along that edge from its negative corner (mm)
module ledge_tab(edge, at, inner_w, inner_l, depth, grid_z,
                 tab_len=10, tab_out=depth, tab_thick=1.2, kiss=0.01) {

  xL = -inner_w/2; xR =  inner_w/2;
  yB = -inner_l/2; yT =  inner_l/2;

  len = tab_len;
  out = tab_out;
  t   = tab_thick;
  z0  = grid_z - t;       // bottom of the tab

  if (edge == "top" || edge == "bottom") {
    // Along-X edge; inward is -Y for top, +Y for bottom.
    y_wall   = (edge=="top") ? (yT - kiss) : (yB + kiss);
    s_inward = (edge=="top") ? -1 : +1;
    xC       = clamp(xL + at, xL + len/2, xR - len/2);

    // 6 points of a triangular prism (two triangles + faces)
    points = [
      [xC - len/2, y_wall,              z0],       // 0  A-
      [xC - len/2, y_wall,              z0 + t],   // 1  B-
      [ xC - len/2, y_wall + s_inward*out, z0 ],      // 2  C-
      [xC + len/2, y_wall,              z0],       // 3  A+
      [xC + len/2, y_wall,              z0 + t],   // 4  B+
      [ xC + len/2, y_wall + s_inward*out, z0 ]       // 5  C+
    ];

    faces = [
      [0,1,2],        // end triangle
      [3,5,4],        // other end triangle
      [0,3,4,1],      // flat face touching wall
      [1,4,5,2],      // flat top (shelf)
      [2,5,3,0]       // sloped underside (ramp inward)
    ];
    polyhedron(points, faces);

  } else if (edge == "left" || edge == "right") {
    // Along-Y edge; inward is +X for left, -X for right.
    x_wall   = (edge=="left") ? (xL + kiss) : (xR - kiss);
    s_inward = (edge=="left") ? +1 : -1;
    yC       = clamp(yB + at, yB + len/2, yT - len/2);

    points = [
      [x_wall,              yC - len/2, z0],        // 0  A-
      [x_wall,              yC - len/2, z0 + t],    // 1  B-
      [ x_wall + s_inward*out, yC - len/2, z0 ],
      [x_wall,              yC + len/2, z0],        // 3  A+
      [x_wall,              yC + len/2, z0 + t],    // 4  B+
      [ x_wall + s_inward*out, yC + len/2, z0 ] 
    ];

    faces = [
      [0,2,1],        // end triangle
      [3,4,5],        // other end triangle
      [0,1,4,3],      // flat face touching wall
      [1,2,5,4],      // flat top (shelf)
      [2,0,3,5]       // sloped underside (ramp inward)
    ];
    polyhedron(points, faces);
  }
}

// Place N tabs evenly along an edge, keeping a margin from both ends.
// Uses your existing `ledge_tab(...)` unchanged.
module place_tabs(edge, inner_w, inner_l, depth, grid_z,
                  count=4, end_margin=0, tab_len=35, tab_out=22, tab_thick=22/4) {
  span = (edge=="top"||edge=="bottom") ? inner_w : inner_l;

  // available run for *centers*, measured from the negative corner
  start_at = end_margin + tab_len/2;
  end_at   = span - end_margin - tab_len/2;

  for (i=[0:count-1]) {
    at = start_at + (end_at - start_at) * (i + 0.5) / count;  // distance from negative corner
    ledge_tab(edge, at, inner_w, inner_l, depth, grid_z, tab_len, tab_out, tab_thick);
  }
}


module top_left_zip_tie_hole(z_offset, depth, fan_size) {
  translate([fan_size / 2 - 2 * depth, fan_size / 2 - depth, z_offset + 5]) {
    usbc_female();
  }
}

module top_right_zip_tie_hole(z_offset, depth, fan_size) {
  mirror([1,0,0])
    top_left_zip_tie_hole(z_offset, depth, fan_size);
}

module bottom_right_zip_tie_hole(z_offset, fan_size, depth) {
  mirror([1,0,0])
  mirror([0,1,0])
  top_left_zip_tie_hole(z_offset, depth, fan_size);
}

module bottom_left_zip_tie_hole(z_offset, fan_size, depth) {
  mirror([0,1,0])
  top_left_zip_tie_hole(z_offset, depth, fan_size);
}

module screw_joins(
    bottom_right_stabilizer,
    bottom_right_stabilizer_axis,
    top_right_stabilizer,
    top_right_stabilizer_axis,
    bottom_left_stabilizer,
    bottom_left_stabilizer_axis,
    top_left_stabilizer,
    top_left_stabilizer_axis,
    depth,
    x_spacing,
    y_spacing,
    side,
    fan_size,
    filter_x,
    filter_y
) {
  // TODO: The code currently assumes depth (wall depth) is the same as the
  // screw_join depth. Might be good to decouple them at some point.
  if (bottom_right_stabilizer != "none" && bottom_right_stabilizer_axis == "horizontal") {
      if (bottom_right_stabilizer == "p1") {

        translate([-(filter_x + 2 * depth) / 4, -(filter_y + 2 * depth) / 4 - depth, side / 2]) {
          mirror([1,0,0])
            rotate([0,-90,0])
            rotate([0,0,90])
            screw_join_p1();
        }
      } else {
        translate([-(filter_x + 2 * depth) / 4,-(filter_y + 2 * depth) / 4 + 2 * depth,side / 2]) {
          rotate([0,-90,0])
          rotate([0,0,-180])
          screw_join_p2();
        }
      }
   }

  // TODO: use num_rows and num_cols to do the proper division
  if (bottom_right_stabilizer != "none" && bottom_right_stabilizer_axis == "vertical") {
    translate([-(filter_x + 2 * depth) / 4  + 2 * depth, -(filter_y + 2 * depth) / 4, side / 2]) {

        rotate([90,0,0])

        mirror([0,0,1])
        rotate([0,0,-180])
          screw_join_p1();
    }
   }
  if (top_left_stabilizer != "none" && top_left_stabilizer_axis == "vertical") {
    translate([(filter_x + 2 * depth) / 4 - depth * 2,(filter_y + 2 * depth) / 4,side / 2]) {
      // rotate([0,0,90])
      rotate([-90,0,0])
        mirror([0,0,1])
          screw_join_p1();
    }
  }

  if (top_left_stabilizer != "none" && top_left_stabilizer_axis == "horizontal") {
    translate([(filter_x + 2 * depth) / 4,(filter_y + 2 * depth) / 4 - depth - 5,side / 2]) {
      // mirror([1,0,0])
      // rotate([0,0,-90])
      rotate([0,90,0])
          screw_join_p2();
    }
  }


  if (top_right_stabilizer != "none" && top_right_stabilizer_axis == "horizontal") {
    translate([-(filter_x + 2 * depth) / 4, filter_y / 4 - depth - 2.5, side / 2]) {
      rotate([0,-90,0])
      rotate([0,0,90])
      mirror([0,0,1])
        screw_join_p1();
    }
  }

  if (top_right_stabilizer != "none" && top_right_stabilizer_axis == "vertical") {
    translate([-(filter_x + 2 * depth) / 4 + depth * 2, (filter_y + 2 * depth) / 4,side / 2]) {
      rotate([0,90,0])
      rotate([-90,0,0])
          screw_join_p2();
    }
  }

  if (bottom_left_stabilizer != "none" && bottom_left_stabilizer_axis == "vertical") {
    translate([(filter_x + 2 * depth) / 4 - depth - 5,-(filter_y + 2 * depth) / 4, side / 2]) {
      rotate([90,0,0])
      rotate([0,0,-90])
          screw_join_p2();
    }
  }

  if (bottom_left_stabilizer != "none" && bottom_left_stabilizer_axis == "horizontal") {
    translate([(filter_x + 2 * depth) / 4, -(filter_y + 2 * depth) / 4 + depth * 2, side / 2]) {
      rotate([-90,0,0])
      rotate([0,90,0])
        mirror([0,0,1])
          screw_join_p1();
    }
  }

}

module fan_container(
  long_wall,
  filter_z,
  z,
  x_spacing=x_spacing,
  y_spacing=y_spacing,
  z_spacing=filter_z,
  z_offset=15,
  left_wall_long=false,
  right_wall_long=false,
  top_wall_long=false,
  bottom_wall_long=false,
  top_screw_hole=false,
  bottom_screw_hole=false,
  left_screw_hole=false,
  right_screw_hole=false,
  edge_fan_top_smoothed=false,
  edge_fan_bottom_smoothed=false,
  edge_fan_left_smoothed=false,
  edge_fan_right_smoothed=false,
  edge_top_left_smoothed=false,
  edge_top_right_smoothed=false,
  edge_bottom_left_smoothed=false,
  edge_bottom_right_smoothed=false,
  left_front_edge_smoothed=false,
  right_front_edge_smoothed=false,
  top_left_corner_smoothed=false,
  top_right_corner_smoothed=false,
  top_right_front_corner_smoothed=false,
  bottom_left_corner_smoothed=false,
  bottom_right_corner_smoothed=false,
  bottom_left_front_corner_smoothed=false,
  bottom_right_front_corner_smoothed=false,
  bottom_front_edge_smoothed=false,
  top_left_front_corner_smoothed=false,
  top_front_edge_smoothed=false,
  bottom_right_zip_tie_hole=false,
  bottom_left_zip_tie_hole=false,
  top_right_zip_tie_hole=false,
  top_left_zip_tie_hole=false,
  width=width,
  length=length,
  fan_size=140,
  grid_z=25.4,
  depth=5,
  top_right_stabilizer="none",
  top_left_stabilizer="none",
  bottom_left_stabilizer="none",
  bottom_right_stabilizer="none",
  filter_x=filter_x,
  filter_y=filter_y,
  bottom_right_stabilizer_axis="horizontal",
  bottom_left_stabilizer_axis="horizontal",
  top_left_stabilizer_axis="vertical",
  top_right_stabilizer_axis="vertical",
  northeast_foot=false,
  southeast_foot=false,
  northwest_foot=false,
  southwest_foot=false,
  cone_top_radius=10,
  fan_hole=true,
  left_wire_route_hole=false,
  right_wire_route_hole=false,
  top_wire_route_hole=false,
  bottom_wire_route_hole=false
) {
  height = 10;
  side = 35 * 2 + 10;
  threaded_height = 8;
  stabilizer_height = threaded_height + 2;

  difference() {
    union() {

      difference() {

        top_spaced(
            z=z + filter_z,
            depth=depth,
            width=width,
            length=length,
            x_spacing=x_spacing,
            y_spacing=y_spacing,
            z_spacing=z_spacing,
            z_offset=z_offset,
            bottom_front_edge_smoothed=bottom_front_edge_smoothed,
            edge_fan_top_smoothed=edge_fan_top_smoothed,
            edge_fan_bottom_smoothed=edge_fan_bottom_smoothed,
            edge_fan_left_smoothed=edge_fan_left_smoothed,
            edge_fan_right_smoothed=edge_fan_right_smoothed,
            edge_top_left_smoothed=edge_top_left_smoothed,
            edge_top_right_smoothed=edge_top_right_smoothed,
            edge_bottom_left_smoothed=edge_bottom_left_smoothed,
            edge_bottom_right_smoothed=edge_bottom_right_smoothed,
            top_left_front_corner_smoothed=top_left_front_corner_smoothed,
            top_left_corner_smoothed=top_left_corner_smoothed,
            top_right_corner_smoothed=top_right_corner_smoothed,
            bottom_left_corner_smoothed=bottom_left_corner_smoothed,
            bottom_right_corner_smoothed=bottom_right_corner_smoothed,
            bottom_left_front_corner_smoothed=bottom_left_front_corner_smoothed,
            bottom_right_front_corner_smoothed=bottom_right_front_corner_smoothed,
            left_front_edge_smoothed=left_front_edge_smoothed,
            right_front_edge_smoothed=right_front_edge_smoothed,
            top_front_edge_smoothed=top_front_edge_smoothed,
            top_right_front_corner_smoothed=top_right_front_corner_smoothed,
            fan_hole=fan_hole,
            fan_diameter=fan_size
          );
          wall_remover(long_wall, width, length, filter_z, z);
      }

        translate([0.5,0.5,filter_z + z - depth ]) {
          // Add 2 to make sure there is awkward spacing
          finger_guard(fan_size=fan_size+3, depth=depth);
        }
    }
    union() {
      if (top_left_zip_tie_hole) {
        top_left_zip_tie_hole(fan_size=fan_size, z_offset=filter_z, depth=depth);
      }

      if (bottom_right_zip_tie_hole) {
        bottom_right_zip_tie_hole(fan_size=fan_size, z_offset=filter_z, depth=depth);
      }

      if (bottom_left_zip_tie_hole) {
        bottom_left_zip_tie_hole(fan_size=fan_size, z_offset=filter_z, depth=depth);
      }

      if (top_right_zip_tie_hole) {
        top_right_zip_tie_hole(fan_size=fan_size, z_offset=filter_z, depth=depth);
      }

      if (top_screw_hole) {
        edge_nub_cube(edge="top");
      }

      if (bottom_screw_hole) {
        bottom_screw_and_nut(length=length, filter_z=filter_z + 5);
      }

      if (left_screw_hole) {
          left_screw_and_nut(
              length=length,
              width=width,
              grid_z=grid_z,
              threaded_height=threaded_height,
              filter_x=filter_x,
              filter_z=filter_z + 5  // Changed from: z + filter_z + 5
              );
      }
      if (right_screw_hole) {
          right_screw_and_nut(
              length=length,
              width=width,
              grid_z=grid_z,
              threaded_height=threaded_height,
              filter_x=filter_x,
              filter_z=filter_z + 5,  // Changed from: z + filter_z + 5
              depth=depth
              );
      }

      if (northeast_foot) {
        northeast_foot(filter_x=filter_x, filter_y=filter_y, z=filter_z, cone_top_radius=cone_top_radius, screw=true, height=height);
      }
      if (northwest_foot) {
        northwest_foot(filter_x=filter_x, filter_y=filter_y, z=filter_z, cone_top_radius=cone_top_radius, screw=true, height=height);
      }
      if (southeast_foot) {
        southeast_foot(filter_x=filter_x, filter_y=filter_y, z=filter_z, cone_top_radius=cone_top_radius, screw=true, height=height);
      }
      if (southwest_foot) {
        southwest_foot(filter_x=filter_x, filter_y=filter_y, z=filter_z, cone_top_radius=cone_top_radius, screw=true, height=height);
      }
      if (left_wire_route_hole) {
        left_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth);
      }
      if (right_wire_route_hole) {
        right_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth);
      }
      if (top_wire_route_hole) {
        top_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth);
      }
      if (bottom_wire_route_hole) {
        bottom_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth);
      }
    }
  }

  screw_joins(
    bottom_right_stabilizer=bottom_right_stabilizer,
    bottom_right_stabilizer_axis=bottom_right_stabilizer_axis,
    top_right_stabilizer=top_right_stabilizer,
    top_right_stabilizer_axis=top_right_stabilizer_axis,
    bottom_left_stabilizer=bottom_left_stabilizer,
    bottom_left_stabilizer_axis=bottom_left_stabilizer_axis,
    top_left_stabilizer=top_left_stabilizer,
    top_left_stabilizer_axis=top_left_stabilizer_axis,
    depth=depth,
    x_spacing=x_spacing,
    y_spacing=y_spacing,
    side=side,
    fan_size=fan_size,
    filter_x=filter_x,
    filter_y=filter_y
  );

}

module top_screw_and_nut(length, filter_z) {
  screw_height = length / 2 + threaded_height -2.1;
  translate([0, screw_height,  filter_z]) {
    rotate([90,0,0])
      color([0,0,1])
      screw_with_nut(threaded_height=threaded_height);
  }
}

module bottom_screw_and_nut(length, filter_z=filter_z) {
  translate([0,-length,0]) {
    top_screw_and_nut(length=length, filter_z=filter_z);
  }
}

module left_screw_and_nut(length, width, grid_z, threaded_height, filter_x, filter_z, depth=5) {
  screw_height = width / 2 + threaded_height - 2.1;
  translate([-screw_height, 0, filter_z]) {
    rotate([0, 90, 0])
      color([0, 0, 1])
      screw_with_nut(threaded_height=threaded_height);
  }
}

module left_wire_route_cutout(length = length, width = width, filter_z = filter_z + 5, depth=depth) {
  z_offset = filter_z;
  x_offset = -width / 2;
  y_offset = length / 4;

  translate([x_offset, y_offset, z_offset]) {
    rotate([0, 90, 0])
      cylinder(d=wire_route_dia, h=depth * 4, center=true, $fn=64);
  }
}

// Right side wire routing hole (mirrors the left)
module right_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth) {
  z_offset = filter_z;
  x_offset = width / 2;      // right inside wall
  y_offset = length / 4;     // keep same Y offset

  translate([x_offset, y_offset, z_offset]) {
    rotate([0, 90, 0])
      cylinder(d=wire_route_dia, h=depth * 4, center=true, $fn=64);
  }
}

// Top wire routing hole (centered in X, inset from top wall)
module top_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth) {
  z_offset = filter_z;
  x_offset = width / 4;      // shift along X (quarter across the panel)
  y_offset = length / 2;     // top inside wall

  translate([x_offset, y_offset, z_offset]) {
    rotate([-90, 0, 0])      // cylinder axis along Y
      cylinder(d=wire_route_dia, h=depth * 4, center=true, $fn=64);
  }
}

// Bottom wire routing hole
module bottom_wire_route_cutout(length=length, width=width, filter_z=filter_z + 5, depth=depth) {
  z_offset = filter_z;
  x_offset = width / 4;      // same X offset
  y_offset = -length / 2;    // bottom inside wall

  translate([x_offset, y_offset, z_offset]) {
    rotate([-90, 0, 0])      // cylinder axis along Y
      cylinder(d=wire_route_dia, h=depth * 4, center=true, $fn=64);
  }
}

module right_screw_and_nut(length, width, grid_z, threaded_height, filter_x, filter_z, depth) {
  translate([width, 0, 0]) {
    left_screw_and_nut(
        length=length,
        width=width,
        grid_z=grid_z,
        threaded_height=threaded_height,
        filter_x=filter_x,
        filter_z=filter_z,
        depth=depth
    );
  }
}

module edge_nub_cube(edge="top", at=0,          // offset along that edge from CENTER (mm)
                     nub_len=20, nub_proj=8,    // along-edge, inward projection
                     nub_h=10, kiss=0.01) {     // nub height

  // center the nub at the very bottom and grow up nub_h
  zc = (filter_z + grid_z) - nub_h;

  if (edge == "top") {
    translate([ at,  (length/2 - kiss) - nub_proj/2, zc ])
      cube([nub_len, nub_proj, nub_h], center=true);
  } else if (edge == "bottom") {
    translate([ at, -(length/2 - kiss) + nub_proj/2, zc ])
      cube([nub_len, nub_proj, nub_h], center=true);
  } else if (edge == "right") {
    translate([ (width/2 - kiss) - nub_proj/2,  at,  zc ])
      cube([nub_proj, nub_len, nub_h], center=true);
  } else if (edge == "left") {
    translate([-(width/2 - kiss) + nub_proj/2,  at,  zc ])
      cube([nub_proj, nub_len, nub_h], center=true);
  }
}

module edge_screw_cut(edge="top", at=0, z_drill, kiss=.1, nub_proj=8) {

  if (edge == "top") {
    // inward = -Y ; NUT inward: map +Z -> -Y  (Rx +90)
    translate([ at,  (length/2 + nub_proj + (kiss * 9)),  z_drill ])
      rotate([ 90, 0, 0 ])
        screw_with_nut(threaded_height=threaded_height);

  } else if (edge == "bottom") {
    // inward = +Y ; HEAD inward: map -Z -> +Y
    // do Ry 180° to flip Z, then Rx -90° to align to +Y
    translate([ at, -(length/2 -nub_proj - kiss),  z_drill ])
      rotate([-90, 0, 0]) rotate([0,180,0])   // (apply rightmost first)
        screw_with_nut(threaded_height=threaded_height);

  } else if (edge == "left") {
    // inward = +X ; NUT inward: map +Z -> +X  (Ry +90)
    translate([-(width/2 - nub_proj - kiss),  at,  z_drill ])
      rotate([ 0, 90, 0 ]) rotate([0,180,0])
        screw_with_nut(threaded_height=threaded_height);

  } else if (edge == "right") {
    // inward = -X ; HEAD inward: map -Z -> -X
    // flip Z with Ry 180°, then align +Z->-X with Ry -90°
    translate([ (width/2 + nub_proj + (kiss * 9)),  at,  z_drill ])
      rotate([0,-90,0])     // (apply rightmost first)
        screw_with_nut(threaded_height=threaded_height);
  }
}

module southeast_foot(filter_x, filter_y, z=0, height=10, cone_top_radius=8, screw=false, num_rows=2, num_cols=2) {
  translate([
  -(filter_x + 2 * depth) / num_rows / 2 + cone_top_radius + depth / 2,
  -(filter_y + 2 * depth) / num_cols / 2 - cone_top_radius,
  cone_top_radius - depth / 2]) {
    foot(screw=screw, height=height);
  }
}

module southwest_foot(filter_x, filter_y, z=0, height=10, cone_top_radius=8, screw=false, num_rows=2, num_cols=2) {
  translate([
      (filter_x + 2 * depth) / num_rows / 2 - cone_top_radius - depth / 2,
      -(filter_y + 2 * depth) / num_cols / 2 - cone_top_radius,
      cone_top_radius - depth / 2]) {
    foot(screw=screw, height=height);
  }
}

module northeast_foot(filter_x, filter_y, z=0, cone_top_radius=8, screw=true, height=10, num_rows=2, num_cols=2) {
  translate([0,0,z - depth]) {
    southeast_foot(filter_x, filter_y, z=z, height=height, cone_top_radius=cone_top_radius, screw=screw, num_rows=num_rows, num_cols=num_cols);
  }
}

module northwest_foot(filter_x, filter_y, z=0, height=10, cone_top_radius=8, screw=false, num_rows=2, num_cols=2) {
  translate([0,0,z - depth]) {
    southwest_foot(filter_x, filter_y, z=z, height=height, cone_top_radius=cone_top_radius, screw=screw, num_rows=num_rows, num_cols=num_cols);
  }
}

// Deboss text into the interior floor at Z = bottom_z (use 0 for your floor).
// We mirror in X to make text read correctly when viewed from inside the box.
module deboss_text_on_bottom(
  label, pos=[0,0], bottom_z=0, size=10,
  angle=0,                 // keep 0; use 180 only if you want upside-down
  fix_mirror=true,         // set false if you *don’t* want the horizontal un-mirror
  halign="center", valign="center"
){
  translate([pos[0], pos[1], bottom_z - deboss_depth + deboss_eps])
    linear_extrude(height=deboss_depth)
      offset(r=deboss_stroke)
        rotate([0,0,angle]) {
          if (fix_mirror)
            mirror([1,0,0]) text(label, size=size, font=deboss_font, halign=halign, valign=valign);
          else
            text(label, size=size, font=deboss_font, halign=halign, valign=valign);
        }
}
module bottom_labels(
  width, length, bottom_z,
  part_code="TL",
  top_T_size=10,
  part_size=10,
  edge_margin=6,
  flip_axis="x"         
){
  // "T" near TOP-RIGHT corner, inset by edge_margin on both axes
  deboss_text_on_bottom(
    label="↑",
    pos=[ -width/2 + edge_margin,  length/2 - edge_margin ],
    bottom_z=bottom_z,
    size=top_T_size,
    flip_axis=flip_axis,
    halign="right", valign="top"
  );

  // part code near BOTTOM-LEFT corner, inset by edge_margin on both axes
  deboss_text_on_bottom(
    label=part_code,
    pos=[ width/2 - edge_margin, -length/2 + edge_margin ],
    bottom_z=bottom_z,
    size=part_size,
    flip_axis=flip_axis,
    halign="left", valign="bottom"
  );
}

fan_container(
  filter_z=filter_z,
  z=grid_z,
  top_left_corner_smoothed=true,
  bottom_left_corner_smoothed=true,
  bottom_right_corner_smoothed=true,
  top_right_corner_smoothed=true,
  edge_fan_top_smoothed=true,
  edge_fan_bottom_smoothed=true,
  edge_fan_right_smoothed=true,
  edge_fan_left_smoothed=true,
  edge_top_left_smoothed=true,
  edge_top_right_smoothed=true,
  edge_bottom_left_smoothed=true,
  edge_bottom_right_smoothed=true,
  top_screw_hole=true,
  left_screw_hole=true,
  bottom_screw_hole=true,
  right_screw_hole=true,
  left_wall_long=true,
  long_wall="top-left"
);

