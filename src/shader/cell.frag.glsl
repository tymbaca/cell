#version 330

in vec2 fragTexCoord;
in vec4 fragTint;
out vec4 finalColor;

uniform sampler2D texture0;          // The circular texture (soccer ball, cell, etc.)
// uniform vec4 tint = vec4(1);    
//
// // Collision data (max 8 simultaneous collisions)
// uniform int collisionCount;           // Number of active collisions (0 to 8)
// uniform vec3 collisions[8];            // Each: x,y = direction vector (normalized), z = strength (0–1)

// Circle parameters (in UV space, where (0,0) is bottom-left, (1,1) is top-right)
// uniform vec2 center = vec2(0.5, 0.5);  // center of the circle
// uniform float radius = 0.5;            // radius of the circle (distance from center to edge)

// Deformation controls
// uniform float compressionFactor = 0.5; // Overall intensity of the squeeze (0 = no effect)
// uniform float falloffExponent = 2.0;   // How sharply the effect falls off with angle (higher = sharper)

void main()
{
    // Sample the texture at the deformed coordinates
    vec4 texColor = texture(texture0, fragTexCoord);
    finalColor = texColor * fragTint;
}
