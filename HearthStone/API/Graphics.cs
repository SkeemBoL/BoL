using UnityEngine;

namespace API
{
    class Graphics
    {
        /* void Graphics.DrawText(string text, int size, int x, int y, UnityEngine.Color color)
         * Draws Text to the screen needs to be run OnGUI
         */
        public static void DrawText(string sText, int iSize, int iX, int iY, UnityEngine.Color color)
        {
            UnityEngine.GUIStyle s = new UnityEngine.GUIStyle();
            s.normal.textColor = color;
            s.fontSize = iSize;
            UnityEngine.GUI.Label(new UnityEngine.Rect(iX, iY, 200, 200), sText, s);
        }

        /* void Graphics.AddInfoMsg(string msg)
         * adds information message to the screen, does not need to be run OnGUI
         */
        public static void AddInfoMsg(string msg)
        {
            UIStatus.Get().AddInfo(msg);
        }
        
        /* void Graphics.AddErrorMsg(string msg)
         * adds information message to the screen, does not need to be run OnGUI
         */
        public static void AddErrorMsg(string msg)
        {
            UIStatus.Get().AddError(msg);
        }
    }
}
