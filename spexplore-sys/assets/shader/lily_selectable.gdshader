shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

const mat3 sobelx = mat3(vec3(-1,-2,-1), vec3(0), vec3(1,2,1));
const mat3 sobely = mat3(vec3(-1,0,1), vec3(-2,0,2), vec3(-1,0,1));

void fragment() {
	//COLOR = texture(screen_texture, UV);
    //float avg = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
    //COLOR.rgb = vec3(avg);
	vec2 size = vec2(textureSize(screen_texture, 0));

	float sobelsumx = 0.0;
	float sobelsumy = 0.0;
	for(int x = -1; x < 1; x++){
		for(int y = -1; y < 1; y++){
			vec3 colorPix = texelFetch(screen_texture, ivec2(FRAGCOORD.xy) + ivec2(x-1,y-1), 0).rgb;
			float grayPix = colorPix.r / 3.0 + colorPix.g / 3.0 + colorPix.b / 3.0;
			sobelsumx += grayPix * sobelx[x + 1][y + 1];
			sobelsumy += grayPix * sobely[x + 1][y + 1];
		}
	}
	//vec4 n[9];
	//make_kernel( n, texture, gl_TexCoord[0].st);

	//vec4 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  	//vec4 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	//vec4 sobelsum = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
	
	//COLOR.rgb = sobelsumy
	//vec3 sobelsum = vec3(sqrt(pow(sobelsumx, 2.0) + pow(sobelsumy, 2)));
	COLOR = vec4(vec3(sobelsumx), 1);
}