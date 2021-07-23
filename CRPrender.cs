using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CRPRenderer
{
    static ShaderTagId[] legacyShaderTagIds = {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };

    ScriptableRenderContext context;
    Camera camera;
    static Material errorMaterial;
    static int cameraColorTextureId = Shader.PropertyToID("_CameraColorTexture");
    static int cameraDepthTextureId = Shader.PropertyToID("_CameraDepthTexture");
    static int cameraBaseColorTextureId = Shader.PropertyToID("_CameraBaseColorTexture");
    static int cameraNormalTextureId= Shader.PropertyToID("_CameraNormalTexture");

    static RenderTargetIdentifier[] gbuffers = new RenderTargetIdentifier[]
    {
        cameraColorTextureId,cameraNormalTextureId,cameraBaseColorTextureId
    };

    public float renderScale = 1.0f;

    //Passes
    ForwardLight forwardLight = new ForwardLight();
    OpaquePass opaquePass=new OpaquePass();
    PostProcessingPass processingPass = new PostProcessingPass();

    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer { name = bufferName };

    public void Setup()
    {
        buffer.BeginSample(bufferName);
        buffer.ClearRenderTarget(true, true, Color.clear);
        ExecuteBuffer();    
    }

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        processingPass.renderScale = renderScale;
        int width = (int)(renderScale * camera.pixelWidth);
        int height = (int)(renderScale * camera.pixelHeight);

        //var colorDescripter = new RenderTextureDescriptor(width, height, RenderTextureFormat.RGB111110Float,
        //    24);

        buffer.GetTemporaryRT(cameraColorTextureId, width,
            height, 0,
                FilterMode.Bilinear, RenderTextureFormat.RGB111110Float);

        buffer.GetTemporaryRT(cameraBaseColorTextureId, width,
            height, 0,
                FilterMode.Bilinear, RenderTextureFormat.Default);

        buffer.GetTemporaryRT(cameraNormalTextureId, width,
            height, 0,
                FilterMode.Bilinear, RenderTextureFormat.Default);

        buffer.GetTemporaryRT(cameraDepthTextureId, width,
            height, 32,
            FilterMode.Point, RenderTextureFormat.Depth);

        //buffer.SetRenderTarget(cameraColorTextureId,
        //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
        //    cameraDepthTextureId,
        //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.SetRenderTarget(gbuffers,cameraDepthTextureId);

        context.SetupCameraProperties(camera);
        Setup();

        DrawUnsupportedShaders();

        forwardLight.Setup(context, camera);
        forwardLight.shadowcastpass.Execute(context, camera);

        //buffer.SetRenderTarget(cameraColorTextureId,
        //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
        //    cameraDepthTextureId,
        //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.SetRenderTarget(gbuffers, cameraDepthTextureId);
        ExecuteBuffer();

        opaquePass.Execute(context, camera);

        context.DrawSkybox(camera);

        processingPass.Execute(context, camera);

        if (!IsGameCamera(camera))
        {
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }

        buffer.ReleaseTemporaryRT(cameraColorTextureId);
        buffer.ReleaseTemporaryRT(cameraDepthTextureId);
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }

    public static bool IsGameCamera(Camera camera)
    {
        if (camera == null)
            throw new ArgumentNullException("camera");

        return camera.cameraType == CameraType.Game || camera.cameraType == CameraType.VR;
    }

    void DrawUnsupportedShaders()
    {
        if (errorMaterial == null)
        {
            errorMaterial =
                new Material(Shader.Find("Hidden/InternalErrorShader"));
        }
        var drawingSettings = new DrawingSettings(
            legacyShaderTagIds[0], new SortingSettings(camera)
        )
        { overrideMaterial = errorMaterial };

        for (int i = 1; i < legacyShaderTagIds.Length; i++)
        {
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }

        var filteringSettings = FilteringSettings.defaultValue;
        camera.TryGetCullingParameters(out ScriptableCullingParameters p);
        CullingResults cullingResults = context.Cull(ref p);
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filteringSettings
        );
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
}
