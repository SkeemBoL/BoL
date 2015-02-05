using System;
using System.IO;

namespace NintendoTome
{
    public class Log
    {
        private string logPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + @"\gamesteroids\bin\assets\5\";
        public Log()
        {
        }
        public void Write(string msg)
        {
            using (TextWriter writer = File.AppendText(this.logPath + @"\Log.txt"))
            {
                writer.Write("[" + DateTime.Now + "] : " + msg + "\r\n");
            }
        }
    }
}