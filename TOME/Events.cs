using UnityEngine;

namespace NintendoTome
{
    class Events : MonoBehaviour
    {
        public delegate void GameStartEvent();
        public static event GameStartEvent OnGameStart;
        private void Update()
        {
            if (Game.MyActor().actorData.ActorName != null && OnGameStart != null)
            {
                OnGameStart();
                OnGameStart = null;
            }
        }
    }
}
