using System.Collections.Generic;
using Common.Game.Actors;
using Common.Game.Attributes;
using Common.Game.Data;
using UnityEngine;

namespace NintendoTome
{
    public class Unit
    {
        private Actor actor;
        public List<ActorData.Ability> abilities
        {
            get
            {
                return this.actor.Abilities;
            }
        }
        public ActorData actorData
        {
            get
            {
                return this.actor.ActorData;
            }
        }
        public int armor
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.Armor];
            }
        }
        public int armorPenetration
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.ArmorPenetration];
            }
        }
        public int assists
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.Assists];
            }
        }
        public int attackDamage
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.AttackDamage];
            }
        }
        public int attackRange
        {
            get 
            {
                return this.actor.Synced.Attributes[ActorAttribute.AttackRange];
            }
        }
        public float attackSpeed
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.AttackSpeed];
            }
        }
        public bool canSeeStealth
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.CanSeeStealth];
            }
        }
        public float collisionRadius
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.CollisionRadius];
            }
        }
        public float cooldownReduction
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.CooldownReduction];
            }
        }
        public int criticalDamage
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.CriticalDamage];
            }
        }
        public int criticalPercent
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.CriticalPercent];
            }
        }
        public int deaths
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.Deaths];
            }
        }
        public int health
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.Health];
            }
        }
        public uint id
        {
            get
            {
                return this.actor.Synced.ID;
            }
        }
        public bool isAlive
        {
            get
            {
                return this.actor.IsAlive;
            }
        }
        public bool isPet
        {
            get
            {
                return this.actor.IsPet;
            }
        }
        public int level
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.Level];
            }
        }
        public int magicPenetration
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.MagicPenetration];
            }
        }
        public int magicResistance
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.MagicResistance];
            }
        }
        public float movementSpeed
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.MovementSpeed];
            }
        }
        public float pathFacingTime
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.PathFacingLeadTime];
            }
        }
        public float pathStrength
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.PathFollowingSteeringStrength];
            }
        }
        public int pathId
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.PathId];
            }
        }
        public int pathIndex
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.PathIndex];
            }
        }
        public int playerKills
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.PlayerKills];
            }
        }
        public Vector3 position
        {
            get
            {
                return new Vector3(this.actor.Synced.Position.X, this.actor.Synced.Position.Y, this.actor.Synced.Position.Z);
            }
        }
        public int teamId
        {
            get
            {
                return this.actor.TeamID;
            }
        }
        public Actor.ActorType type
        {
            get
            {
                return this.actor.Type;
            }
        }
        public int visionId
        {
            get
            {
                return this.actor.Synced.VisionId;
            }
        }
        public int visionLevel
        {
            get
            {
                return this.actor.Synced.Attributes[ActorAttribute.VisionLevel];
            }
        }

        public Unit(Actor source)
        {
            actor = source;
        }

        public Vector3 GetLastKnownAnimatedPosition()
        {
            return new Vector3(actor.GetLastKnownAnimatedPosition().X, actor.GetLastKnownAnimatedPosition().Y, actor.GetLastKnownAnimatedPosition().Z);
        }

        public float DistanceTo(Unit unit)
        {
            return Vector3.Distance(position, unit.position);
        }

        public float DistanceTo(Vector3 pos)
        {
            return Vector3.Distance(position, pos);
        }

        public Unit ClosestGuardianActor()
        {
            List<Unit> enemies = Game.GetEnemies();
            Unit closest = null;
            for (int b = 0; b < enemies.Count; b++)
            {
                Unit currentEnemy = enemies[b];
                if (closest == null || currentEnemy.DistanceTo(this.position) < closest.DistanceTo(this.position))
                {
                    closest = currentEnemy;
                }
            }
            return closest;
        }

    }
}
