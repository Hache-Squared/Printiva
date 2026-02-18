using System;

namespace ManejoPresupuestos.Helpers
{
    public static class TimeZones
    {
        private static readonly TimeZoneInfo MonterreyTz = FindMonterreyTz();

        private static TimeZoneInfo FindMonterreyTz()
        {
            // Azure App Service Linux (IANA)
            try { return TimeZoneInfo.FindSystemTimeZoneById("America/Monterrey"); } catch { }

            // Windows dev (Windows TZ)
            try { return TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time (Mexico)"); } catch { }

            // fallback común
            return TimeZoneInfo.FindSystemTimeZoneById("America/Mexico_City");
        }

        public static DateTime ToMonterreyFromUtc(DateTime dt)
        {
            if (dt == default) return dt;

            // Dapper suele traer Kind=Unspecified aunque sea UTC -> asumimos UTC
            var utc = dt.Kind switch
            {
                DateTimeKind.Utc => dt,
                DateTimeKind.Local => dt.ToUniversalTime(),
                _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc)
            };

            return TimeZoneInfo.ConvertTimeFromUtc(utc, MonterreyTz);
        }
    }
}