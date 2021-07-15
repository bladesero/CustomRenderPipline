using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public abstract class ScriptableRenderPass
{

    public abstract void Execute(ScriptableRenderContext context, Camera camera);
}
