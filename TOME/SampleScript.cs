using System.Collections.Generic;
using UnityEngine;

namespace NintendoTome
{
    public class SampleScript : MonoBehaviour
    {
        private Spell Q;
        private Spell W;
        private Spell E;
        private Spell R;
   
        private void Start()
        {
            Game.Log.Write("Main Handler Started");
            Events.OnGameStart += GameStart;
        }
        private void GameStart()
        {
            // Skill info for tina_guardian
            Q = new Spell("Q Name", "Q", "linear");
            W = new Spell("W Name", "W", "circular");
            E = new Spell("E Name", "E", "self");
            E.range = 11f;
            R = new Spell("R Name", "R", "circular");
            Game.Log.Write("GameStarted");
        }
        private void Update()
        {
            // Cast our Skills On Enemies
            List<Unit> enemies = Game.GetEnemies();
            for (int b = 0; b < enemies.Count; b++)
            {
                Q.Cast(enemies[b]);
                W.Cast(enemies[b]);
                E.Cast(enemies[b]);
                R.Cast(enemies[b]);
            }
        }

        private void OnGUI()
        {
            for (int b = 0; b < Game.GetEnemies().Count; b++)
            {
                Unit currentEnemy = Game.GetEnemies()[b];
                Draws.Text("Name: " + currentEnemy.actorData.ActorName + " Role: " + currentEnemy.actorData.GuardianRole + " Type: " + currentEnemy.type + " Distance: " + Vector3.Distance(Game.MyActor().position, currentEnemy.position) + " VisionLevel: " + currentEnemy.visionLevel, 15, 100, 170 + (b * 20), UnityEngine.Color.white);

            }
        }

    }
}
 