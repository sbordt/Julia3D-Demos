{{GLSL_VERSION}}

{{in}} vec3 N;
{{in}} vec3 V;

uniform vec3 material_ambient;
uniform vec3 material_specular;
uniform vec3 material_diffuse;

uniform vec3 light_position;
uniform vec3 light_ambient;
uniform vec3 light_specular;
uniform vec3 light_diffuse;

{{out}} vec4 fragment_color;

vec3 blinn_phong(vec3 N, vec3 V, vec3 L)
{
    float shininess = 1.0; 
    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    float spec_coeff = pow(max(dot(H,N), 0.0), shininess);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  light_ambient * material_ambient +
            light_diffuse * material_diffuse * diff_coeff +
            light_specular * material_specular * spec_coeff;
}


void main(){
    vec3 L = normalize(light_position - V);
    fragment_color = vec4(blinn_phong(N, V, L), 1);
}
