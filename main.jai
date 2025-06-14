Range_Kind :: enum_flags u8 {
	EXCL_BEGIN;
	EXCL_END;
	POLE_BEGIN;
	POLE_END;

	CONSTANT;
	INDEFINITE;

	//INCL_END :: EXCL_BEGIN;
	//INCL_BEGIN :: EXCL_END;
	INCLUSIVE :: 0;
	EXCLUSIVE :: EXCL_BEGIN | EXCL_END;
	DIPOLE :: POLE_BEGIN | POLE_END;

	//INCL_POLE_BEGIN :: INCL_BEGIN | POLE_BEGIN;
	//INCL_POLE_END :: INCL_END | POLE_END;
	EXCL_POLE_BEGIN :: EXCL_BEGIN | POLE_BEGIN;
	EXCL_POLE_END :: EXCL_END | POLE_END;
}

Range :: struct {
	begin, end: float64;
	resolution: int;
	kind: Range_Kind;
}

Has :: struct {
	left_side, right_side, bottom_side, top_side,
	left_pole, right_pole, bottom_pole, top_pole,
	left_bottom_corner, right_bottom_corner, left_top_corner, right_top_corner: bool;
}

Surface :: struct {
	name: string;
	u_domain: Range;
	v_domain: Range;
	equation: (avec2) -> avec3;
	normal: (avec2) -> avec3;
	surface_start: int;
	has: Has;
	u_begin_attach: Surface_Attachment;
	u_end_attach: Surface_Attachment;
	v_begin_attach: Surface_Attachment;
	v_end_attach: Surface_Attachment;
}

Surface_Attachment_Kind :: enum u8 {
	U_BEGIN; U_END; V_BEGIN; V_END;
}
Surface_Attachment :: struct {
	kind: Surface_Attachment_Kind;
	surface: *Surface;
	reversed := false;
}

Triangle :: [3]int;

main :: () {
	square := Surface.{
		u_domain = .{
			0, 2, 5, .INCLUSIVE
		},
		v_domain = .{
			0, 1, 5, .INCLUSIVE
		},
		equation = (uv: avec2) -> avec3 { return .{uv.x, uv.y, 0}; },
	};

	sphere := Surface.{
		u_domain = .{
			0, 2*PI, 50, .EXCL_END
		},
		v_domain = .{
			0, PI/2.0, 50, .POLE_BEGIN
		},
		equation = (uv: avec2) -> avec3 { return .{cos(uv.x)*sin(uv.y), sin(uv.x)*sin(uv.y), cos(uv.y)}; },
	};
	sphere.u_end_attach = .{.U_BEGIN, *sphere, false};

	already_done: [..]*Surface;

	the_main_surface := make_vase();
	vertices: [..]avec3;
	triangles: [..]Triangle;
	generate_vertices(*vertices, the_main_surface, *already_done);
	print("%\n", vertices.count);
	array_reset(*already_done);
	triangulate(*triangles, the_main_surface, *vertices, *already_done);
	//print("%\n", triangles);

	write_ply("vase", vertices, triangles);

}

