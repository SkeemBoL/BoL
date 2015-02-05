using System.Collections.Generic;
using Common.Game.Actors;
using Common.Game.Attributes;
using UnityEngine;

namespace NintendoTome
{
    class Game
    {
        public static Log Log = new Log();
        public static Unit MyActor()
        {
            return new Unit(GameClient.ClientGameManager.Instance.Game.Self.BoundActor);
        }

        public static List<Unit> GetEnemies()
        {
            List<Unit> enemies = new List<Unit>();
            foreach (Actor actor in GameClient.ClientGameManager.Instance.Game.Actors.Values)
            {
                if (actor.Type == Actor.ActorType.Guardian && actor.TeamID != MyActor().teamId)
                {
                    enemies.Add(new Unit(actor));
                }
            }
            return enemies;
        }

        public static bool isValid(Unit unit)
        {
            return unit.isAlive && unit.visionId != 0 && !unit.isPet;
        }

    }
}
