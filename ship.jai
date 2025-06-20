ship_surfaces: [..]Surface;

ship :: () -> *Surface {
	array_resize(*ship_surfaces, 2);
	ship := *(ship_surfaces[0]);
	ship_floor := *(ship_surfaces[1]);

	ship.* = .{
		name = "ship",
		u_domain = .{-5, 5, 20, .INCLUSIVE},
		v_domain = .{0, 1, 3, .EXCL_BEGIN},
		equation = flap_contour,
		v_begin_attach = .{.V_END, ship_floor, false},
	};

	ship_floor.* = .{
		name = "ship floor",
		u_domain = .{-5, 5, 20, .INCLUSIVE},
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

	p: avec3 = ---;
	delta := upper_curve_offset(x) - lower_curve_offset(x);


	delta.x = 0;
	return lerp(lower_curve_offset(x), upper_curve_offset(x), out);
}

upper_curve_offset :: (x: float64) -> avec3 {
	return lower_curve_offset(x) + .{0, 0, 3};
}

lower_curve_offset :: (x: float64) -> avec3 {
	semi_major :: 5.0;
	semi_minor :: 3.0;
	xi: float64 = ---;
	sign := ifx x >= 0 then 1 else -1;
	if sign == 1 {
		xi = semi_major - x;
	} else {
		xi = x + semi_major;
	}
	return .{xi, sign*(semi_minor/semi_major)*sqrt(semi_major*semi_major - xi*xi), 0};
}

parabola_basis :: (x: float64, a: float64) -> amat3 {
	ijk: amat3 = ---;
	ijk.col[0] = avec3.{1, 2*a*x, 0}*(1/sqrt(1 + 4*a*a*x*x));
	ijk.col[1] = .{ijk._21, ijk._11, 0};
	ijk.col[2] = .{0, 0, 1};
	return ijk;
}
