include <./libraries/BOSL2/std.scad>

$fs = $preview ? 1 : 0.05;
$fa = $preview ? 12 : 0.2;

film_slot=[9, 36, 14];
inner_slot=[18.3, 45, film_slot.z];
outer_slot=inner_slot + [4, 4, 0];
mask_slot = film_slot + [4, 0, 20];

function spiral(t1, t2, r1, r2, a1, a2) =
  let (
    t2 = t2 == undef ? t1 : t2,
    roff = (r2 - t2 - r1) / (a2 - a1),
    toff = (t2 - t1) / (a2 - a1)
  )
  concat(
    [for(a = [each [a1:$fa:a2], a2])
      let(r = r1 + roff * (a - a1))
        [r * sin(a), r * cos(a)]
    ],
    [for(a=[each [a2:$fa*-1:a1], a1])
      let(r = r1 + roff * (a - a1) + t1 + toff * (a - a1))
        [r * sin(a), r * cos(a)]
    ]
  );

function scanner_case_xy(x) =
  x < 0 ? 13.2 : x > 53 ? 0 :
  // function generated using hand measured points and Wolfram Alpha
  // fit { 0,13.2}, { 5,12.8}, {10,12.4}, {15,12.0}, {20,11.3},
  //     {25,10.4}, {30, 9.2}, {35, 7.9}, {40, 6.2}, {45, 5.0}, {50,3.4}
  -0.00329604 * pow(x, 2) - 0.0335618 * x + 13.1594;
  
function scanner_case(x1, x2) =
  concat(
    [[x1, 0]],
    [for(x = [each [x1:$fs:x2], x2]) [x, scanner_case_xy(x)]],
    [[x2, 0]]
  );
   
module spool(mask=false) {
  let(
    h1 = 40,
    r1 = 30,
    r2 = 42,
    sx = r1 + (r2 - r1) / (540 - 45) * 225,
    s1 = spiral(t1=2, r1=r1-2, r2=r2, a1=45, a2=540),
    u1 = union(s1, move([0, 0-r2], rect([sx, 2], anchor=[1,-1,0])))[0],
    h2 = 6,
    s2 = spiral(t1=4, r1=r1-4, r2=r2, a1=45, a2=540),
    u2 = union(s2, move([0, 0-r2], rect([sx, 4], anchor=[1,-1,0])))[0],
    s3 = spiral(t1=2, r1=r1-2, r2=sx, a1=45, a2=225),
    s4 = spiral(t1=4, r1=r1-2, r2=sx+2, a1=45, a2=225)
  )
  move([sx, r2-4, -2]) union() {
    if(!mask) {
      skin(
        profiles = [u2, u2, u1, u1, u2, u2],
        z=[0, h2, h2+4, h1-h2-4, h1-h2, h1],
        slices=0
      );
      skin(
        profiles = [s4, s4, s3, s3, s4, s4],
        z=[0, h2, h2+4, h1-h2-4, h1-h2, h1],
        slices=0
      );
      linear_extrude(height=2) difference() {
        union() {
          hull() region(s1);
          region(move([0, 0-r2], rect([sx, 18], anchor=[1,-1,0])));
        }
        circle(d=35);
      }
    } else {
      linear_extrude(height=h1)
        hull() region(s1);
    }
  }
}

module cylcube(size, r) {
  hull()
    for(pos=[[r, r], [size.x-r, r], [r, size.y-r], [size.x-r, size.y-r]])
      translate(pos)
        cylinder(r=r, h=size.z);
}

module connector() {
  difference() {
    translate((outer_slot - film_slot) * -0.5)
      cylcube(outer_slot, r=6);
      
    translate((inner_slot - film_slot) * -0.5)
      translate([0,0, -0.1])
        cylcube(inner_slot, r=4);
      
    translate((outer_slot - film_slot) * -0.5)
      translate([0, 0, film_slot.z])
        rotate([90, 0, 90]) mirror([0, 1, 0])
          translate([0, -0.01, -0.01])
            linear_extrude(height=outer_slot.x+0.02)
              polygon(scanner_case(x1=-0.01, x2=outer_slot.y+0.01));
  }
}

module spool_connector() {
  union() {
    color("yellow") difference() {
      hull() {
        intersection() {
          spool();
          rotate([90, 0, 90])
            linear_extrude(height=20)
              hull() projection() connector();
        }
        rotate([90, 0, 90])
          linear_extrude(height=0.01)
            projection() connector();
      }
      rotate([90, 0, 90])
        translate((mask_slot - film_slot) * -0.5)
          translate([0, 0, -0.01])
            cube(mask_slot);
    }

    color("orange")
      rotate([90, 0, 90]) mirror([0, 0, 1])
        connector();
  }
}

module scanner_spool() {
  union() {
    spool();
    difference() {
      top_half(z=-2)
        spool_connector();
      spool(mask=true);
    }
  }
}

scanner_spool();
