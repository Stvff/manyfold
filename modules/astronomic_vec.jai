/*** Vectors ***/

avec2 :: struct {
    x, y: float64;

#place x;
    component: [2] float64 = ---;
}

avec3 :: struct {
	x, y, z: float64;

#place x;
    xy: avec2 = ---;
#place y;
    yz: avec2 = ---;

#place x;
	component: [3]float64 = ---;
}

dot :: (a: avec2, b: avec2) -> float64 {
	return a.x*b.x + a.y*b.y;
}

dot :: (a: avec3, b: avec3) -> float64 {
	return a.x*b.x + a.y*b.y + a.z*b.z;
}

length :: (a: avec2) -> float64 {
    return sqrt(a.x*a.x + a.y*a.y);
}

length :: (a: avec3) -> float64 {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
}

length_squared :: inline (a: avec2) -> float64 {
    return a.x*a.x + a.y*a.y;
}

length_squared :: inline (a: avec3) -> float64 {
    return a.x*a.x + a.y*a.y + a.z*a.z;
}

normalize :: (v: avec2, $epsilon := 0.0, $fallback := avec2.{}) -> avec2 {
	mag := length(v);
	if mag <= epsilon {
		return fallback;
	}

	inv_mag := 1/mag;
	return v*inv_mag;
}

normalize :: (v: avec3, $epsilon := 0.0, $fallback := avec3.{}) -> avec3 {
	mag := length(v);
	if mag <= epsilon {
		return fallback;
	}

	inv_mag := 1/mag;
	return v*inv_mag;;
}

operator + :: (a: avec2, b: avec2) -> avec2 {
    return .{a.x+b.x, a.y+b.y};
}

operator - :: (a: avec2, b: avec2) -> avec2 {
    return .{a.x-b.x, a.y-b.y};
}

operator - :: (a: avec2) -> avec2 {
    return .{-a.x, -a.y};
}

operator * :: (a: avec2, k: float64) -> avec2  #symmetric {
    return .{a.x*k, a.y*k};
}

operator + :: (a: avec3, b: avec3) -> avec3 {
    return .{a.x+b.x, a.y+b.y, a.z+b.z};
}

operator - :: (a: avec3, b: avec3) -> avec3 {
    return .{a.x-b.x, a.y-b.y, a.z-b.z};
}

operator - :: (a: avec3) -> avec3 {
    return .{-a.x, -a.y, -a.z};
}

operator * :: (a: avec3, k: float64) -> avec3  #symmetric {
    return .{a.x*k, a.y*k, a.z*k};
}

vec_cast :: (a: avec2) -> Vector2 {
	return .{cast(float, a.x), cast(float, a.y)};
}

vec_cast :: (a: avec3) -> Vector3 {
	return .{cast(float, a.x), cast(float, a.y), cast(float, a.z)};
}

lerp :: (a: avec2, b: avec2, t: float64) -> avec2 {
	return (1 - t)*a + t*b;
}

lerp :: (a: avec3, b: avec3, t: float64) -> avec3 {
	return (1 - t)*a + t*b;
}

/*** Matrices ***/

amat3 :: struct { /* column-major because it is convenient for basisvector calculations */
	/* these numbers are _rowcol */
	_11, _21, _31: float64;
	_12, _22, _32: float64;
	_13, _23, _33: float64;

	#place _11; col:  [3]avec3;
	#place _11; coef: [3][3]float64;
}

operator * :: (mat: amat3, vec: avec3) -> avec3 {
	return mat.col[0]*vec.x + mat.col[1]*vec.y + mat.col[2]*vec.z;
}

operator * :: (a: amat3, b: amat3) -> amat3 {
	c: amat3 = ---;
	c.col[0] = a.col[0]*b._11 + a.col[1]*b._21 + b.col[2]*b._31;
	c.col[1] = a.col[0]*b._12 + a.col[1]*b._22 + b.col[2]*b._32;
	c.col[0] = a.col[0]*b._13 + a.col[1]*b._23 + b.col[2]*b._33;
	return c;
}

#import "Math";
