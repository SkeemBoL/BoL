using System.Collections.Generic;

namespace API
{
    class Game
    {
        /* Player Game.MyPlayer()
         * Returns Current Player
         */
        public static Player MyPlayer()
        {
            return GameState.Get().GetCurrentPlayer();
        }

        /* Player Game.EnemyPlayer()
         * Returns Enemy Player
         */
        public static Player EnemyPlayer()
        {
            return GameState.Get().GetFirstOpponentPlayer(MyPlayer());
        }

        /* List<Card> Game.CardsInHand
         * Returns a list of cards in local player hand
         */
        public static List<Card> CardsInHand()
        {
            return MyPlayer().GetHandZone().GetCards();
        }

        /* List<Card> Game.CardsInField
         * Returns a list of cards in local player battlefield
         */
        public static List<Card> CardsInField()
        {
            return MyPlayer().GetBattlefieldZone().GetCards();
        }

        /* List<Card> Game.CardsInEnemyField()
         * returns list of cards in enemy field
         */
        public static List<Card> CardsInEnemyField()
        {
            return EnemyPlayer().GetBattlefieldZone().GetCards();
        }
        
        /* bool Game.CanAttack(Card card)
         * returns if the input Card can attack
         */
        public static bool CanAttack(Card card)
        {
            return (!card.GetEntity().IsRecentlyArrived() || card.GetEntity().HasCharge()) && !card.GetEntity().IsAsleep() && !card.GetEntity().IsExhausted() && !card.GetEntity().IsFrozen() && card.GetEntity().CanAttack() && !(card.GetEntity().GetATK() < 1);
        }
        
        /* bool Game.CanKill(Card attacker, Card target)
         * returns if the attacker can kill the target Card
         */
        public static bool CanKill(Card attacker, Card target)
        {
            return attacker.GetEntity().GetATK() >= target.GetEntity().GetHealth();
        }

        /* bool Game.CanPlay(Card card)
        * returns the local player can play input card
        */
        public static bool CanPlay(Card card)
        {
            return card.GetEntity() != null && card.GetEntity().IsControlledByLocalUser() && card.GetEntity().GetCost() <= MyPlayer().GetNumAvailableResources() && (!card.GetEntity().IsMinion() || MyPlayer().GetNumMinionsInPlay() < 7);
        }
        
        /* void Game.PlayCard(string type, Card card, [optional] Card target)
         * Plays a card from player hand, TYPES = "Minion", "Spell"
         * TODO: Improve this function and add support for Secret, Weapon Zones
         */
        public static void PlayCard(string type, Card card, Card target = null)
        {
            Entity cEntity = card.GetEntity();
            switch (type)
            {
                case "Minion":
                    Zone destZone = MyPlayer().GetBattlefieldZone();
                    int slot = destZone.GetCards().Count + 1;
                    GameState.Get().GetGameEntity().NotifyOfCardDropped(cEntity);
                    GameState.Get().SetSelectedOptionPosition(slot);
                    if (InputManager.Get().DoNetworkResponse(cEntity))
                    {
                        int zonePos = cEntity.GetZonePosition();
                        ZoneMgr.Get().AddLocalZoneChange(card, destZone, slot);
                        MyPlayer().GetHandZone().UpdateLayout(-1, true);
                        MyPlayer().GetBattlefieldZone().SortWithSpotForHeldCard(-1);
                        if (GameState.Get().GetResponseMode() != GameState.ResponseMode.SUB_OPTION)
                        {
                            EnemyActionHandler.Get().NotifyOpponentOfCardDropped();
                        }
                    }
                    break;
                case "Spell":
                    if (card.GetActor().GetActorStateType() == ActorStateType.CARD_PLAYABLE)
                    {
                        GameState.Get().GetGameEntity().NotifyOfCardDropped(cEntity);
                        if (InputManager.Get().DoNetworkResponse(cEntity))
                        {
                            ZoneMgr.Get().AddLocalZoneChange(card, TAG_ZONE.PLAY);
                            MyPlayer().GetHandZone().UpdateLayout(-1, true);
                            MyPlayer().GetBattlefieldZone().SortWithSpotForHeldCard(-1);

                            if (GameState.Get().GetResponseMode() != GameState.ResponseMode.SUB_OPTION)
                            {
                                EnemyActionHandler.Get().NotifyOpponentOfCardDropped();
                            }
                        }
                    }
                    break;
            }
            if (target != null && GameState.Get().IsInTargetMode())
            {
                GameState.Get().GetGameEntity().NotifyOfBattlefieldCardClicked(target.GetEntity(), true);
                if (InputManager.Get().DoNetworkResponse(target.GetEntity()))
                {
                    EnemyActionHandler.Get().NotifyOpponentOfTargetEnd();
                    MyPlayer().GetHandZone().UpdateLayout(-1, true);
                    MyPlayer().GetBattlefieldZone().UpdateLayout();
                }
            }
        }

        /* void Game.Attack(Card Attacker, Card enemy)
         * Attacks enemy card with attacker card
         */
        public static void Attack(Card attacker, Card enemy)
        {
            GameState.Get().GetGameEntity().NotifyOfCardGrabbed(attacker.GetEntity());
            if (InputManager.Get().DoNetworkResponse(attacker.GetEntity()))
            {
                EnemyActionHandler.Get().NotifyOpponentOfCardPickedUp(attacker);
                EnemyActionHandler.Get().NotifyOpponentOfTargetModeBegin(attacker);
                GameState.Get().GetGameEntity().NotifyOfBattlefieldCardClicked(enemy.GetEntity(), true);
                if (InputManager.Get().DoNetworkResponse(enemy.GetEntity()))
                {
                    EnemyActionHandler.Get().NotifyOpponentOfTargetEnd();
                    GameState.Get().GetCurrentPlayer().GetHandZone().UpdateLayout(-1, true);
                    GameState.Get().GetCurrentPlayer().GetBattlefieldZone().UpdateLayout();
                }
            }
        }
    }
}
