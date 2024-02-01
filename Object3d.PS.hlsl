#include "Object3d.hlsli"

struct Material {
	float32_t4 color;
	int32_t enableLighting;
};

struct DirectionalLight {
	float32_t4 color;
	float32_t3 direction;
	float32_t3 worldPosition;
	float intensity;
};

ConstantBuffer<Camera> gCamera : register(b2);
ConstantBuffer<Material> gMaterial : register(b0);
Texture2D<float32_t4>gTexture:register(t0);
SamplerState gSampler : register(s0);

ConstantBuffer<DirectionalLight>gDirectionalLight:register(b1);

// half lambert
float Ndotl = dot(normalize(input.normal), normalize(-gDirectionalLight.direction));
float cos = pow(Ndotl * 0.5f + 0.5f, 2.0f);

float RdotE = dot(reflectLight, toEye);
float specularPow = pow(saturate(RdotE), gMaterial.shininess);

struct PixelShaderOutput {
	float32_t4 color : SV_TARGET0;
};

PixelShaderOutput main(VertexShaderOutput input) {
	PixelShaderOutput output;
	float32_t4 textureColor = gTexture.Sample(gSampler, input.texcoord);
	output.color = gMaterial.color * textureColor;
	float32_t3 toEye = normalize(gCamera.worldPosition - input.worldPosition);
	float32_t3 reflectLight = reflect(gDirectionalLight.direction, normalize(input.normal));
	
	// 拡散反射
    float32_t3 diffuse = gMaterial.color.rgb * textureColor.rgb * gDirectionalLight.color.rgb * gDirectionalLight.intensity;
	// 鏡面反射
    float32_t3 specular = gDirectionalLight.color.rgb * gDirectionalLight.intensity * specularPow * float32_t3(1.0f, 1.0f, 1.0f);
	// 拡散反射
    output.color.rgb = diffuse + specular;
	// アルファは今まで通り
    output.color.a = gMaterial.color.a * textureColor.a;
	
	//output.color.rgb = gMaterial.color.rgb * textureColor.rgb * gDirectionallLight.color.rgb * cos * gDirectionallLight.intensity;
	//output.color.a = gMaterial.color.a * textureColor.a;
	return output;
}