using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GTAO : PostProcessingComponent
{
    const string k_AOPostProcessingTag = "AO Pass";

    public RenderTargetHandle m_OcclusionOrigin;
    public RenderTargetHandle m_Normal;

    public float m_Radius = 0.35f;
    public float m_OcclusionBias = 0.1f;
    public float m_OcclusionOffset = 0.04f;
    public void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd,float renderScale)
    {
        m_Source.Init("_CameraColorTexture");
        m_OcclusionOrigin.Init("_OcclusionOrigin");


        float far = camera.farClipPlane;
        float x, y;
        y = 2 * Mathf.Tan(camera.fieldOfView * Mathf.Deg2Rad * 0.5f) * far;
        x = y * camera.aspect;
        this.m_BlitMaterial.SetVector("_FarCorner", new Vector3(x, y, far));
        this.m_BlitMaterial.SetVector("_Params", new Vector4(
                                                     m_Radius,
                                                     m_OcclusionBias,
                                                     m_OcclusionOffset,
                                                     1.0f / (m_Radius * m_Radius * 10)
                                                     ));

        int width = (int)(renderScale * camera.pixelWidth);
        int height = (int)(renderScale * camera.pixelHeight);

        cmd.BeginSample(k_AOPostProcessingTag);

        cmd.GetTemporaryRT(m_OcclusionOrigin.id, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        cmd.Blit(m_Source.id, m_OcclusionOrigin.id, m_BlitMaterial, 0);
        //cmd.Blit(m_OcclusionOrigin.id, m_Destination.id, m_BlitMaterial, 1);
        //cmd.ReleaseTemporaryRT(m_OcclusionOrigin.id);
        cmd.EndSample(k_AOPostProcessingTag);
    }

    public override void Execute(ScriptableRenderContext context, Camera camera, CommandBuffer cmd)
    {
    }
}
