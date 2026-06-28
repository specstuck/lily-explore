// based on https://iquilezles.org/articles/ibilinear/
shader_type canvas_item;

uniform float topleft_x = 0.0;
uniform float topleft_y = 0.0;
uniform float topright_x = 1.0;
uniform float topright_y = 0.0;
uniform float bottomleft_x = 0.0;
uniform float bottomleft_y = 1.0;
uniform float bottomright_x = 1.0;
uniform float bottomright_y = 1.0;

float border(vec2 uv, float border_width) {
	vec2 bottom_left = step(vec2(border_width), uv);
	vec2 top_right = step(vec2(border_width), 1.0 - uv);
	return bottom_left.x * bottom_left.y * top_right.x * top_right.y;
}


float _cross( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

vec2 invBilinear( in vec2 p, in vec2 a, in vec2 b, in vec2 c, in vec2 d ) {
	vec2 res = vec2(-1.0);

	vec2 e = b-a;
	vec2 f = d-a;
	vec2 g = a-b+c-d;
	vec2 h = p-a;

	float k2 = _cross( g, f );
	float k1 = _cross( e, f ) + _cross( h, g );
	float k0 = _cross( h, e );

	// if edges are parallel, this is a linear equation
	if( abs(k2)<0.001 ) {
		res = vec2( (h.x*k1+f.x*k0)/(e.x*k1-g.x*k0), -k0/k1 );
	}
	// otherwise, it's a quadratic
	else {
		float w = k1*k1 - 4.0*k0*k2;
		if( w<0.0 ) return vec2(-1.0);
		w = sqrt( w );

		float ik2 = 0.5/k2;
		float v = (-k1 - w)*ik2;
		float u = (h.x - f.x*v)/(e.x + g.x*v);

		if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) {
		v = (-k1 + w)*ik2;
		   u = (h.x - f.x*v)/(e.x + g.x*v);
		}
		res = vec2( u, v );
	}

	return res;
}

void fragment(){
	vec2 newUV = invBilinear(UV, vec2(topleft_x, topleft_y), vec2(topright_x, topright_y),
		vec2(bottomright_x, bottomright_y), vec2(bottomleft_x, bottomleft_y));

	if (newUV.x < 0.0 || newUV.x > 1.0 || newUV.y < 0.0 || newUV.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, newUV);
	}

}