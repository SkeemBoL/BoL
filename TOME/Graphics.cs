using UnityEngine;

namespace NintendoTome
{
    public class Draws
    {
        public static void Text(string sText, int iSize, int iX, int iY, UnityEngine.Color color)
        {
            UnityEngine.GUIStyle s = new UnityEngine.GUIStyle();
            s.normal.textColor = color;
            s.fontSize = iSize;
            UnityEngine.GUI.Label(new UnityEngine.Rect(iX, iY, 200, 200), sText, s);
        }
    }

    public class World
    {
         public static Vector3 GetCursorPosition()
        {
            Plane xzPlane = new Plane(Vector3.right, Vector3.zero, Vector3.forward);
            Camera main = Camera.main;
            float enter = 0.0f;
            Ray ray = main.ScreenPointToRay(Input.mousePosition);
            if (xzPlane.Raycast(ray, out enter))
                return ray.GetPoint(enter);
            return Vector3.zero;
        }
    }
}
