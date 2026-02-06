using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Caching.Memory;

namespace ManejoPresupuestos.Servicios
{
    public interface IServicioPermisos
    {
        Task<bool> EsAdminAsync(int usuarioId);
        Task<HashSet<string>> ObtenerPermisosAsync(int usuarioId);
    }

    public class ServicioPermisos : IServicioPermisos
    {
        private readonly string cs;
        private readonly IMemoryCache cache;

        public ServicioPermisos(IConfiguration config, IMemoryCache cache)
        {
            cs = config.GetConnectionString("DefaultConnection");
            this.cache = cache;
        }

        public async Task<bool> EsAdminAsync(int usuarioId)
        {
            var key = $"admin:{usuarioId}";
            if (cache.TryGetValue(key, out bool val)) return val;

            using var con = new SqlConnection(cs);
            var es = await con.ExecuteScalarAsync<int>(
                "SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.Usuarios WHERE Id=@id AND EstaActivo=1 AND EsAdmin=1) THEN 1 ELSE 0 END",
                new { id = usuarioId }
            );

            val = es == 1;
            cache.Set(key, val, TimeSpan.FromMinutes(5));
            return val;
        }

        public async Task<HashSet<string>> ObtenerPermisosAsync(int usuarioId)
        {
            var key = $"perms:{usuarioId}";
            if (cache.TryGetValue(key, out HashSet<string> set)) return set;

            using var con = new SqlConnection(cs);
            var perms = await con.QueryAsync<string>(
                "SELECT PermisoKey FROM dbo.TblUsuariosPermisos WHERE UsuarioId=@id AND EstaActivo=1",
                new { id = usuarioId }
            );

            set = perms.Select(x => x.Trim()).Where(x => x.Length > 0).ToHashSet(StringComparer.OrdinalIgnoreCase);
            cache.Set(key, set, TimeSpan.FromMinutes(5));
            return set;
        }
    }
}