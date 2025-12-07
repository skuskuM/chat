// Boat switch panel with embossed icons and rotated text
// Adjust the parameters below to tweak panel, spacing, and embossing.
panel_thickness = 3;        // base panel thickness
corner_radius = 4;
corner_hole_diameter = 4;   // diameter for mounting holes at corners
mount_hole_offset_x = 5;    // distance from vertical edges to mounting hole center
mount_hole_offset_y = 5;    // distance from horizontal edges to mounting hole center

rows = 1;
cols = 8;
hole_diameter = 11;
hole_clearance = 0.2;       // extra diameter for drilling clearance
hole_spacing_x = 14;
hole_spacing_y = 12;

panel_margin_x = 18;        // margin from outer switch center to edge
panel_margin_y = 22;        // margin above/below the switch row
panel_width = (cols - 1) * hole_spacing_x + 2 * panel_margin_x;
panel_height = hole_diameter + (rows - 1) * hole_spacing_y + 2 * panel_margin_y;

icon_size = 8;
icon_base_height = 1.2;
emboss_height = 0.6;
icon_gap = -10;             // gap between switch center and icon edge
icon_offset_x = 0;          // horizontal shift for pictograms (left/right)
icon_offset_y = 12;         // vertical shift for pictograms (up/down)
text_gap = -4;              // distance from switch perimeter to text baseline
text_size = 3.0;            // font size for embossed labels
text_offset_x = 0;          // horizontal shift for text (left/right)
text_offset_y = -17;        // vertical shift for text (up/down)
text_font = "Liberation Sans:style=Bold";

labels = [
    "220V",
    "HI-FI",
    "WIFI",
    "HI-FI",
    "LIGHTS",
    "HEATER",
    "BEAM L",
    "BEAM H"
];

module boat_switch_panel() {
    difference() {
        rounded_panel(panel_width, panel_height, panel_thickness, corner_radius);
        switch_holes();
        mounting_holes();
    }
    embossed_features();
}

module rounded_panel(w, h, t, r) {
    translate([-w/2, -h/2, 0]) linear_extrude(t)
        offset(r) offset(-r) square([w - 2*r, h - 2*r]);
}

module mounting_holes() {
    z = panel_thickness + 2;
    x_offset = panel_width/2 - mount_hole_offset_x;
    y_offset = panel_height/2 - mount_hole_offset_y;
    for (corner = [[-1, -1], [1, -1], [-1, 1], [1, 1]])
        translate([corner[0] * x_offset,
                   corner[1] * y_offset,
                   -1])
            cylinder(h = z, d = corner_hole_diameter, $fn = 40);
}

module switch_holes() {
    z = panel_thickness + 2;
    for (i = [0 : len(labels) - 1]) {
        pos = hole_position(i);
        translate([pos[0], pos[1], -1])
            cylinder(h = z, d = hole_diameter + hole_clearance, $fn = 80);
    }
}

module embossed_features() {
    for (i = [0 : len(labels) - 1]) {
        pos = hole_position(i);
        icon_center = [
            pos[0] - (hole_diameter/2 + icon_gap + icon_size/2) + icon_offset_x,
            pos[1] + icon_offset_y
        ];
        text_center = [
            pos[0] + (hole_diameter/2 + text_gap) + text_offset_x,
            pos[1] + text_offset_y
        ];

        translate([icon_center[0], icon_center[1], panel_thickness])
            pictogram_tile(i);

        translate([text_center[0], text_center[1], panel_thickness])
            rotate([0, 0, 90])
                linear_extrude(height = emboss_height)
                    text(labels[i], size = text_size, font = text_font,
                         halign = "center", valign = "center");
    }
}

module pictogram_tile(index) {
    linear_extrude(height = icon_base_height)
        square([icon_size, icon_size], center = true);
    translate([0, 0, icon_base_height])
        linear_extrude(height = emboss_height)
            icon_shape(index);
}

module icon_shape(index) {
    if (index == 0)
        icon_inverter();
    else if (index == 1 || index == 3)
        icon_media();
    else if (index == 2)
        icon_wifi_mast();
    else if (index == 4)
        icon_night_light();
    else if (index == 5)
        icon_heat_coils();
    else if (index == 6)
        icon_short_beam();
    else if (index == 7)
        icon_long_beam();
    else
        square([icon_size/2, icon_size/2], center = true);
}

module icon_inverter() {
    union() {
        translate([-2.5, 0]) square([5, 6], center = true);
        translate([1.5, 2]) square([2, 1.2], center = true);
        translate([1.5, -2]) square([2, 1.2], center = true);
        stroke_path(wave_points(6, 2, 6), 1.0);
    }
}

module icon_media() {
    union() {
        translate([-2, 0]) polygon(points=[[ -3, -3], [3, 0], [-3, 3]]);
        translate([3, 0]) circle(r = 1.4, $fn = 24);
        translate([1.8, 0]) square([1.2, 4], center = true);
        translate([2.8, 1.6]) square([1.2, 2.4], center = true);
    }
}

module icon_wifi_mast() {
    union() {
        translate([0, -3]) square([1.2, 6], center = true);
        for (i = [0 : 2])
            difference() {
                circle(r = 2.5 + i * 1.5, $fn = 64);
                circle(r = 1.5 + i * 1.5, $fn = 64);
            }
        translate([0, 3.5]) circle(r = 0.9, $fn = 32);
    }
}

module icon_night_light() {
    difference() {
        circle(r = 4.5, $fn = 48);
        translate([1.5, 1.5]) circle(r = 4.5, $fn = 48);
    }
    for (angle = [30, 75, 120])
        rotate(angle)
            translate([4, 0]) circle(r = 0.8, $fn = 24);
}

module icon_heat_coils() {
    for (row = [-1, 0, 1])
        translate([0, row * 1.8])
            stroke_path([[ -4, -1], [ -2, 1], [0, -1], [2, 1], [4, -1]], 0.9);
}

module icon_short_beam() {
    translate([-2.5, 0]) square([3, 5], center = true);
    for (i = [-1 : 1])
        translate([1.5 + i * 2, 0])
            square([1.2, 3 - abs(i)], center = true);
}

module icon_long_beam() {
    translate([-3, 0]) square([4, 5.5], center = true);
    for (i = [-2 : 2])
        translate([1.8 + i * 1.5, 0])
            square([1.0, 4], center = true);
}

module stroke_path(points, width) {
    union() {
        for (p = points)
            translate(p) circle(d = width, $fn = 24);
        for (i = [0 : len(points) - 2])
            hull() {
                translate(points[i]) circle(d = width, $fn = 24);
                translate(points[i + 1]) circle(d = width, $fn = 24);
            }
    }
}

function wave_points(length, amplitude, steps) =
    [for (s = [0 : steps]) [
        s * length / steps - length / 2,
        sin(s * 180 / steps) * amplitude
    ]];

function hole_position(index) = [
    (index % cols - (cols - 1) / 2) * hole_spacing_x,
    (((rows - 1) / 2) - floor(index / cols)) * hole_spacing_y
];

boat_switch_panel();