generate_vertices :: (vertices: *[..]avec3, using surface: *Surface, already_done: *[..]*Surface) {
	if !surface return;
	if array_find(already_done.*, surface) return;
	surface_start = vertices.count;

	du := (u_domain.end - u_domain.begin)/cast(float64, u_domain.resolution);
	dv := (v_domain.end - v_domain.begin)/cast(float64, v_domain.resolution);

	has.left_side = !cast(bool, u_domain.kind & .EXCL_POLE_BEGIN);
	has.right_side = !cast(bool, u_domain.kind & .EXCL_POLE_END);
	has.bottom_side = !cast(bool, v_domain.kind & .EXCL_POLE_BEGIN);
	has.top_side = !cast(bool, v_domain.kind & .EXCL_POLE_END);

	has.left_pole = u_domain.kind & (.POLE_BEGIN | .EXCLUSIVE) == .POLE_BEGIN;
	has.right_pole = u_domain.kind & (.POLE_END | .EXCLUSIVE) == .POLE_END;
	has.bottom_pole = v_domain.kind & (.POLE_BEGIN | .EXCLUSIVE) == .POLE_BEGIN;
	has.top_pole = v_domain.kind & (.POLE_END | .EXCLUSIVE) == .POLE_END;

	has.left_bottom_corner = (has.left_side && has.bottom_side) || has.left_pole || has.bottom_pole;
	has.right_bottom_corner = (has.right_side && has.bottom_side) || has.right_pole;
	has.left_top_corner = (has.left_side && has.top_side) || has.top_pole;
	has.right_top_corner = (has.right_side && has.top_side);

	print("generating vertices for: %\n", name);
	for v_i: 0..v_domain.resolution {
		v := v_domain.begin + v_i*dv;
		is_first_v := v_i == 0;
		is_last_v := v_i == v_domain.resolution;
	for u_i: 0..u_domain.resolution {
		//print("%, %; ", u_i, v_i);
		u := u_domain.begin + u_i*du;
		is_first_u := u_i == 0;
		is_last_u := u_i == u_domain.resolution;

		make_point := !(is_first_u || is_last_u || is_first_v || is_last_v);

		make_point ||= has.left_bottom_corner && is_first_u && is_first_v;
		make_point ||= has.right_bottom_corner && is_last_u && is_first_v;
		make_point ||= has.left_top_corner && is_first_u && is_last_v;
		make_point ||= has.right_top_corner && is_last_u && is_last_v;

		make_point ||= has.left_side && is_first_u && !is_first_v && !is_last_v;
		make_point ||= has.right_side && is_last_u && !is_first_v && !is_last_v;
		make_point ||= has.bottom_side && is_first_v && !is_first_u && !is_last_u;
		make_point ||= has.top_side && is_last_v && !is_first_u && !is_last_u;

		if !make_point {
			//print("skipped, \n");
			continue;
		}

		array_add(vertices, equation(.{u, v}));
	}}
	array_add(already_done, surface);

	generate_vertices(vertices, u_begin_attach.surface, already_done);
	generate_vertices(vertices, u_end_attach.surface, already_done);
	generate_vertices(vertices, v_begin_attach.surface, already_done);
	generate_vertices(vertices, v_end_attach.surface, already_done);
}

get_index :: (using surface: *Surface, u: int, v: int) -> int {
	if u == 0 {
		if has.left_pole then v = 0;
	} else if u == u_domain.resolution {
		if has.right_pole then v = 0;
	}
	if v == 0 {
		if has.bottom_pole then u = 0;
	} else if v == u_domain.resolution {
		if has.top_pole then u = 0;
	}

	attachment: Surface_Attachment;
	rev_u := u_domain.resolution - u;
	rev_v := v_domain.resolution - v;
	new_t: [4]int;
	rev_t: int;

	if u == 0 && u_domain.kind & .EXCL_BEGIN {
		attachment = u_begin_attach;
		new_t = .[rev_v, v, v, rev_v];
		rev_t = v_domain.resolution;
	} else if u == u_domain.resolution && u_domain.kind & .EXCL_END {
		attachment = u_end_attach;
		new_t = .[v, rev_v, rev_v, v];
		rev_t = v_domain.resolution;
	} else if v == 0 && v_domain.kind & .EXCL_BEGIN {
		attachment = v_begin_attach;
		new_t = .[u, rev_u, rev_u, u];
		rev_t = u_domain.resolution;
	} else if v == v_domain.resolution && v_domain.kind & .EXCL_END {
		attachment = v_end_attach;
		new_t = .[rev_u, u, u, rev_u];
		rev_t = u_domain.resolution;
	}

	if attachment.surface {
		if attachment.reversed {
			new_t[0] = rev_t - new_t[0];
			new_t[1] = rev_t - new_t[1];
			new_t[2] = rev_t - new_t[2];
			new_t[3] = rev_t - new_t[3];
		}
		new_u, new_v: int;
		if attachment.kind == {
			case .U_BEGIN;
				new_u = 0;
				new_v = new_t[0];
			case .U_END;
				new_u = attachment.surface.u_domain.resolution;
				new_v = new_t[1];
			case .V_BEGIN;
				new_u = new_t[2];
				new_v = 0;
			case .V_END;
				new_u = new_t[3];
				new_v = attachment.surface.v_domain.resolution;
		}
		i := get_index(attachment.surface, new_u, new_v);
		print("% to %: %\n", name, attachment.surface.name, i);
		return i;
	}


	if v == 0 {
		return surface_start + u;
	}

	bottom_row := (u_domain.resolution-1) * cast(int, has.bottom_side) + cast(int) has.left_bottom_corner + cast(int) has.right_bottom_corner;
	row_size := (u_domain.resolution-1) + cast(int, has.left_side) + cast(int, has.right_side);

	bottom_row -= cast(int, v == v_domain.resolution && !has.left_top_corner);

	return surface_start + u + bottom_row + (v-1)*row_size;
}

