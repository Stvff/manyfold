ship_surfaces: [..]Surface;

ship :: () -> *Surface {
	array_resize(*ship_surfaces, 2);
	ship := *(ship_surfaces[0]);
	ship_floor := *(ship_surfaces[1]);

	ship.* = .{
		name = "ship",
		u_domain = .{-PI/2, +PI/2, 20, .INCLUSIVE},
		v_domain = .{0, 1, 6, .EXCL_BEGIN},
		equation = flap_contour,
		v_begin_attach = .{.V_END, ship_floor, false},
	};

	ship_floor.* = .{
		name = "ship floor",
		u_domain = .{-PI/2, +PI/2, 20, .INCLUSIVE},
		v_domain = .{0, 1, 2, .POLE_BEGIN},
		equation = ship_floor_fan,
		v_end_attach = .{.V_BEGIN, ship, false},
	};

	return ship;
}

sharpness: float64 = 0.7;

ship_floor_fan :: (uv: avec2) -> avec3 {
	x := uv.x;
	out := uv.y;

	pole := avec3.{0, 0, 0};
	return lerp(pole, lower_curve_offset(x), out);
}

flap_contour :: (uv: avec2) -> avec3 {
	x := uv.x;
	out := uv.y;

	delta := upper_curve_offset(x) - lower_curve_offset(x);
	//delta.xy = normalize(delta.xy);

	b: amat3 = ---;
	b.col[0] = .{delta.x, delta.y, 0};
	b.col[1] = .{delta.y, delta.x, 0};
	b.col[2] = .{0, 0, delta.z};

	max_angle := PI/2;
	vi := ellipse((1 - out)*max_angle, 1, 1);
	v := avec3.{vi.x, 0, 1 - vi.y};

	return lower_curve_offset(x) + b*v;
//	return lerp(lower_curve_offset(x), upper_curve_offset(x), out);
}

upper_curve_offset :: (theta: float64) -> avec3 {
	return ellipse(theta, 17, 6) + .{0, 0, 2};
}

lower_curve_offset :: (theta: float64) -> avec3 {
	return ellipse(theta, 15, 3);
}

ellipse :: (theta: float64, semi_major: float64, semi_minor: float64) -> avec3 {
	return .{semi_major*cos(theta), semi_minor*sin(theta), 0};
}

parabola_basis :: (x: float64, a: float64) -> amat3 {
	ijk: amat3 = ---;
	ijk.col[0] = avec3.{1, 2*a*x, 0}*(1/sqrt(1 + 4*a*a*x*x));
	ijk.col[1] = .{ijk._21, ijk._11, 0};
	ijk.col[2] = .{0, 0, 1};
	return ijk;
}
