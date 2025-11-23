using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCompraTipos
    {
        Task<IEnumerable<CompraTipo>> ObtenerTodos();
        Task Crear(CompraTipo tipo);
        Task<CompraTipo?> ObtenerPorId(int id);
        Task Actualizar(int usuarioId, CompraTipo tipo);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioCompraTipos : IRepositorioCompraTipos
    {
        private readonly string connectionString;

        public RepositorioCompraTipos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<CompraTipo>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraTipo>(
                @"
                    SELECT * FROM TblComprasTipos
                "
            );
        }

        public async Task Crear(CompraTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblComprasTipos (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                tipo
            );

            tipo.CompraTipoId = id;
        }

        public async Task<CompraTipo?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CompraTipo>(
                @"
                    SELECT * FROM TblComprasTipos WHERE CompraTipoId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(int usuarioId, CompraTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<CompraTipo>(
                "procAlteraComprasTipos",
                new
                {
                    elementoAlterarId = tipo.CompraTipoId,
                    nombre = tipo.Nombre,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<CompraTipo>(
                "procAlteraComprasTipos",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Tipo eliminado",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
