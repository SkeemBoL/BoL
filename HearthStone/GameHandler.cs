using UnityEngine;

namespace NintendoBot
{
    public class GameHandler : MonoBehaviour
    {
        public static void Init()
        {
            SceneMgr.Get().gameObject.AddComponent<GameHandler>();
        }
    }
}
