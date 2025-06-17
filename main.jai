main :: () {
	square := Surface.{
		name = "square",
		u_domain = .{
			0, 2, 5, .INCLUSIVE
		},
		v_domain = .{
			0, 1, 5, .INCLUSIVE
		},
		equation = (uv: avec2) -> avec3 { return .{uv.x, uv.y, 0}; },
	};

	sphere := Surface.{
		name = "sphere",
		u_domain = .{
			0, 2*PI, 50, .EXCL_END
		},
		v_domain = .{
			0, PI, 50, .DIPOLE
		},
		equation = (uv: avec2) -> avec3 { return .{cos(uv.x)*sin(uv.y), sin(uv.x)*sin(uv.y), cos(uv.y)}; },
	};
	sphere.u_begin_attach = .{.U_END, *sphere, false};
	sphere.u_end_attach = .{.U_BEGIN, *sphere, false};

	ply_from_surface(*square, .NO_FAULTS);
	ply_from_surface(*sphere);
	ply_from_surface(make_vase());
}

#load "vase.jai";
#import "geoalg64";
#import "Basic";
#import "Math";
#import "manyfold";
