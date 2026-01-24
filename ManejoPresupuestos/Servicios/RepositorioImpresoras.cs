using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioImpresoras
    {
        Task<IEnumerable<Impresora>> ObtenerTodos(int usuarioId, bool soloActivas = false);
        Task<Impresora?> ObtenerPorId(int usuarioId, int impresoraId);
        Task<ResultProcedureGeneric> Crear(int usuarioId, ImpresoraEdicionViewModel modelo);
        Task<ResultProcedureGeneric> Actualizar(int usuarioId, ImpresoraEdicionViewModel modelo);
        Task<ResultProcedureGeneric> Borrar(int usuarioId, int impresoraId);
    }

    public class RepositorioImpresoras : IRepositorioImpresoras
    {
        private readonly string connectionString;

        public RepositorioImpresoras(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Impresora>> ObtenerTodos(int usuarioId, bool soloActivas = false)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Impresora>(
                "dbo.procObtenerImpresoras",
                new { loginId = usuarioId, ElementoObtenerId = (int?)null, SoloActivas = soloActivas ? 1 : 0 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Impresora?> ObtenerPorId(int usuarioId, int impresoraId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Impresora>(
                "dbo.procObtenerImpresoras",
                new { loginId = usuarioId, ElementoObtenerId = impresoraId, SoloActivas = 0 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Crear(int usuarioId, ImpresoraEdicionViewModel modelo)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraImpresora",
                new
                {
                    ElementoAlterarId = 0,
                    Nombre = modelo.Nombre,
                    Modelo = modelo.Modelo ?? "",
                    Notas = modelo.Notas ?? "",
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Actualizar(int usuarioId, ImpresoraEdicionViewModel modelo)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraImpresora",
                new
                {
                    ElementoAlterarId = modelo.ImpresoraId,
                    Nombre = modelo.Nombre,
                    Modelo = modelo.Modelo ?? "",
                    Notas = modelo.Notas ?? "",
                    loginId = usuarioId,
                    Actualizar = 1,
                    Borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> Borrar(int usuarioId, int impresoraId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraImpresora",
                new
                {
                    ElementoAlterarId = impresoraId,
                    Nombre = "",
                    Modelo = "",
                    Notas = "",
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
