#define kThreadBlockSize 128

enum DEFORM_FLAG
{
    DF_APPLY_BLENDSHAPE = 1,
    DF_APPLY_SKINNING = 2,
};

struct BlendshapeFrame
{
    uint delta_offset;
    float weight;
};
struct BlendshapeInfo
{
    uint frame_count;
    uint frame_offset;
};

struct BoneCount
{
    uint weight_count;
    uint weight_offset;
};
struct BoneWeight
{
    float weight;
    uint bone_index;
};

struct MeshInfo
{
    uint deform_flags; // combination of DEFORM_FLAG
    uint vertex_stride; // in element (e.g. 6 if position + normals)
    uint2 pad;
};

RWStructuredBuffer<float4>    g_dst_vertices : register(u0);
StructuredBuffer<float>       g_base_vertices : register(t0);

// blendshape data
StructuredBuffer<float4>            g_bs_delta : register(t1);
StructuredBuffer<BlendshapeFrame>   g_bs_frames : register(t2);
StructuredBuffer<BlendshapeInfo>    g_bs_info : register(t3);
StructuredBuffer<float>             g_bs_weights : register(t4);

// skinning data
StructuredBuffer<BoneCount>   g_bone_counts : register(t5);
StructuredBuffer<BoneWeight>  g_bone_weights : register(t6);
StructuredBuffer<float4x4>    g_bone_matrices : register(t7);

ConstantBuffer<MeshInfo>      g_mesh_info : register(b0);


uint VertexCount()
{
    uint n, s;
    g_dst_vertices.GetDimensions(n, s);
    return n;
}

uint VertexStrideInElement()
{
    return g_mesh_info.vertex_stride;
}

uint BlendshapeCount()
{
    uint n, s;
    g_bs_info.GetDimensions(n, s);
    return n;
}

uint DeformFlags()
{
    return g_mesh_info.deform_flags;
}


float3 ApplyBlendshape(uint vid, float3 base)
{
    float3 result = base;
    uint num_blendshapes = BlendshapeCount();
    for (uint bsi = 0; bsi < num_blendshapes; ++bsi) {
        float weight = g_bs_weights[bsi];
        if (weight != 0.0f) {
            BlendshapeInfo info = g_bs_info[bsi];
            BlendshapeFrame last_frame = g_bs_frames[info.frame_offset + info.frame_count - 1];
            if (weight < 0.0f) {
                BlendshapeFrame first_frame = g_bs_frames[info.frame_offset];
                float3 delta = g_bs_delta[first_frame.delta_offset + vid].xyz;
                float s = weight / first_frame.weight;
                result += delta * s;
            }
            else if (weight > last_frame.weight) {
                float3 delta = g_bs_delta[last_frame.delta_offset + vid].xyz;
                float s = 0.0f;
                if (info.frame_count >= 2) {
                    BlendshapeFrame prev_frame = g_bs_frames[info.frame_offset + info.frame_count - 2];
                    s = (weight - prev_frame.weight) / (last_frame.weight - prev_frame.weight);
                }
                else {
                    s = weight / last_frame.weight;
                }
                result += delta * s;
            }
            else {
                float3 p1 = 0.0f, p2 = 0.0f;
                float w1 = 0.0f, w2 = 0.0f;

                for (uint fi = 0; fi < info.frame_count; ++fi) {
                    BlendshapeFrame frame = g_bs_frames[info.frame_offset + fi];
                    if (weight <= frame.weight) {
                        p2 = g_bs_delta[frame.delta_offset + vid].xyz;
                        w2 = frame.weight;
                        break;
                    }
                    else {
                        p1 = g_bs_delta[frame.delta_offset + vid].xyz;
                        w1 = frame.weight;
                    }
                }
                float s = (weight - w1) / (w2 - w1);
                result += lerp(p1, p2, s);
            }
        }
    }
    return result;
}

float3 ApplySkinning(uint vid, float3 base_)
{
    float4 base = float4(base_, 1.0f);
    float3 result = float3(0.0f, 0.0f, 0.0f);
    BoneCount wc = g_bone_counts[vid];
    for (uint bi = 0; bi < wc.weight_count; ++bi) {
        BoneWeight w = g_bone_weights[wc.weight_offset + bi];
        result += mul(g_bone_matrices[w.bone_index], base).xyz * w.weight;
    }
    return result;
}

[numthreads(kThreadBlockSize, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint vid = tid.x;

    uint vertex_stride = VertexStrideInElement();
    float3 result = float3(
        g_base_vertices[vertex_stride * vid + 0],
        g_base_vertices[vertex_stride * vid + 1],
        g_base_vertices[vertex_stride * vid + 2]);

    uint deform_flags = DeformFlags();
    if ((deform_flags & DF_APPLY_BLENDSHAPE) != 0)
        result = ApplyBlendshape(vid, result);
    if ((deform_flags & DF_APPLY_SKINNING) != 0)
        result = ApplySkinning(vid, result);

    g_dst_vertices[vid] = float4(result, 1.0f);
}
