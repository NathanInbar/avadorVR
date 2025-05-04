// Modified from: https://godotshaders.com/shader/distortion-bubble/
shader_type spatial;
render_mode unshaded;

// fragment uniforms
uniform float distortionView : hint_range(0.0, 0.3, 0.005) = 0.03;
uniform float speedView : hint_range(0.0, 1.0, 0.005) = 0.5;
uniform sampler2D noiseViewX;
uniform sampler2D noiseViewY;
uniform sampler2D screenTexture : hint_screen_texture;
uniform vec3 tintColor : source_color;
uniform float fesnelAmount : hint_range(0.0, 5.0, 0.1);

// New image parameters
uniform sampler2D imageTexture; // Image to display inside the bubble
uniform float imageOpacity : hint_range(0.0, 1.0, 0.01) = 0.7; // Control image visibility
uniform float imageScale : hint_range(0.1, 5.0, 0.1) = 1.0; // Scale the image
uniform vec2 imageOffset = vec2(0.0, 0.0); // Offset the image position

// vertex uniforms
uniform float distortionVertex : hint_range(0.0, 0.3, 0.005) = 0.03;
uniform float speedVertex : hint_range(0.0, 1.0, 0.005) = 0.1;
uniform sampler2D noiseVertex;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex()
{
	float noiseVal = (texture(noiseVertex, UV + (TIME * speedVertex)).r * 2.0) - 1.0; // Range: -1.0 to 1.0
	vec3 displacement = NORMAL * noiseVal * distortionVertex;
	VERTEX = VERTEX + displacement;
}

void fragment() 
{
	float noiseValueX = (texture(noiseViewX, UV + (TIME * speedView)).r * 2.0) - 1.0; // Range: -1.0 to 1.0
	float noiseValueY = (texture(noiseViewY, UV + (TIME * speedView)).r * 2.0) - 1.0; // Range: -1.0 to 1.0
	vec2 noiseDistort = vec2(noiseValueX, noiseValueY) * distortionView;
	
	// Get the distorted screen texture
	vec3 distortedScreenTexture = vec3(texture(screenTexture, SCREEN_UV + noiseDistort).rgb);
	
	// Calculate fresnel effect for edge highlight
	vec3 fresnelTint = (tintColor * fresnel(fesnelAmount, NORMAL, VIEW));
	
	// Calculate UV coordinates for the image - centered and scaled
	vec2 centeredUV = (UV - 0.5) / imageScale + 0.5 + imageOffset;
	
	// Sample the image texture with the new UVs
	vec4 imageColor = texture(imageTexture, centeredUV + noiseDistort * 0.2);
	
	// Apply a spherical mask to make the image appear properly on the bubble
	// This creates a circular falloff from the center
	float distFromCenter = length(UV - 0.5) * 2.0;
	float sphereMask = 1.0 - smoothstep(0.0, 0.9, distFromCenter);
	
	// Blend everything together:
	// 1. First layer: Distorted screen
	// 2. Second layer: Image with opacity and mask
	// 3. Third layer: Fresnel effect for edges
	vec3 finalColor = mix(distortedScreenTexture, imageColor.rgb, imageColor.a * imageOpacity * sphereMask) + fresnelTint;
	
	ALBEDO = finalColor;
	
	// Add transparency to the edges for a more bubble-like appearance
	ALPHA = mix(1.0, sphereMask, 0.3);
}