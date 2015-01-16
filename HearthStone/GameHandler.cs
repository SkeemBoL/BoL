using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace NintendoBot
{
    public class GameHandler : MonoBehaviour
    {
        private IList<Card> CardsInHand;
        public static void Init()
        {
            SceneMgr.Get().gameObject.AddComponent<GameHandler>();
            Graphics.AddInfoMsg("Game Handler Started");
        }
        private void Update()
        {
            if (!Game.wait)
            {
                CardsInHand = GameState.Get().GetCurrentPlayer().GetHandZone().GetCards();
                if (Game.MulliganActive())
                {
                    Graphics.AddInfoMsg("Changing Cards");
                    Game.Delay(3000);
                    Game.ReplaceCards(CardsInHand);
                } else if (GameState.Get().IsFriendlySidePlayerTurn())
                {
                    
                    Game.DoAttacks();
                }
            }
        }
        private void OnGUI()
        {
            Rect NintendoMenu = new Rect(20, 20, 200, 250);
            NintendoMenu = GUI.Window(0, NintendoMenu, DoMenu, "NintendoBot Menu");
            for (var i = 0; i < CardsInHand.Count; i++)
            {
                Card c = CardsInHand[i];
                Graphics.DrawText(c.GetEntity().GetName(), 12, 55, (105 + (i * 15)), UnityEngine.Color.green);
            }
            Graphics.DrawText("My Name: "      + GameState.Get().GetCurrentPlayer().GetName(), 15, 100, 700, UnityEngine.Color.red);
            Graphics.DrawText("My Health: "    + GameState.Get().GetCurrentPlayer().GetRealTimeRemainingHP(), 15, 100, 720, UnityEngine.Color.red);
            Graphics.DrawText("Enemy Health: " + GameState.Get().GetFirstOpponentPlayer(GameState.Get().GetCurrentPlayer()).GetRealTimeRemainingHP(), 15, 100, 740, UnityEngine.Color.green);
            Graphics.DrawText("Enemy Name: "   + GameState.Get().GetFirstOpponentPlayer(GameState.Get().GetCurrentPlayer()).GetName(), 15, 100, 760, UnityEngine.Color.green);
        }
        void DoMenu(int windowID)
        {
            GUI.Box(new Rect(20, 40, 160, 150), "Hand Card List");
        }
    }
}
