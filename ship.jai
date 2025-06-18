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

ship_floor_fan :: (uv: avec2) -> avec3 {
	x := uv.x;
	out := uv.y;

	sharpness: float64 = 0.7;
	pole := avec3.{0, sharpness*25, 0};
	lower_curve_offset := avec3.{x, sharpness*x*x, 0};

	return lerp(pole, lower_curve_offset, out);
}

flap_contour :: (uv: avec2) -> avec3 {
	x := uv.x;
	out := uv.y;

	sharpness: float64 = 0.7;
	upper_curve_offset := avec3.{2*x, sharpness*x*x, 3};
	lower_curve_offset := avec3.{x, sharpness*x*x, 0};

	return lerp(lower_curve_offset, upper_curve_offset, out);

//	return curve_offset + parabola_basis(x, sharpness)*up;
}

parabola_basis :: (x: float64, a: float64) -> amat3 {
	ijk: amat3 = ---;
	ijk.col[0] = avec3.{1, 2*a*x, 0}*(1/sqrt(1 + 4*a*a*x*x));
	ijk.col[1] = .{ijk._21, ijk._11, 0};
	ijk.col[2] = .{0, 0, 1};
	return ijk;
}
