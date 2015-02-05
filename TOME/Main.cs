using UnityEngine;

namespace HSAnthrax
{
    public class HackInstall : MonoBehaviour
    {
        public static void CreateHack()
        {


            Object.DontDestroyOnLoad((Object)new GameObject("Tometartup").AddComponent<HackInstall>());
        }

        private void Start()
        {
            // Event Handler
            gameObject.AddComponent<NintendoTome.Events>();
            // Sample Script
            gameObject.AddComponent<NintendoTome.SampleScript>();
        }
    }
    public class EntryPoint
    {
        public EntryPoint()
        {
            EntryPoint.Init();

        }
        public static void Init()
        {
            HackInstall.CreateHack();
        }
    }
}