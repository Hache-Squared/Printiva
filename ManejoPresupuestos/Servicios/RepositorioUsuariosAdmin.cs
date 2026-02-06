using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Text.Json;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioUsuariosAdmin
    {
        Task<IEnumerable<UsuarioListaVm>> ListarAsync();
        Task<(UsuarioFormVm? usuario, List<string> permisos)> ObtenerDetalleAsync(int usuarioId);
        Task<SpResultVm> AlteraAsync(UsuarioFormVm vm, int loginId, string? passwordHash, bool actualizar, bool borrar, bool reactivar);
    }

    public class RepositorioUsuariosAdmin : IRepositorioUsuariosAdmin
    {
        private readonly string connectionString;

        public RepositorioUsuariosAdmin(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<UsuarioListaVm>> ListarAsync()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<UsuarioListaVm>(
                "dbo.procObtenerUsuarios",
                commandType: CommandType.StoredProcedure
            );
        }

        public async Task<(UsuarioFormVm? usuario, List<string> permisos)> ObtenerDetalleAsync(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);

            using var multi = await connection.QueryMultipleAsync(
                "dbo.procObtenerUsuarioDetalle",
                new { UsuarioId = usuarioId },
                commandType: CommandType.StoredProcedure
            );

            var u = await multi.ReadSingleOrDefaultAsync<Usuario>();
            var permisos = (await multi.ReadAsync<string>()).ToList();

            if (u is null) return (null, new List<string>());

            var vm = new UsuarioFormVm
            {
                Id = u.Id,
                Nombre = u.Nombre ?? "",
                Email = u.Email,
                EsAdmin = u.EsAdmin,
                PermisosSeleccionados = permisos
            };

            return (vm, permisos);
        }

        public async Task<SpResultVm> AlteraAsync(UsuarioFormVm vm, int loginId, string? passwordHash, bool actualizar, bool borrar, bool reactivar)
        {
            using var connection = new SqlConnection(connectionString);

            var permisosJson = JsonSerializer.Serialize((vm.PermisosSeleccionados ?? new()).Distinct().ToList());

            var res = await connection.QuerySingleAsync<SpResultVm>(
                "dbo.procAlteraUsuarios",
                new
                {
                    ElementoAlterarId = vm.Id,
                    vm.Nombre,
                    vm.Email,
                    PasswordHash = passwordHash,
                    vm.EsAdmin,
                    PermisosJson = permisosJson,
                    loginId,
                    Actualizar = actualizar ? 1 : 0,
                    Borrar = borrar ? 1 : 0,
                    Reactivar = reactivar ? 1 : 0
                },
                commandType: CommandType.StoredProcedure
            );

            return res;
        }
    }
}