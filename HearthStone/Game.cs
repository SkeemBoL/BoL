using System;
using System.Linq;
using System.Collections.Generic;

namespace NintendoBot
{
    public class Game
    {   
        // Delay Stufff
        private static DateTime delayStart = DateTime.Now;
        private static long delayLenght = 0;
        public static bool wait = false;

        public static void Delay(long msec)
        {
            delayStart = DateTime.Now;
            delayLenght = msec;
        }

        public static void DelayUpdate()
        {
            DateTime currTime = DateTime.Now;
            TimeSpan timeSince = currTime - delayStart;
            wait = timeSince.TotalMilliseconds < delayLenght;
        }

        // Find Game
        public static void FindGame(PegasusShared.GameType gameType, int missionId, long deckId = 0, long aiDeckId = 0)
        {
            GameMgr.Get().FindGame(gameType, missionId, deckId, aiDeckId);
            GameMgr.Get().UpdatePresence();
        }

        public static bool MulliganActive()
        {
            return GameState.Get().IsMulliganManagerActive();
        }

        public static void ReplaceCards(IList<Card> cards)
        {
            /*for (var i = 0; i < cards.Count; i++)
            {
                Card c = cards[i];
                if (c.GetEntity().GetCost() > 3)
                {
                    MulliganManager.Get().ToggleHoldState(c);
                }
            }*/
            MulliganManager.Get().EndMulligan();
            EndTurn();
        }

        public static void PlayCards()
        {

        }

        public static Card BestAttacker()
        {
            IList<Card> Cards = GameState.Get().GetCurrentPlayer().GetHandZone().GetCards();
            for (var i = 0; i < Cards.Count; i++)
            {
                Card attacker = Cards[i];
                if (attacker.GetEntity().IsAsleep() || attacker.GetEntity().IsExhausted() || attacker.GetEntity().IsFrozen() || attacker.GetEntity().IsRecentlyArrived() || !attacker.GetEntity().CanAttack() || attacker.GetEntity().GetATK() < 1)
                {
                    continue;
                }
                return attacker;
            }
            return null;
        }
        public static void EndTurn()
        {
            InputManager.Get().DoEndTurnButton();
            Delay(5000);
        }
        public static Card BestEnemy()
        {
            IList<Card> enemyCards = GameState.Get().GetFirstOpponentPlayer(GameState.Get().GetCurrentPlayer()).GetBattlefieldZone().GetCards();
            if (enemyCards.Count > 0)
            {
                Card enemy = enemyCards[0];
                for (var i = 0; i < enemyCards.Count; i++)
                {
                    Card current = enemyCards[i];
                    if (!current.GetEntity().CanBeAttacked())
                    {
                        continue;
                    }
                    if (current.GetEntity().HasTaunt() || !enemy.GetEntity().HasTaunt())
                    {
                        enemy = current;
                    }
                }
                return enemy;             
            }
            return null;
        }

        public static bool Attack(Card attacker, Card enemy)
        {
            try
            {
                GameState.Get().GetGameEntity().NotifyOfCardGrabbed(attacker.GetEntity());
                if (InputManager.Get().DoNetworkResponse(attacker.GetEntity()))
                {
                    EnemyActionHandler.Get().NotifyOpponentOfCardPickedUp(attacker);

                    System.Threading.Thread.Sleep(500);

                    EnemyActionHandler.Get().NotifyOpponentOfTargetModeBegin(attacker);
                    System.Threading.Thread.Sleep(500);
                    GameState.Get().GetGameEntity().NotifyOfBattlefieldCardClicked(enemy.GetEntity(), true);
                    if (InputManager.Get().DoNetworkResponse(enemy.GetEntity()))
                    {
                       EnemyActionHandler.Get().NotifyOpponentOfTargetEnd();
                       GameState.Get().GetCurrentPlayer().GetHandZone().UpdateLayout(-1, true);
                       GameState.Get().GetCurrentPlayer().GetBattlefieldZone().UpdateLayout();
                       return true;
                    }
                }
                return false;
            }
            catch (Exception ex)
            {
                Graphics.AddErrorMsg("Attacking Failed" + ex.StackTrace.ToString());
                return false;
            }
            finally
            {
                System.Threading.Thread.Sleep(1000 * 2);
            }
        }

        public static void DoAttacks()
        {
            int numAttacks = 0;
            for (int i = 0; i < GameState.Get().GetCurrentPlayer().GetHandZone().GetCards().Count + 10; i++)
            {
                Card attacker = BestAttacker();
                Card enemy    = BestEnemy();
                if (attacker == null || enemy == null)
                {
                    return;
                }
                if (Attack(attacker, enemy))
                {
                    Graphics.AddInfoMsg("Attacked");
                    numAttacks += 1;
                }
            }
        }
    }
}
