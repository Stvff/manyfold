/* The rotations and coordinate system in this module is righthanded.

   The ordering of a bivector is right-handed when, if you curl your right hand along with
   two basisvectors, the direction of your thumb is in the same direction as the third basisvector.

   To explain 'curling your right hand along with two basisvectors' in detail, I will give a small
   problem description and guide.

   ## Problem description

   In geometric algebra, multiplying two basis vectors results in a bivector.
   In 3D, there are three possible combinations of basis vectors:
   x and y
   y and z
   z and x
   Furthermore, in geometric algebra, the order of the multiplication changes the sign:
   xy = -yx    so    -xy = yx
   yz = -zy    so    -yz = zy
   zx = -xz    so    -zx = xz
   But when you make a rotor struct, which has the three possible bivectors in it, which should
   you store? xy, or yx? Because when you're doing math, this changes the sign of things, and
   importantly, the directions in which things rotate when you rotate them.
   So, we stick to a convention: we want the coordinate system to be righthanded.

   ## Handedness guide

   Hold your right hand forward, fingers forward, palm upwards, thumb out (so as if you were receiving a
   a stack of money).
   Then, point your fingers up (leaving your thumb as-is).
   If +x is forward, and +y is up, you just curled your hand along with an xy ordered bivector.

   You'll notice that your thumb is pointing to your right. This means +z must be in that direction
   for this to be a right-handed coordinate system.
   (a fun excercise to the reader is to find out which handedness your preferred coordinate system is)

   In this coordinate system, let's now see what the right-handed ordering is for the two basisvectors
   y and z.
   First, let's try zy:
   +z is to the right, so we hold out our hand to right, then y is up, so we point our fingers up.
   You'll find that your thumb is pointed backwards. This is not the direction of our earlier decision
   to have +x be forward, so zy is not the righthanded ordering of the bivector in our coordinate system.
   With this knowledge, let's try yz:
   +y is up, so hand up, +z is to the right, so fingers to the right (a wierd pose we're in hah). Now
   our thumb is pointed forward, in agreement with +x.

   Finally, x and z:
   I'm inclined to let you figure this one out on your own, but I'll tell you, the righthanded ordering is indeed zx

   So that is why the bivectors have the order that they do in this module.

   ## Practical implications and ease of debugging

   Now to figure out in which direction a rotor rotates, you can do the following:
   Pick a bivector of the rotor. Curl your fingers along with the bivector as demonstrated earlier,
   and then, if the value of the bivector is positive, that's the direction in which that bivector
   will rotate. If the value is negative, point your thumb in the opposite direction, and that
   is the direction in which it will rotate.

   However, because this module is fully righthanded, there is an even simpler way.
   Pick a bivector, then take the axis that is _not_ in the name. So for xy, it's z.
   Point your thumb along that direction (positive xy to positive z, negative xy to negative z),
   curl your fingers, and there it is: the direction in which that bivector rotates your vector.

*/

Bivector3 :: struct {
	xy: float64;
	yz: float64;
	zx: float64;
}

Rotor :: struct {
	a: float64;
	using b: Bivector3;
}

Trivector3 :: struct {
	using v: avec3;
	xyz: float64;
}

/* This returns an xy Bivector */
operator ^ :: (a: Vector2, b: Vector2) -> float64 {
	return a.x*b.y - a.y*b.x;
}

operator ^ :: (a: avec3, b: avec3) -> Bivector3 {
	return .{
		xy = a.x*b.y - a.y*b.x,
		yz = a.y*b.z - a.z*b.y,
		zx = a.z*b.x - a.x*b.z
	};
}

/*
  operator * between two vectors is already defined, so I can't overload it with a different return type.
  Alternatively, it's always {a dot b, a ^ b}, so not the end of the world.
  For now, I'll provide it as 'mul'.
*/
mul :: (a: avec3, b: avec3) -> Rotor {
 	return .{
 		dot(a, b),
		a ^ b
	};
}

operator * :: (p: Rotor, q: Rotor) -> Rotor {
	return .{
		a  = p.a*q.a  - p.xy*q.xy - p.yz*q.yz - p.zx*q.zx,
		xy = p.a*q.xy + p.xy*q.a  - p.yz*q.zx + p.zx*q.yz,
		yz = p.a*q.yz + p.xy*q.zx + p.yz*q.a  - p.zx*q.xy,
		zx = p.a*q.zx - p.xy*q.yz + p.yz*q.xy + p.zx*q.a
	};
}

