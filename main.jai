Range_Kind :: enum_flags u8 {
	EXCLUSIVE;
	EXCL_BEGIN;
	EXCL_END;
	CONSTANT;
	PINCH_BEGIN;
	PINCH_END;
	INDEFINITE;
	CLOSED;

	INCL_END :: EXCL_BEGIN;
	INCL_BEGIN :: EXCL_END;
	INCLUSIVE :: INCL_BEGIN | INCL_END;
	PINCHED :: PINCH_BEGIN | PINCH_END;
}

Range :: struct {
	begin, end: float64;
	kind: Range_Kind;
}

Surface :: struct {
	u_domain: Range;
	v_domain: Range;
	equation: (avec2) -> avec3;
	normal: (avec2) -> avec3;
}

Line :: struct {
	domain: Range;
	equation: (float64) -> avec2;
	normal: (float64) -> avec2;
}

Triangle :: [3]u32;

spatial_resolution := 0.5;

main :: () {
	square := Surface.{
		u_domain = .{
			0, 2, .INCLUSIVE
		},
		v_domain = .{
			0, 1, .INCLUSIVE
		},
		equation = (uv: avec2) -> avec3 { return .{uv.x, uv.y, 0}; },
		normal = (uv: avec2) -> avec3 { return .{0, 0, 1}; }
	};


	//print("%\n", square);
	write_ply("square", .[.{0, 0, 0}, .{0, 1, 0}, .{1, 0, 0}, .{1, 1, 0}], .[.[0, 1, 2], .[1, 3, 2]]);

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
		evil_byte_face.data += 4;
		array_add(*full_file, ..evil_byte_face);
		evil_byte_face.data += 4;
		array_add(*full_file, ..evil_byte_face);
	}

	write_entire_file(sprint("%.ply", name), full_file.data, full_file.count);
	reset(*sb);
}

#import "geoalg64";
#import "Basic";
#import "File";
