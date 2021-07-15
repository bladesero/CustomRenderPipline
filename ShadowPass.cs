using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

struct DirectionalShadowData
{
    float strength;
    int tileIndex;
}

public class ShadowPass : ScriptableRenderPass
{

    const int k_MaxCascades = 4;
    const int k_ShadowmapBufferBits = 16;
    const int k_ShadowmapSize = 2048;
    RenderTargetHandle m_MainLightShadowmap;
    RenderTexture m_MainLightShadowmapTexture;

    static int dirShadowArrayId = Shader.PropertyToID("_dirShadowArray");
    static int dirShadowMatrixId = Shader.PropertyToID("_dirShadowMatrix");
    const string k_ShadowPassTag = "ShadowPass";
    NativeArray<VisibleLight> lights;

    public ShadowPass(NativeArray<VisibleLight> lights)
    {
        this.lights = lights;
    }

    public override void Execute(ScriptableRenderContext context, Camera camera)
    {
        var cmd = CommandBufferPool.Get(k_ShadowPassTag);
        cmd.BeginSample(k_ShadowPassTag);
        int MainlightIndex = ForwardLight.GetMainLightIndex(lights);
        renderMainLightShadowmap(context, camera, cmd, MainlightIndex);
        context.ExecuteCommandBuffer(cmd);
        
        CommandBufferPool.Release(cmd);
        cmd.EndSample(k_ShadowPassTag);
    }

    void renderMainLightShadowmap(ScriptableRenderContext context,Camera camera, CommandBuffer cmd,int lightindex)
    {
        if(lightindex != -1&& lights[lightindex].light.shadows != LightShadows.None)
        {
            cmd.GetTemporaryRT(
            dirShadowArrayId, k_ShadowmapSize, k_ShadowmapSize, 32,
            FilterMode.Bilinear, RenderTextureFormat.Shadowmap
            );
            cmd.SetRenderTarget(dirShadowArrayId,
                RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);

            cmd.ClearRenderTarget(true, false, Color.clear);
            ExecuteBuffer(context, cmd);

            camera.TryGetCullingParameters(out ScriptableCullingParameters p);
            p.shadowDistance = 20;
            CullingResults cullingResults = context.Cull(ref p);

            if(cullingResults.GetShadowCasterBounds(lightindex, out Bounds bounds))
            {
                var shadowSetting = new ShadowDrawingSettings(cullingResults, lightindex);
                cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives
                    (lightindex, 0, 1, Vector3.zero, k_ShadowmapSize, 0.0f, out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix,
                    out ShadowSplitData splitData);
                shadowSetting.splitData = splitData;

                cmd.SetViewProjectionMatrices(viewMatrix, projectionMatrix);

                projectionMatrix.m20 = -projectionMatrix.m20;
                projectionMatrix.m21 = -projectionMatrix.m21;
                projectionMatrix.m22 = -projectionMatrix.m22;
                projectionMatrix.m23 = -projectionMatrix.m23;

                var textureScaleAndBias = Matrix4x4.identity;
                textureScaleAndBias.m00 = 0.5f;
                textureScaleAndBias.m11 = 0.5f;
                textureScaleAndBias.m22 = 0.5f;
                textureScaleAndBias.m03 = 0.5f;
                textureScaleAndBias.m23 = 0.5f;
                textureScaleAndBias.m13 = 0.5f;

                Matrix4x4 shadowMatrix = projectionMatrix * viewMatrix;
                shadowMatrix= textureScaleAndBias * shadowMatrix;
                cmd.SetGlobalMatrix(dirShadowMatrixId, shadowMatrix);
                ExecuteBuffer(context, cmd);
                context.DrawShadows(ref shadowSetting);
            }
            

            cmd.ReleaseTemporaryRT(dirShadowArrayId);
            cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
            ExecuteBuffer(context, cmd);
        }
        else
        {
            cmd.GetTemporaryRT(
                dirShadowArrayId, 1, 1,
                32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap
            );
            cmd.ReleaseTemporaryRT(dirShadowArrayId);
            ExecuteBuffer(context, cmd);
        }
    }

    void ExecuteBuffer(ScriptableRenderContext context, CommandBuffer cmd)
    {
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }
}
