#pragma once

#include "rthsTypes.h"

#ifdef _WIN32
#ifdef rthsDebug
    // debug layer
    #define rthsEnableD3D12DebugLayer

    // GPU based validation
    // https://docs.microsoft.com/en-us/windows/desktop/direct3d12/using-d3d12-debug-layer-gpu-based-validation
    #define rthsEnableD3D12GBV

    // DREAD (this requires Windows SDK 10.0.18362.0 or newer)
    // https://docs.microsoft.com/en-us/windows/desktop/direct3d12/use-dred
    #define rthsEnableD3D12DREAD

    //// VB & IB validation
    //#define rthsEnableBufferValidation

    //// render target validation
    //#define rthsEnableRenderTargetValidation
#endif


namespace rths {

#define DefPtr(_a) _COM_SMARTPTR_TYPEDEF(_a, __uuidof(_a))
DefPtr(IDXGISwapChain3);
DefPtr(IDXGIFactory4);
DefPtr(IDXGIAdapter1);
DefPtr(IDXGIResource);
DefPtr(IDXGIResource1);
DefPtr(IDxcBlobEncoding);
DefPtr(ID3D11Device);
DefPtr(ID3D11Device5);
DefPtr(ID3D11DeviceContext);
DefPtr(ID3D11DeviceContext4);
DefPtr(ID3D11Buffer);
DefPtr(ID3D11Texture2D);
DefPtr(ID3D11Query);
DefPtr(ID3D11Fence);
DefPtr(ID3D12Device);
DefPtr(ID3D12Device5);
DefPtr(ID3D12GraphicsCommandList4);
DefPtr(ID3D12CommandQueue);
DefPtr(ID3D12Fence);
DefPtr(ID3D12CommandAllocator);
DefPtr(ID3D12Resource);
DefPtr(ID3D12DescriptorHeap);
DefPtr(ID3D12StateObject);
DefPtr(ID3D12RootSignature);
DefPtr(ID3D12StateObjectProperties);
DefPtr(ID3D12Debug);
#ifdef rthsEnableD3D12GBV
    DefPtr(ID3D12Debug1);
#endif
#ifdef rthsEnableD3D12DREAD
    DefPtr(ID3D12DeviceRemovedExtendedDataSettings);
    DefPtr(ID3D12DeviceRemovedExtendedData);
#endif
DefPtr(ID3DBlob);
DefPtr(IDxcCompiler);
DefPtr(IDxcLibrary);
DefPtr(IDxcBlobEncoding);
DefPtr(IDxcOperationResult);
DefPtr(IDxcBlob);
#undef DefPtr

class TextureDataDXR
{
public:
    void *texture = nullptr; // host
    int width = 0;
    int height = 0;

    DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
    ID3D12ResourcePtr  resource;
    ID3D11Texture2DPtr temporary_d3d11;
    HANDLE handle = nullptr;
    bool is_nt_handle = false;
    int use_count = 0;

    TextureDataDXR();
    ~TextureDataDXR();
};
using TextureDataDXRPtr = std::shared_ptr<TextureDataDXR>;
TextureID identifier(const TextureDataDXR& data);

class BufferDataDXR
{
public:
    void *buffer = nullptr; // host
    int size = 0;

    ID3D12ResourcePtr resource;
    ID3D11BufferPtr   temporary_d3d11;
    HANDLE handle = nullptr;
    bool is_nt_handle = false;
    int use_count = 0;

    BufferDataDXR();
    ~BufferDataDXR();
};
using BufferDataDXRPtr = std::shared_ptr<BufferDataDXR>;

class MeshDataDXR
{
public:
    BufferDataDXRPtr vertex_buffer;
    BufferDataDXRPtr index_buffer;
    int vertex_count = 0;
    int index_bits = 0;
    int index_count = 0;
    int index_offset = 0;
    int use_count = 0;

    ID3D12ResourcePtr blas; // bottom level acceleration structure
};
using MeshDataDXRPtr = std::shared_ptr<MeshDataDXR>;
MeshID identifier(const MeshDataDXR& data);

class MeshInstanceDXR
{
public:
    MeshDataDXRPtr mesh;
    float3x4 transform;
};

struct DescriptorHandle
{
    D3D12_CPU_DESCRIPTOR_HANDLE hcpu{};
    D3D12_GPU_DESCRIPTOR_HANDLE hgpu{};

    operator bool() const;
};


extern const D3D12_HEAP_PROPERTIES kDefaultHeapProps;
extern const D3D12_HEAP_PROPERTIES kUploadHeapProps;

// thin wrapper for Windows' event
class FenceEvent
{
public:
    FenceEvent();
    ~FenceEvent();
    operator HANDLE() const;

private:
    HANDLE m_handle = nullptr;
};

DXGI_FORMAT GetTypedFormat(DXGI_FORMAT format);

} // namespace rths
#endif // _WIN32
