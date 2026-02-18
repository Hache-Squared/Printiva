using System;

namespace ManejoPresupuestos.Helpers
{
    public static class DateTimeMxExtensions
    {
        public static DateTime Mx(this DateTime utcDateTime)
            => TimeZones.ToMonterreyFromUtc(utcDateTime);

        public static string MxFmt(this DateTime utcDateTime, string format)
            => TimeZones.ToMonterreyFromUtc(utcDateTime).ToString(format);

        public static string MxFmt(this DateTime? utcDateTime, string format)
            => utcDateTime.HasValue ? TimeZones.ToMonterreyFromUtc(utcDateTime.Value).ToString(format) : "";
    }
}