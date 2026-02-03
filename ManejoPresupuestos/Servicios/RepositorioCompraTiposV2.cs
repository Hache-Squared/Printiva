using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCompraTiposV2
    {
        Task<IEnumerable<CompraTipoV2>> ObtenerTodosActivos();
        Task<IEnumerable<CompraTipoV2>> ObtenerTodosIncluyendoInactivos();
        Task<CompraTipoV2?> ObtenerPorId(int id);

        Task Crear(int usuarioId, CompraTipoV2 tipo);
        Task Actualizar(int usuarioId, CompraTipoV2 tipo);
        Task Borrar(int usuarioId, int compraTipoId);
    }

    public class RepositorioCompraTiposV2 : IRepositorioCompraTiposV2
    {
        private readonly string connectionString;

        public RepositorioCompraTiposV2(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection")!;
        }

        public async Task<IEnumerable<CompraTipoV2>> ObtenerTodosActivos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraTipoV2>(
                @"
                SELECT CompraTipoId, Nombre, EsInventario, EstaActivo
                FROM dbo.TblComprasTipos
                WHERE EstaActivo = 1
                ORDER BY Nombre;
                "
            );
        }

        public async Task<IEnumerable<CompraTipoV2>> ObtenerTodosIncluyendoInactivos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraTipoV2>(
                @"
                SELECT CompraTipoId, Nombre, EsInventario, EstaActivo
                FROM dbo.TblComprasTipos
                ORDER BY EstaActivo DESC, Nombre;
                "
            );
        }

        public async Task<CompraTipoV2?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CompraTipoV2>(
                @"
                SELECT CompraTipoId, Nombre, EsInventario, EstaActivo
                FROM dbo.TblComprasTipos
                WHERE CompraTipoId = @id;
                ",
                new { id }
            );
        }

        public async Task Crear(int usuarioId, CompraTipoV2 tipo)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstAsync<dynamic>(
                "dbo.procAlteraComprasTiposV2",
                new
                {
                    ElementoAlterarId = 0,
                    Nombre = tipo.Nombre,
                    EsInventario = tipo.EsInventario,
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 0
                },
                commandType: CommandType.StoredProcedure
            );

            // el SP devuelve elementoId
            tipo.CompraTipoId = (int)res.elementoId;
        }

        public async Task Actualizar(int usuarioId, CompraTipoV2 tipo)
        {
            using var connection = new SqlConnection(connectionString);

            await connection.QueryFirstAsync<dynamic>(
                "dbo.procAlteraComprasTiposV2",
                new
                {
                    ElementoAlterarId = tipo.CompraTipoId,
                    Nombre = tipo.Nombre,
                    EsInventario = tipo.EsInventario,
                    loginId = usuarioId,
                    Actualizar = 1,
                    Borrar = 0
                },
                commandType: CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int compraTipoId)
        {
            using var connection = new SqlConnection(connectionString);

            await connection.QueryFirstAsync<dynamic>(
                "dbo.procAlteraComprasTiposV2",
                new
                {
                    ElementoAlterarId = compraTipoId,
                    Nombre = "", // ya no se requiere en delete lógico
                    EsInventario = 0,
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 1
                },
                commandType: CommandType.StoredProcedure
            );
        }
    }
}