triangulate :: (triangles: *[..]Triangle, using surface: *Surface, vertices: *[..]avec3, already_done: *[..]*Surface) {
	if !surface return;
	if array_find(already_done.*, surface) return;

	print("triangulating: %\n", name);
	for v_i: 0..v_domain.resolution-1 {
		is_first_v := v_i == 0;
		is_last_v := v_i == v_domain.resolution;
	for u_i: 0..u_domain.resolution-1 {
		//print("%, %;\n ", u_i, v_i);
		is_first_u := u_i == 0;
		is_last_u := u_i == u_domain.resolution;

		triangle_a, triangle_b: Triangle;
		triangle_a[0] = get_index(surface, u_i, v_i);
		triangle_a[1] = get_index(surface, 1 + u_i, 1 + v_i);
		triangle_a[2] = get_index(surface, u_i, 1 + v_i);

		triangle_b[0] = get_index(surface, u_i, v_i);
		triangle_b[1] = get_index(surface, 1 + u_i, v_i);
		triangle_b[2] = get_index(surface, 1 + u_i, 1 + v_i);

		if !(triangle_a[0] == triangle_a[1] || triangle_a[1] == triangle_a[2] || triangle_a[0] == triangle_a[2])
			array_add(triangles, triangle_a);
		if !(triangle_b[0] == triangle_b[1] || triangle_b[1] == triangle_b[2] || triangle_b[0] == triangle_b[2])
			array_add(triangles, triangle_b);

	}}
	array_add(already_done, surface);

	triangulate(triangles, u_begin_attach.surface, vertices, already_done);
	triangulate(triangles, u_end_attach.surface, vertices, already_done);
	triangulate(triangles, v_begin_attach.surface, vertices, already_done);
	triangulate(triangles, v_end_attach.surface, vertices, already_done);
}

write_ply :: (name: string, vertices: []avec3, faces: []Triangle) {
	sb: String_Builder;
	print(*sb, #string PLY_HEADER
ply
format binary_little_endian 1.0
comment made by meeee >:3
element vertex %1
property double x
property double y
property double z
element face %2
property list uchar uint vertex_index
end_header
PLY_HEADER, vertices.count, faces.count);

	full_file: [..]u8;
	defer array_reset(*full_file);
	array_add(*full_file, ..cast([]u8) builder_to_string(*sb));

	evil_byte_vertices: []u8;
	evil_byte_vertices.data = xx vertices.data;
	evil_byte_vertices.count = vertices.count*size_of(avec3);
	array_add(*full_file, ..evil_byte_vertices);

	for face: faces {
		array_add(*full_file, 3);
		evil_byte_face: []u8;
		evil_byte_face.data = xx *face;
		evil_byte_face.count = 4;
		array_add(*full_file, ..evil_byte_face);
		evil_byte_face.data += 8;
		array_add(*full_file, ..evil_byte_face);
		evil_byte_face.data += 8;
		array_add(*full_file, ..evil_byte_face);
	}

	write_entire_file(sprint("%.ply", name), full_file.data, full_file.count);
	reset(*sb);
}

#import "geoalg64";
#import "Basic";
#import "Math";
#import "File";
#load "vase.jai";
