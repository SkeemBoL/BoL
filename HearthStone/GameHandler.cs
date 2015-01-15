using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace NintendoBot
{
    public class GameHandler : MonoBehaviour
    {
        IList<Card> CardsInHand;
        public static void Init()
        {
            SceneMgr.Get().gameObject.AddComponent<GameHandler>();
            Graphics.AddInfoMsg("Game Handler Started");
        }
        private void Update()
        {
            CardsInHand = GameState.Get().GetCurrentPlayer().GetHandZone().GetCards();
        }
        private void OnGUI()
        {
            Graphics.DrawText("Current Turn: " + GameState.Get().GetTurn(), 15, 100, 70, UnityEngine.Color.red);
            Graphics.DrawText("Cards In Hand:", 15, 100, 90, UnityEngine.Color.red);
            for (var i = 0; i < CardsInHand.Count; i++)
            {
                Card c = CardsInHand[i];
                Graphics.DrawText(c.GetEntity().GetName(), 12, 100, (100 + (i * 20)), UnityEngine.Color.green);
            }
            Graphics.DrawText("My Name: "      + GameState.Get().GetCurrentPlayer().GetName(), 15, 100, 700, UnityEngine.Color.red);
            Graphics.DrawText("My Health: "    + GameState.Get().GetCurrentPlayer().GetRealTimeRemainingHP(), 15, 100, 720, UnityEngine.Color.red);
            Graphics.DrawText("Enemy Health: " + GameState.Get().GetFirstOpponentPlayer(GameState.Get().GetCurrentPlayer()).GetRealTimeRemainingHP(), 15, 100, 740, UnityEngine.Color.green);
            Graphics.DrawText("Enemy Name: "   + GameState.Get().GetFirstOpponentPlayer(GameState.Get().GetCurrentPlayer()).GetName(), 15, 100, 760, UnityEngine.Color.green);
        }
    }
}