/* These return a normal vector, and an xyz trivector */
operator * :: (r: Rotor, v: avec3) -> Trivector3 {
	vec := avec3.{
		x = r.a*v.x + r.xy*v.y /* r.yz */ - r.zx*v.z,
		y = r.a*v.y - r.xy*v.x + r.yz*v.z /* r.zx */,
		z = r.a*v.z /* r.xy */ - r.yz*v.y + r.zx*v.x
	};
	xyz := r.xy*v.z + r.yz*v.x + r.zx*v.y;
	return .{vec, xyz};
}

operator * :: (v: avec3, r: Rotor) -> Trivector3 {
	vec := avec3.{
		x =  v.x*r.a  - v.y*r.xy + v.z*r.zx,
		y =  v.x*r.xy + v.y*r.a  - v.z*r.yz,
		z = -v.x*r.zx + v.y*r.yz + v.z*r.a
	};
	xyz := v.x*r.yz + v.y*r.zx + v.z*r.xy;
	return .{vec, xyz};
}

operator * :: (f: float64, r: Rotor) -> Rotor #symmetric {
	return .{
		a  = f*r.a ,
		xy = f*r.xy,
		yz = f*r.yz,
		zx = f*r.zx
	};
}

operator * :: (f: float64, b: Bivector3) -> Bivector3 #symmetric {
	return .{
		xy = f*b.xy,
		yz = f*b.yz,
		zx = f*b.zx
	};
}

reverse :: (r: Rotor) -> Rotor {
	return .{
		a = r.a,
		xy = -r.xy,
		yz = -r.yz,
		zx = -r.zx
	};
}

length :: (r: Rotor) -> float64 {
	return sqrt(r.a*r.a + r.xy*r.xy + r.yz*r.yz + r.zx*r.zx);
}

length_squared :: (r: Rotor) -> float64 {
	return r.a*r.a + r.xy*r.xy + r.yz*r.yz + r.zx*r.zx;
}

normalize :: (b: Bivector3) -> Bivector3 {
	mag := 1/length(b);
	return b*mag;
}

normalize :: (r: Rotor) -> Rotor {
	mag := length(r);
	if mag <= 0 then return .{a = -1.0, xy = 0.0, yz = 0.0, zx = 0.0};
	return (1/mag)*r;
}

inverse :: (r: Rotor) -> Rotor {
	inv_mag_sq := -length_squared(r);
	return inv_mag_sq*Rotor.{a = -r.a, b = r.b};
}

/* Expects a normalized rotor. */
rotate :: (r: Rotor, v: avec3) -> avec3 {
	// rotated vector = -(r * v) * rev(r)
	// However, in the second part, the trivector is always zero
	// and (vec * rotor) = (rev(rotor) * vec), so the reverse cancels out
	// so we do the second part inline

	// un-inlined, this code looks like this:
	// t := r * v;
	// cr := reverse(r);
	// t2 := t.v * cr;
	// t2.v -= .{-t.xyz*cr.yz, -t.xyz*cr.zx, -t.xyz*cr.xy};
	// return t2.v;

	t  := r*v;
	rr := reverse(r);
	t2 := t.v*rr;
	return .{
		x = t2.v.x - t.xyz*rr.yz,
		y = t2.v.y - t.xyz*rr.zx,
		z = t2.v.z - t.xyz*rr.xy
	};

	// t := r*v;
	// vec, xyz := t.v, t.xyz;
	// return .{
	// 	x = r.a*vec.x + r

	// 	r.a*vec.x + r.xy*vec.y + r.xz*vec.z + xyz*r.yz,
	// 	r.a*vec.y - r.xy*vec.x + r.yz*vec.z - xyz*r.xz,
	// 	r.a*vec.z - r.xz*vec.x - r.yz*vec.y + xyz*r.xy
	// };
}

/* Expects a normalized bivector. */
rotor_angle_plane :: (angle_radians: float64, plane: Bivector3) -> Rotor {
	sin_of_angle := -sin(angle_radians*0.5);
	return .{
		a = cos(angle_radians*0.5),
		b = sin_of_angle * plane
	};
}

rotor_between :: (from: avec3, to: avec3) -> Rotor {
	return normalize(.{
		a = 1 + dot(from, to),
		b = to ^ from
	});
}

matrix_from_rotor :: (r: Rotor) -> Matrix3 {
	x_axis := vec_cast(rotate(r, .{1, 0, 0}));
	y_axis := vec_cast(rotate(r, .{0, 1, 0}));
	z_axis := vec_cast(rotate(r, .{0, 0, 1}));
	return make_matrix_from_rows(x_axis, y_axis, z_axis, Matrix3);
}

#load "astronomic_vec.jai";
