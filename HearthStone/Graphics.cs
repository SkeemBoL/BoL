using UnityEngine;

namespace NintendoBot
{
    class Graphics
    {
        public static void DrawText(string sText, int iSize, int iX, int iY, UnityEngine.Color color)
        {
            UnityEngine.GUIStyle s = new UnityEngine.GUIStyle();
            GUI.color = color;
            s.normal.textColor = color;
            s.fontSize = iSize;
            UnityEngine.GUI.Label(new UnityEngine.Rect(iX, iY, 200, 200), sText, s);
        }
        public static void AddInfoMsg(string msg)
        {
            UIStatus.Get().AddInfo(msg);
        }
        public static void AddErrorMsg(string msg)
        {
            UIStatus.Get().AddError(msg);
        }
    }
}
