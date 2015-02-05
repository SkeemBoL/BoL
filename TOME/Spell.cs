using Common.Game.Actors;
using Common.Game.Attributes;
using Common.Game.Data;
using Common.Game.Abilities;
using UnityEngine;

/*      Spell Class
 *       Usage:
 *            Spell Q = new Spell(string name, string spellslot, string type)
 *            Spell.Cast(Actor/Pos)
 *            string name = Anything you want
 *            string spellslot = "Q", "W", "E", "R"
 *            string type = "targeted", "self", "linear", "circular", "cone"
 *      Members:
 *          string name, returns spell name
 *          string slot, returns spell slot
 *          float range, returns spell range 
 *          AbilityAsignment assignment
 *          AbilityData data (has all data like cooldown, range, radius etc)
 *     Methods:
 *          Cast(Actor target) -- Casts spell on a target
 *          Cast(UnityEngine.Vector3 Position) -- casts spell on unity engine vector3
 *          Cast(Common.Math.Vector3 Position) -- cast spell on tome vecctor3
 *      
 */

namespace NintendoTome
{
    public class Spell
    {
        public string name
        {
            get
            {
                return this.name;
            }
            set
            {
                this.name = value;
            }
        }
        public string slot
        {
            get
            {
                return this.slot;
            }
            set
            {
                this.slot = value;
            }
        }
        public string type
        {
            get
            {
                return this.type;
            }
            set
            {
                this.name = type;
            }
        }
        public float range
        {
            get
            {
                return this.data[AbilityAttribute.TargetingRange];
            }
            set
            {
                this.range = value;
            }
        }
        public AbilityAssignment assignment
        {
            get
            {
                return this.GetAbilityAssignment(this.slot);
            }
        }
        public AbilityData data
        {
            get
            {
                return DataStore.GetInstance().GetData<AbilityData>(this.actorDataAbility.AbilityName);
            }
        }
        private ActorData.Ability actorDataAbility
        {
            get
            {
                return Game.MyActor().abilities[this.GetAbilityId(this.assignment)];
            }

        }
        public Spell(string spellName, string spellSlot, string type = "targeted")
        {
            this.name = spellName;
            this.slot = spellSlot;
            this.type = type;
        }
        private void Cast(Unit target = null, Vector3 pos = default(Vector3))
        {
            Vector3 toPos = (target == null) ? pos : target.position;
            if (Vector3.Distance(Game.MyActor().position, toPos) < this.range && (target == null || Game.isValid(target)))
            {
                TargetingProps targetingProps = new TargetingProps();
                switch(this.type)
                {
                    case "self":
                        targetingProps.ActorId = Game.MyActor().id;
                        break;
                    case "targeted":
                        targetingProps.ActorId = target.id;
                        break;
                    case "cone":
                    case "linear":
                        UnityEngine.Vector3 combinedLinear = toPos - Game.MyActor().position;
                        targetingProps.Direction = new Common.Math.Vector2(combinedLinear.x, combinedLinear.z).Normalized;
                        Common.Math.Vector3 myPos = new Common.Math.Vector3(Game.MyActor().position.x, Game.MyActor().position.x, Game.MyActor().position.z);
                        Common.Math.Vector2 extend = targetingProps.Direction.Normalized * this.range;
                        Common.Math.Vector3 endPoint = myPos + new Common.Math.Vector3(extend.X, 0.0f, extend.Y);
                        targetingProps.StartPoint = myPos;
                        targetingProps.EndPoint = endPoint;
                        break;
                    case "circular":
                        targetingProps.EndPoint = new Common.Math.Vector3(toPos.x, toPos.y, toPos.z);
                        break;
                }
                GameClient.NetworkManager.Instance.Client.SendMessage((Common.Net.Protocol.MessageBase)new Common.Net.Protocol.Definitions.ActivateAbilityMessage(this.assignment, targetingProps)); 

            }
        }

        public void Cast(Vector3 pos)
        {
            this.Cast(null, pos);
        }

        public void Cast(Common.Math.Vector3 pos)
        {
            this.Cast(null, new Vector3(pos.X, pos.Y, pos.Z));
        }

        public void Cast(Unit target)
        {
            this.Cast(target, default(Vector3));
        }
        
        private int GetAbilityId(AbilityAssignment assignment)
        {
            return (int)assignment;
        }
        private AbilityAssignment GetAbilityAssignment(string slot)
        {
            switch(slot)
            {
                case "Q":
                    return AbilityAssignment.Ability1;
                case "W":
                    return AbilityAssignment.Ability2;
                case "E":
                    return AbilityAssignment.Ability3;
                case "R":
                    return AbilityAssignment.Ability4;
                default:
                    return AbilityAssignment.Ability1;
            }
        }
    }
}
