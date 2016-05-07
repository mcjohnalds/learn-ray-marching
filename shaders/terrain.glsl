precision mediump float;
uniform vec2 resolution;
uniform float time;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float minDistance = 0.01;
const float drawDistance = 100.0;
const int maxMarches = 2000;
const vec3 camPos = vec3(0.0, 10.0, 0.0);

vec3 mod289(vec3 v){return v-floor(v*(1./289.))*289.;}vec2 mod289(vec2 v){return v-floor(v*(1./289.))*289.;}vec3 permute(vec3 v){return mod289((v*34.+1.)*v);}float snoise(vec2 v){const vec4 d=vec4(.211325,.366025,-.57735,.0243902);vec2 r=floor(v+dot(v,d.gg)),g=v-r+dot(r,d.rr),a;a=g.r>g.g?vec2(1.,0.):vec2(0.,1.);vec4 m=g.rgrg+d.rrbb;m.rg-=a;r=mod289(r);vec3 b=permute(permute(r.g+vec3(0.,a.g,1.))+r.r+vec3(0.,a.r,1.)),f=max(.5-vec3(dot(g,g),dot(m.rg,m.rg),dot(m.ba,m.ba)),0.);f=f*f;f=f*f;vec3 p=2.*fract(b*d.aaa)-1.,e=abs(p)-.5,o=floor(p+.5),c=p-o;f*=1.79284-.853735*(c*c+e*e);vec3 s;s.r=c.r*g.r+e.r*g.g;s.gb=c.gb*m.rb+e.gb*m.ga;return 130.*dot(f,s);}

// The sky light emits straight downwards everywhere equally
const vec3 skyLightColor = vec3(0.57, 0.87, 0.88) * 0.65;

// Sun point light
const vec3 sunLightPos = vec3(10.0, 10.0, -200.0);
const vec3 sunLightColor = vec3(0.98, 0.87, 0.57) * 1.5;

const vec3 materialColor = vec3(0.70, 0.95, 0.40);

mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

float terrain(float x, float z) {
    return pow(snoise(vec2(x * 1.1, pow(z, 0.9)) * 0.02), 4.0) * 8.0 +
           snoise(vec2(x, z) * 0.01);
}

vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution;
    vec2 screen = 2.0 * ndc - 1.0;
    float ar = resolution.x / resolution.y;
    float f = tan(fov / 2.0 * pi / 180.0);
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

vec3 getNormal(vec3 p) {
    float e = 0.001;
    vec3 n = vec3(
        terrain(p.x - e, p.z) - terrain(p.x + e, p.z),
        2.0 * e,
        terrain(p.x, p.z - e) - terrain(p.x, p.z + e)
    );
    return normalize(n);
}

float diffuse(vec3 p, vec3 n, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.0);
    return clamp(iDiff, 0.0, 1.0);
}

vec3 getShading(vec3 p, vec3 n) {
    float iSky = diffuse(p, n, p + vec3(0.0, 1.0, 0.0));
    float iSun = diffuse(p, n, sunLightPos);

    return materialColor * (skyLightColor * iSky + sunLightColor * iSun);
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rotateXYZ(-0.5, 0.0, 0.0) * rayDirection();
    
    vec3 p = ro + rd * minDistance;
    const float dt = (drawDistance - minDistance) / float(maxMarches);
    bool hit = false;
    for (float t = minDistance; t < drawDistance; t += dt) {
        p = ro + rd * t;
        
        if (p.y < terrain(p.x, p.z)) {
            hit = true;
            break;
        }
    }
    
    if (hit) {
        vec3 n = getNormal(p);
        vec3 s = getShading(p, n);
        gl_FragColor = vec4(s, 1.0);
    } else {
        gl_FragColor = vec4(0.0);
    }
}
