airco_surfaces: [..]Surface;

HOLE_RESOLUTION :: 6;
FRONT_WIDTH :: 23;
FRONT_HEIGHT :: 15;
HOLE_RADIUS :: 5;
HOLE_OFFSET_FROM_RIGHT :: 6;

airco :: () -> *Surface {
	array_add(*airco_surfaces, .{}, .{});
	hole := *(airco_surfaces[0]);
	front_left := *(airco_surfaces[1]);

	hole.* = .{
		name = "airco",
		u_domain = .{0, 1, HOLE_RESOLUTION, .INCLUSIVE},
		v_domain = .{0, 1, HOLE_RESOLUTION, .INCLUSIVE},
		equation = hole_top,
		u_begin_attach = .{.U_END, front_left, false},
	};

	front_left.* = .{
		name = "front bottom",
		u_domain = .{1, 0, HOLE_RESOLUTION, .EXCL_BEGIN},
		v_domain = .{0, 1, HOLE_RESOLUTION, .INCLUSIVE},
		equation = hole_left,
		u_end_attach = .{.U_BEGIN, hole, false},
	};

	return hole;
}

hole_top :: (uv: avec2) -> avec3 {
	x := uv.x;
	y := uv.y;
	top := avec3.{FRONT_WIDTH*(1 - x) - HOLE_OFFSET_FROM_RIGHT, FRONT_HEIGHT/2, 0};
	arc := ring((x-0.5)*PI/2 + PI/2, HOLE_RADIUS);
	return lerp(top, arc, y);
}

hole_left :: (uv: avec2) -> avec3 {
	x := uv.x;
	y := uv.y;
	top := avec3.{FRONT_WIDTH - HOLE_OFFSET_FROM_RIGHT, FRONT_HEIGHT*(x - 0.5), 0};
	arc := ring((x-0.5)*PI/2, HOLE_RADIUS);
	return lerp(top, arc, y);
}
