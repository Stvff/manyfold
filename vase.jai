VASE_HEIGHT :: 2;
VASE_BASE_RADIUS :: 0.5;
VASE_THICKNESS :: 0.06;

ROTATIONAL_RES :: 120;
HEIGHT_RES :: 50;

vase_surfaces: [..]Surface;

make_vase :: () -> *Surface {
	array_add(*vase_surfaces, .{}, .{}, .{}, .{}, .{});
	body := *(vase_surfaces[0]);
	inner_body := *(vase_surfaces[1]);
	bottom := *(vase_surfaces[2]);
	inner_bottom := *(vase_surfaces[3]);
	rim := *(vase_surfaces[4]);

	body.* = Surface.{
		name = "vase",
		u_domain = .{ 0, 2*PI, ROTATIONAL_RES, .EXCL_END },
		v_domain = .{ 0, VASE_HEIGHT, HEIGHT_RES, .EXCL_BEGIN },
		equation = vase_body,
		v_begin_attach = .{.V_END, bottom, false},
		v_end_attach = .{.V_END, inner_body, true},
	};
	body.u_begin_attach = .{.U_END, body, false};
	body.u_end_attach = .{.U_BEGIN, body, false};

	bottom.* = Surface.{
		name = "bottom",
		u_domain = .{ 0, 2*PI, ROTATIONAL_RES, .EXCL_END },
		v_domain = .{ 0, VASE_BASE_RADIUS, 1, .POLE_BEGIN},
		equation = bottom_disk,
		v_end_attach = .{.V_BEGIN, body, false},
	};
	bottom.u_begin_attach = .{.U_END, bottom, false};
	bottom.u_end_attach = .{.U_BEGIN, bottom, false};

	inner_body.* = Surface.{
		name = "inner body",
		u_domain = .{ 0, 2*PI, ROTATIONAL_RES, .EXCL_END },
		v_domain = .{ VASE_THICKNESS, VASE_HEIGHT, HEIGHT_RES/3, .EXCL_BEGIN | .EXCL_END},
		equation = vase_inner_body,
		v_begin_attach = .{.V_END, inner_bottom, false},
		v_end_attach = .{.V_END, body, true},
	};
	inner_body.u_begin_attach = .{.U_END, inner_body, false};
	inner_body.u_end_attach = .{.U_BEGIN, inner_body, false};

	inner_bottom.* = Surface.{
		name = "inner bottom",
		u_domain = .{ 0, 2*PI, ROTATIONAL_RES, .EXCL_END },
		v_domain = .{ 0, VASE_BASE_RADIUS-VASE_THICKNESS, 1, .POLE_BEGIN },
		equation = inner_bottom_disk,
		v_end_attach = .{.V_BEGIN, inner_body, false},
	};
	inner_bottom.u_begin_attach = .{.U_END, inner_bottom, false};
	inner_bottom.u_end_attach = .{.U_BEGIN, inner_bottom, false};

	return body;
}

vase_body :: (uv: avec2) -> avec3 {
	theta := uv.x;
	z := uv.y;

	offset := ring(theta, VASE_BASE_RADIUS);
	i, j, k := ring_basis_vectors(theta);
	profile := vase_side_profile(z);
	return profile.x*i + profile.y*j + profile.z*k + offset;
}

vase_inner_body :: (uv: avec2) -> avec3 {
	theta := uv.x;
	z := uv.y;

	offset := ring(theta, VASE_BASE_RADIUS - VASE_THICKNESS);
	i, j, k := ring_basis_vectors(theta);
	profile := vase_side_profile(z);
	return profile.x*i + profile.y*j + profile.z*k + offset;
}

vase_side_profile :: (z: float64) -> avec3 {
	return .{0.1*sin(z*(1.75*PI)/VASE_HEIGHT), 0, z};
}

bottom_disk :: (uv: avec2) -> avec3 {
	theta := uv.x;
	x := uv.y;
	xy := ring(theta, x);
	return .{xy.x, xy.y, 0};
}

inner_bottom_disk :: (uv: avec2) -> avec3 {
	theta := uv.x;
	x := uv.y;
	xy := ring(theta, x);
	return .{xy.x, xy.y, VASE_THICKNESS};
}

/* Common functions, could (should) be split off into its own file/library */
ring :: (theta: float64, radius: float64) -> avec3 {
	return .{radius*cos(theta), radius*sin(theta), 0};
}

ring_basis_vectors :: (theta: float64) -> avec3, avec3, avec3 {
	i := avec3.{cos(theta), sin(theta), 0};
	j := avec3.{-sin(theta), cos(theta), 0};
	k := avec3.{0, 0, 1};
	return i, j, k;
}
