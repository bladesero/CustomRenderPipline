using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

using GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat;
public struct RenderTargetHandle
{
    public int id { set; get; }

    public static readonly RenderTargetHandle CameraTarget = new RenderTargetHandle { id = -1 };

    public void Init(string shaderProperty)
    {
        id = Shader.PropertyToID(shaderProperty);
    }

    public RenderTargetIdentifier Identifier()
    {
        if (id == -1)
        {
            return BuiltinRenderTextureType.CameraTarget;
        }
        return new RenderTargetIdentifier(id);
    }

    public bool Equals(RenderTargetHandle other)
    {
        return id == other.id;
    }

    public override bool Equals(object obj)
    {
        if (ReferenceEquals(null, obj)) return false;
        return obj is RenderTargetHandle && Equals((RenderTargetHandle)obj);
    }

    public override int GetHashCode()
    {
        return id;
    }

    public static bool operator ==(RenderTargetHandle c1, RenderTargetHandle c2)
    {
        return c1.Equals(c2);
    }

    public static bool operator !=(RenderTargetHandle c1, RenderTargetHandle c2)
    {
        return !c1.Equals(c2);
    }
}

public class PostProcessingPass : ScriptableRenderPass
{
    [Reload("/Asset/CustomPostProcessData.asset")]
    public PostProcessingData postProcessData = AssetDatabase.LoadAssetAtPath<PostProcessingData>(CustomRenderPipelineAsset.packagePath + "/Asset/CustomPostProcessData.asset");

    const string k_RenderPostProcessingTag = "Render PostProcessing Effects";

    FXAA FXAAPass =new FXAA();
    CopyDepth copyDepthPass = new CopyDepth();

    public PostProcessingPass()
    {
#if UNITY_EDITOR
        if (postProcessData == null)
        {
            ResourceReloader.TryReloadAllNullIn(postProcessData, CustomRenderPipelineAsset.packagePath);
        }
#endif
    }

    public override void Execute(ScriptableRenderContext context, Camera camera)
    {
        var cmd = CommandBufferPool.Get(k_RenderPostProcessingTag);

        {//CopyDepthPass
            copyDepthPass.m_Source.Init("_CameraDepthTexture");

            copyDepthPass.m_Destination.Init("_CameraDepthTexture");

            if (copyDepthPass.m_BlitMaterial == null)
            {
                copyDepthPass.m_BlitMaterial = new Material(postProcessData.shaders.CopyDepth);
                copyDepthPass.m_BlitMaterial.hideFlags = HideFlags.HideAndDontSave;
            }

            if (camera.cameraType == CameraType.SceneView || camera.cameraType == CameraType.Game)
                copyDepthPass.Execute(context, camera, cmd);
        }

        {//FXAA Pass
            FXAAPass.m_Source.Init("_CameraColorTexture");

            FXAAPass.m_Destination.Init("_CameraDepthTexture");

            if (FXAAPass.m_BlitMaterial == null)
            {
                FXAAPass.m_BlitMaterial = new Material(postProcessData.shaders.fxaa);
                FXAAPass.m_BlitMaterial.hideFlags = HideFlags.HideAndDontSave;
            }

            if (camera.cameraType == CameraType.SceneView || camera.cameraType == CameraType.Game)
                FXAAPass.Execute(context, camera, cmd);
        }
        

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}

public abstract class PostProcessingComponent
{
    public RenderTextureDescriptor m_Descriptor;
    public RenderTargetHandle m_Source;
    public RenderTargetHandle m_Destination;
    public Material m_BlitMaterial;

    public abstract void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd);
}

class MaterialLibrary
{
    public readonly Material stopNaN;
    public readonly Material subpixelMorphologicalAntialiasing;
    public readonly Material FastApproximateAntialiasing;
}

//static class ShaderConstants
//{
//    public static readonly int _EdgeTexture = Shader.PropertyToID("_EdgeTexture");
//    public static readonly int _BlendTexture = Shader.PropertyToID("_BlendTexture");
//}

public class CopyDepth : PostProcessingComponent
{
    const string k_CopyDepthPostProcessingTag = "CopyDepth Pass";

    public override void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd)
    {
        cmd.BeginSample(k_CopyDepthPostProcessingTag);
        cmd.Blit(m_Source.id, BuiltinRenderTextureType.CameraTarget, m_BlitMaterial, 0);
        cmd.EndSample(k_CopyDepthPostProcessingTag);
    }
}

public class SMAA : PostProcessingComponent
{
    const int kStencilBit = 64;

    public override void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd)
    {
    }
}

public class FXAA : PostProcessingComponent
{
    const string k_RenderFXAAPostProcessingTag = "FXAA Pass";

    public override void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd)
    {
        cmd.BeginSample(k_RenderFXAAPostProcessingTag);
        cmd.Blit(m_Source.id, BuiltinRenderTextureType.CameraTarget, m_BlitMaterial, 0);
        cmd.EndSample(k_RenderFXAAPostProcessingTag);
    }
}
